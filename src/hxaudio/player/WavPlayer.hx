package hxaudio.player;

import format.wav.Data.WAVE;
import haxe.io.Bytes;

/**
 * WAV file player.
 * See `hxaudio.sound.Sound.load()` to load a WAV file easily.
 */
class WavPlayer implements IPlayer {
    var data:Bytes;
    var pos:Float = 0;
    var channels:Int;
    var bytesPerSample:Int;
    var sampleRate:Int;
    var totalFrames:Int;
    var playing:Bool = false;
    public var volume:Float = 1;
    public var loop:Bool = false;
    public var pitch:Float = 1;
    public var finished(get, never):Bool;
    function get_finished() return pos >= totalFrames;
    public var time(get, never):Float;
    function get_time() return pos / sampleRate * 1000;
    public var length(get, never):Float;
    function get_length() return totalFrames / sampleRate * 1000;
    /**
     * Initialize a new WAV player.
     * @param wav The WAV file to play.
     */
    public function new(wav:WAVE) {
        data = wav.data;
        channels = wav.header.channels;
        bytesPerSample = wav.header.bitsPerSample >> 3;
        sampleRate = wav.header.samplingRate;
        trace("loading wave: " + wav.header);
        totalFrames = Std.int(data.length / (channels * bytesPerSample));
    }
    public function play() {
        if (playing)
            seek(0);
        playing = true;
    }
    public function pause() playing = false;
    public function stop() { playing = false; pos = 0; }
    public function seek(ms:Float) {
        pos = (ms / 1000) * sampleRate;
        if (pos < 0) pos = 0;
        if (pos >= totalFrames) pos = totalFrames - 0.0001;
    }
    function getSample(frame:Int, channel:Int):Float {
        if (frame < 0 || frame >= totalFrames) return 0;
        var index = (frame * channels + channel) * bytesPerSample;
        if (bytesPerSample == 2) {
            var val = data.get(index) | (data.get(index + 1) << 8);
            if (val & 0x8000 != 0) val -= 0x10000;
            return val / 32768;
        } else if (bytesPerSample == 3) {
            var val = data.get(index) | (data.get(index + 1) << 8) | (data.get(index + 2) << 16);
            if (val & 0x800000 != 0) val |= 0xFF000000;
            return val / 8388608;
        } else if (bytesPerSample == 4) {
            var val = data.getFloat(index);
            return val > 1 ? 1 : val < -1 ? -1 : val;
        }
        return 0;
    }
    public function process():{l:Float, r:Float} {
        if (finished) {
            if (loop) { seek(0); playing = true; }
            else return {l: 0, r: 0};
        }
        if (!playing) return {l: 0, r: 0};
        var i = Std.int(pos);
        var t = pos - i;
        var l1 = getSample(i, 0);
        var l2 = getSample(i + 1, 0);
        var outL = (l1 + t * (l2 - l1)) * volume;
        var outR = if (channels == 2) {
            var r1 = getSample(i, 1);
            var r2 = getSample(i + 1, 1);
            (r1 + t * (r2 - r1)) * volume;
        } else outL;
        pos += pitch;
        return {l: outL, r: outR};
    }
}