package hxaudio.player;

import hxaudio.midi.MidiEvent;

/**
 * A simple MIDI file player.
 * Synthesizes voices using a sine-based oscillator with ADSR envelope and vibrato.
 * usage:
 * ```haxe
 * var midi = Midi.parse('song.mid');
 * var player = new MidiPlayer(midi);
 * output.onProcess = () -> {
 *     var s = player.process();
 *     output.write(s, s);
 * }
 * ```
 */
class MidiPlayer implements IPlayer {
    /**
     * Currently active voices with their note and envelope values.
     */
    public var activeVoices:Array<{note:Int, env:Float}> = [];
    /**
     * Playback volume. Defaults to 1.
     */
    public var volume:Float = 1;
    /**
     * Whether the player should loop. Defaults to false.
     */
    public var loop:Bool = false;
    /**
     * Playback pitch/speed multiplier. Defaults to 1.
     */
    public var pitch:Float = 1;
    /**
     * Whether the player has finished playing.
     */
    public var finished(get, never):Bool;
    function get_finished() return eventIdx >= midi.events.length && voices.length == 0;
    /**
     * Current playback position in milliseconds.
     */
    public var time(get, never):Float;
    function get_time() return _time * 1000;
    /**
     * Total length of the audio in milliseconds.
     */
    public var length(get, never):Float;
    function get_length() return _length * 1000;

    var _time:Float = 0;
    var _length:Float = 0;
    var playing:Bool = false;
    var midi:MidiFile;
    var sampleRate:Float;
    var voices:Array<Voice> = [];
    var eventIdx:Int = 0;
    var tick:Float = 0;
    var uspb:Int = 500000;
    var samplesPerTick:Float = 0;

    static inline var ATK = 0.002;
    static inline var DCY = 0.08;
    static inline var SUS = 0.6;
    static inline var REL = 0.05;
    static inline var DUTY = 0.25; // nes-like square

    /**
     * Initialize a new MIDI player.
     * @param midi Parsed MIDI file.
     * @param sampleRate Sample rate. Defaults to 48000hz.
     */
    public function new(midi:MidiFile, sampleRate:Float = 48000) {
        this.midi = midi;
        this.sampleRate = sampleRate;
        tick = 0;
        calculateLength();
        recomputeTiming();
    }

    public function play() {         
        if (playing)
            seek(0);
        playing = true; 
    }
    public function pause() { playing = false; }
    public function stop() {
        playing = false;
        eventIdx = 0;
        tick = 0;
        _time = 0;
        voices = [];
        recomputeTiming();
    }

    public function seek(ms:Float) {
        var targetSec = ms / 1000;

        // reset
        voices = [];
        eventIdx = 0;
        tick = 0;
        _time = 0;
        uspb = 500000;

        var curTick = 0.0;
        var curTime = 0.0;
        for (i in 0...midi.events.length) {
            var e = midi.events[i];
            var dt = (e.tick - curTick) * ((uspb / 1000000) / midi.ticksPerBeat);
            if (curTime + dt >= targetSec) break;
            curTime += dt;
            curTick = e.tick;
            switch e.type { case Tempo(t): uspb = t; default: }
            eventIdx = i + 1;
        }

        tick = curTick;
        _time = curTime;
        recomputeTiming();
    }

    /**
     * Process and return the next stereo sample.
     * Call this inside `AudioOutput.onProcess`.
     */
    public function process():{l:Float, r:Float} {
        if (finished) {
            if (loop) stop();
            else return {l: 0, r: 0};
        }
        if (!playing) return {l: 0, r: 0};
        var dt = 1 / sampleRate;
        _time += dt;
        tick += 1 / samplesPerTick;

        while (eventIdx < midi.events.length && midi.events[eventIdx].tick <= tick) {
            var e = midi.events[eventIdx++];
            switch e.type {
                case NoteOn:      if (e.velocity > 0) noteOn(e.note, e.velocity, e.channel) else noteOff(e.note);
                case NoteOff:     noteOff(e.note);
                case Tempo(t):    uspb = t; recomputeTiming();
                default:
            }
        }

        var out = 0.0;
        for (v in voices) {
            v.phase += v.freq / sampleRate;
            if (v.phase >= 1) v.phase -= 1;
            var sample = v.phase < DUTY ? 1 : -1;
            switch v.stage {
                case 0: v.env += dt / ATK; if (v.env >= 1) { v.env = 1; v.stage = 1; }
                case 1: v.env -= dt / DCY; if (v.env <= SUS)  { v.env = SUS; v.stage = 2; }
                case 3: v.env -= dt / REL; if (v.env <= 0)  { v.env = 0; v.stage = 4; }
                default:
            }
            out += sample * v.env * v.vel;
        }

        voices = voices.filter(v -> v.stage < 4);
        activeVoices = voices.map(v -> { note: v.note, env: v.env });
        var s = out * volume;
        return {l: s, r: s};
    }

    function noteOn(note:Int, vel:Int, channel:Int) {
        for (v in voices) if (v.note == note) { v.stage = 0; v.vel = vel / 127; return; }
        voices.push({ note: note, channel: channel, freq: noteToFreq(note), phase: 0, vel: vel / 127, env: 0, stage: 0, vibratoPhase: 0 });
    }

    function noteOff(note:Int) {
        for (v in voices) if (v.note == note && v.stage < 3) v.stage = 3;
    }

    function calculateLength() {
        var tempUspb = 500000;
        var total = 0.0;
        var lastTick = 0.0;
        for (e in midi.events) {
            total += (e.tick - lastTick) * ((tempUspb / 1000000) / midi.ticksPerBeat);
            switch e.type { case Tempo(t): tempUspb = t; default: }
            lastTick = e.tick;
        }
        _length = total;
    }
    function recomputeTiming() {
        samplesPerTick = sampleRate / (1000000 / uspb * midi.ticksPerBeat);
    }

    static inline function noteToFreq(n:Int):Float {
        return 440 * Math.pow(2, (n - 69) / 12);
    }
}

private typedef Voice = {
    var note:Int;
    var channel:Int;
    var freq:Float;
    var phase:Float;
    var vel:Float;
    var env:Float;
    var stage:Int;
    var vibratoPhase:Float;
}