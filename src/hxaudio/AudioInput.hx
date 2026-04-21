package hxaudio;

import grig.audio.AudioInterface;

/**
 * Represents an audio input device, such as a Microphone.
 * usage:
 * ```haxe
 * var input:hxaudio.AudioInput = new hxaudio.AudioInput();
 * input.onProcess = (sample:Float) -> {
 *     trace(sample); // `sample` is retrieved from the input source.
 * }
 * ```
 */
class AudioInput extends AudioDevice {
    /**
     * Callback when a new sample is received from the input source.
     * `sample` is the raw float value from the input device.
     */
    public var onProcess:(sample:Float) -> Void;
    /**
     * Find and assign the default input port.
     */
    override function findDefault() {
        var ai:AudioInterface = new AudioInterface();
        for (p in ai.getPorts()) {
            if (p.isDefaultInput) {
                this.portID = p.portID;
                info = p;
            }
        }
    }
}