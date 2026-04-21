package hxaudio;

import grig.audio.PortInfo;
import grig.audio.AudioInterface;

/**
 * Base class for audio devices.
 * Holds shared properties like `portID` and `sampleRate`.
 * Use `AudioInput` or `AudioOutput` instead of this directly.
 */
class AudioDevice {
    /**
     * Port ID of this device.
     */
    public var portID:Int;
    /**
     * Sample rate of this device. Defaults to 48000hz.
     */
    public var sampleRate:Float = 48000;
    /**
     * Port info retrieved from grig.audio's AudioInterface.
     */
    public var info:PortInfo = null;

    /**
     * Initialize a new audio device.
     * @param id Port ID of the device. Leave empty to let hxaudio pick the default one.
     */
    public function new(id:Int = -1) {
        this.portID = id;
        if (this.portID == -1) findDefault();
    }
    /**
     * Find and assign the default port for this device.
     * Overridden by child classes.
     */
    function findDefault() {
        var inter:AudioInterface = new AudioInterface();
        for (p in inter.getPorts()) {
            // child classes will override this
        }
    }
}