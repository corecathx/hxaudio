
package hxaudio.player;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import stb.format.vorbis.Reader;

/**
 * OGG file player.
 * See `audio.sound.Sound.load()` to load an OGG file easily.
 */
class OggPlayer implements IPlayer {
    var reader:Reader;
    var buffer:Bytes = null;
    var bufferPos:Float = 0;
    var bufferSamples:Int = 0;
    var channels:Int;
    var playing:Bool = false;
    var fileSampleRate:Int;
    var engineSampleRate:Float;
    var _finished:Bool = false;
    static inline var CHUNK = 4096;
    public var volume:Float = 1;
    public var loop:Bool = false;
    public var pitch:Float = 1;
    public var finished(get, never):Bool;
    public var pendingSeek:Null<Float> = null;
    function get_finished() return _finished;
    public var time(get, never):Float;
    function get_time() return reader.currentMillisecond;

    public var length(get, never):Float;
    function get_length() return reader.totalMillisecond;
    /**
     * Initialize a new OGG player.
     * @param bytes Raw bytes of the OGG file.
     */
    public function new(bytes:Bytes, engineSampleRate:Float = 48000) {
        reader = Reader.openFromBytes(bytes);
        channels = reader.header.channel;
        fileSampleRate = reader.header.sampleRate;
        this.engineSampleRate = engineSampleRate;
        refill();
    }
    /**
     * Decode the next chunk of samples into the buffer.
     */
    function refill() {
        try {
            var out = new BytesOutput();
            bufferSamples = reader.read(out, CHUNK, channels, reader.header.sampleRate, true);
            buffer = out.getBytes();
            bufferPos = 0;
            if (bufferSamples == 0) _finished = true;
        } catch (e) {
            _finished = true;
        }
    }
    /**
     * Read a float sample from the buffer at a given float index.
     * Each frame is `channels * 4` bytes (Float32).
     */
    inline function readFloat(bytePos:Int):Float {
        if (bytePos + 3 >= buffer.length) return 0;
        return buffer.getFloat(bytePos);
    }
    public function play() {
        if (playing)
            seek(0);
        _finished = false;
        playing = true;
    }
    public function pause() playing = false;
    public function stop() {
        playing = false;
        _finished = false;
        reader.currentSample = 0;
        refill();
    }
    public function seek(ms:Float) {
        reader.currentMillisecond = ms;
        _finished = false;
        refill();
    }
    public function process():{l:Float, r:Float} {
        if (_finished) {
            if (loop) { seek(0); playing = true; }
            else {
                playing = false;
                return {l: 0, r: 0};
            }
        }
        if (!playing) return {l: 0, r: 0};
        if (pendingSeek != null) {
            reader.currentMillisecond = pendingSeek;
            _finished = false;
            refill();
            pendingSeek = null;
        }
        // refill buffer if exhausted
        if (Std.int(bufferPos) + 1 >= bufferSamples) refill();
        if (_finished) return {l: 0, r: 0};
        // lerp used for pitch shift
        var i = Std.int(bufferPos);
        var t = bufferPos - i;
        var byteBase = i * channels * 4;
        var l1 = readFloat(byteBase);
        var l2 = readFloat(byteBase + channels * 4);
        var outL = (l1 + t * (l2 - l1)) * volume;
        var outR = if (channels == 2) {
            var r1 = readFloat(byteBase + 4);
            var r2 = readFloat(byteBase + channels * 4 + 4);
            (r1 + t * (r2 - r1)) * volume;
        } else outL;
        bufferPos += pitch * (fileSampleRate / engineSampleRate);
        return {l: outL, r: outR};
    }
}