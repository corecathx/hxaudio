package hxaudio.midi;

enum MidiEventType {
    NoteOn;
    NoteOff;
    // microseconds per beat.
    Tempo(uspb:Int);
    Unknown;
}
typedef MidiEvent = {
    var tick:Int;
    var type:MidiEventType;
    var channel:Int;
    var note:Int;
    var velocity:Int;
}
typedef MidiFile = {
    var events:Array<MidiEvent>;
    var ticksPerBeat:Int;
}
