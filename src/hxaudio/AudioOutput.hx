package hxaudio;

import grig.audio.AudioInterface;

/**
 * Represents an audio output device, such as a Speaker.
 * usage:
 * ```haxe
 * var output:hxaudio.AudioOutput = new hxaudio.AudioOutput();
 * output.onProcess = () -> {
 *     output.write(Math.random(), Math.random()); // write random noise to the speaker.
 * }
 * ```
 */
class AudioOutput extends AudioDevice {
    /**
     * Pending left channel sample to be written to the output.
     */
    public var pendingL:Float = 0;
    /**
     * Pending right channel sample to be written to the output.
     */
    public var pendingR:Float = 0;
    /**
     * Callback when the audio engine requests a new sample.
     * Call `write()` here to send audio to the output device.
     */
    public var onProcess:() -> Void;
    /**
     * Find and assign the default output port.
     */
    override function findDefault() {
        var ai:AudioInterface = new AudioInterface();
        for (p in ai.getPorts()) {
            if (p.isDefaultOutput) {
                this.portID = p.portID;
                info = p;
            }
        }
    }
    /**
     * Write a stereo sample to the output device.
     * @param l Left channel sample.
     * @param r Right channel sample.
     */
    public function write(l:Float, r:Float) {
        pendingL = l;
        pendingR = r;
    }
}