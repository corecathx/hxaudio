package hxaudio.midi;

import hxaudio.midi.MidiEvent;
import sys.io.File;

/**
 * MIDI file parser.
 * usage:
 * ```haxe
 * var midi = Midi.parse('song.mid');
 * var player = new MidiPlayer(midi);
 * ```
 */
class Midi {
    /**
     * Parse a MIDI file from path.
     * @param path Path to the MIDI file.
     */
    public static function parse(path:String):MidiFile {
        var b = File.getBytes(path);
        var i = 0;
        function r8()  return b.get(i++);
        function r16() { var v = (b.get(i) << 8) | b.get(i+1); i += 2; return v; }
        function r32() { var v = (b.get(i) << 24) | (b.get(i+1) << 16) | (b.get(i+2) << 8) | b.get(i+3); i += 4; return v; }
        function varlen():Int {
            var v = 0;
            while (true) {
                var c = r8();
                v = (v << 7) | (c & 0x7F);
                if (c & 0x80 == 0) break;
            }
            return v;
        }
        r32(); r32(); r16(); // MThd, chunk length, format
        var numTracks = r16();
        var tpb = r16();
        var events:Array<MidiEvent> = [];
        for (_ in 0...numTracks) {
            r32(); // MTrk
            var end = i + r32();
            var tick = 0;
            var lastStatus = 0;
            while (i < end) {
                tick += varlen();
                var status = b.get(i);
                if (status & 0x80 == 0) {
                    status = lastStatus;
                } else {
                    lastStatus = status;
                    i++;
                }
                var type = (status >> 4) & 0xF;
                var ch   = status & 0xF;
                switch type {
                    case 0x9:
                        var note = r8(); var vel = r8();
                        events.push({ tick: tick, channel: ch, note: note, velocity: vel, type: vel == 0 ? NoteOff : NoteOn });
                    case 0x8:
                        var note = r8(); var vel = r8();
                        events.push({ tick: tick, type: NoteOff, channel: ch, note: note, velocity: vel });
                    case 0xA | 0xB | 0xE: i += 2;
                    case 0xC | 0xD:       i += 1;
                    case 0xF:
                        if (ch == 0xF) {
                            var meta = r8();
                            var len  = varlen();
                            if (meta == 0x51 && len == 3) {
                                var uspb = (r8() << 16) | (r8() << 8) | r8();
                                events.push({ tick: tick, type: Tempo(uspb), channel: 0, note: 0, velocity: 0 });
                            } else i += len;
                        } else i += varlen();
                    default: i++;
                }
            }
            i = end;
        }
        events.sort((a, b) -> a.tick - b.tick);
        return { events: events, ticksPerBeat: tpb };
    }
}