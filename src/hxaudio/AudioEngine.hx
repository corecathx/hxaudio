package hxaudio;

import hxaudio.player.IPlayer;
import tink.core.Error;
import grig.audio.AudioInterfaceOptions;
import grig.audio.AudioInterface;

/**
 * Wrapper for grig.audio interface.
 * usage:
 * ```haxe
 * /// AudioInput takes one parameter in the constructor.
 * /// Leave it empty to let hxaudio pick the default one.
 * var input:hxaudio.AudioInput = new hxaudio.AudioInput();
 * input.onProcess = (sample:Float) -> {} // `sample` is retrieved from the input source.
 * var output:hxaudio.AudioOutput = new hxaudio.AudioOutput();
 * output.onProcess = () -> {
 *     output.write(Math.random(), Math.random()); // write random noise to the speaker.
 * }
 * var engine:hxaudio.AudioEngine = new hxaudio.AudioEngine(input, output);
 * engine.start();
 * ```
 */
class AudioEngine {
    /**
     * Current active AudioEngine instance.
     */
    public static var instance:AudioEngine = null;
    /**
     * Main interface used in the engine.
     */
    public var inter:AudioInterface;
    /**
     * Input audio source, such as Microphones.
     */
    public var input:AudioInput;
    /**
     * Output audio source, such as Speakers.
     */
    public var output:AudioOutput;
    /**
     * Grig Audio Interface options.
     */
    public var options:AudioInterfaceOptions = {
        sampleRate:        48000,
        inputNumChannels:  0,
        outputNumChannels: 2,
        bufferSize:        256,
        inputLatency:      0.01,
        outputLatency:     0.01
    };
    /**
     * Player sounds tracker.
     */
    public var sounds:Array<IPlayer> = [];
    /**
     * Callback when the audio engine is ready to use.
     */
    public var onReady:Void -> Void = () -> {};
    /**
     * Callback when the audio engine failed to start.
     */
    public var onError:Error -> Void = (_) -> {};
    /**
     * Callback when the audio engine finished processing output buffer.
     */
    public var onPostProcess:Float -> Float -> Void = null;
    /**
     * Defines whether this audio engine running or not.
     */
    public var running:Bool = false;

    /**
     * Initialize a new audio engine.
     * @param input Input audio source.
     * @param output Output audio source.
     */
    public function new(input:AudioInput, output:AudioOutput) {
        instance = this;
        this.input = input;
        this.output = output;
        inter = new AudioInterface();
    }

    /**
     * Start the audio engine.
     */
    public function start() {
        if (running) return;
        running = true;
        if (input != null) {
            options.inputPort = input.portID;
            options.inputNumChannels = 1;
        }

        inter.setCallback((inBuffer, outBuffer, rate, info) -> {
            var mic = (inBuffer != null && inBuffer.numChannels > 0) ? inBuffer[0] : null;
            var outL = outBuffer[0];
            var outR = outBuffer[1];

            for (i in 0...outL.length) {
                output.pendingL = 0;
                output.pendingR = 0;
                
                if (output.onProcess != null)
                    output.onProcess();

                for (sound in sounds) {
                    var s = sound.process();
                    output.pendingL += s.l;
                    output.pendingR += s.r;
                }

                if (mic != null && input != null && input.onProcess != null)
                    input.onProcess(mic[i]);

                if (onPostProcess != null)
                    onPostProcess(output.pendingL, output.pendingR);

                outL[i] = output.pendingL;
                outR[i] = output.pendingR;
            }
            sounds = sounds.filter(s -> !s.finished || s.loop);
        });

        inter.openPort(options).handle(o -> switch o {
            case Failure(e): running = false; onError(e);
            case Success(_): onReady();
        });
    }
}