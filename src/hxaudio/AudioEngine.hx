package hxaudio;

import sys.thread.Thread;
import hxaudio.player.IPlayer;
import tink.core.Error;
import grig.audio.AudioInterfaceOptions;
import grig.audio.AudioInterface;

/**
 * Wrapper for grig.audio interface.
 * usage:
 * ```haxe
 * var engine = new hxaudio.AudioEngine(null, new hxaudio.AudioOutput());
 * engine.onReady = () -> trace("engine ready!");
 * engine.onError = (e) -> trace("error: " + e);
 * engine.start();
 * ```
 */
@:allow(hxaudio.sound.Sound)
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
     * Callback when the audio engine is ready.
     */
    public var onReady:Void -> Void = () -> {};
    /**
     * Callback when the audio engine failed to start.
     */
    public var onError:Error -> Void = (_) -> {};
    /**
     * Callback after each output buffer is processed.
     */
    public var onPostProcess:Float -> Float -> Void = null;
    /**
     * Defines whether this audio engine running or not.
     */
    public var running:Bool = false;

    var _thread:Thread = null;
    var _mutex:sys.thread.Mutex = new sys.thread.Mutex();

    /**
     * Initialize a new audio engine.
     * @param input Input audio source.
     * @param output Output audio source.
     */
    public function new(input:AudioInput, output:AudioOutput) {
        instance = this;
        this.input = input;
        this.output = output;
    }

    /**
     * Start the audio engine.
     */
    public function start() {
        if (running) return;

        _thread = Thread.create(() -> {
            // create AudioInterface on this thread so its event loop
            // stays here and never touches the main thread
            inter = new AudioInterface();

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

                    _mutex.acquire();
                    for (sound in sounds) {
                        var s = sound.process();
                        output.pendingL += s.l;
                        output.pendingR += s.r;
                    }
                    _mutex.release();

                    if (mic != null && input != null && input.onProcess != null)
                        input.onProcess(mic[i]);

                    if (onPostProcess != null)
                        onPostProcess(output.pendingL, output.pendingR);

                    outL[i] = output.pendingL;
                    outR[i] = output.pendingR;
                }
            });

            inter.openPort(options).handle(o -> switch o {
                case Failure(e):
                    running = false;
                    onError(e);
                case Success(_):
                    running = true; 
                    onReady();
            });

            // without this the thread will end by itself
            while (running) Sys.sleep(0.05);
        });
    }

    /**
     * Stop the audio engine and release the thread.
     */
    public function stop() {
        running = false;
        _thread  = null;
    }

    /**
     * Safely add a sound from any thread.
     */
    public function addSound(p:IPlayer) {
        _mutex.acquire();
        sounds.push(p);
        _mutex.release();
    }

    /**
     * Executes a function within the safety of the engine's mutex.
     */
    public function syncJob(fn:Void->Void) {
        _mutex.acquire();
        try {
            fn();
        } catch(e:Dynamic) {
            _mutex.release();
            throw e;
        }
        _mutex.release();
    }
}