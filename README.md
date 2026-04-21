# hxaudio
**hxaudio** is a wrapper for [grig.audio](grig.tech) that makes it easier to use with less boilerplate.

Supports WAV, OGG, and MIDI playback, plus FFT-based frequency analysis.

## Installation

soon

## Example

```haxe
var input:hxaudio.AudioInput = new hxaudio.AudioInput();
input.onProcess = (sample:Float) -> {} // `sample` is retrieved from the input source.
var output:hxaudio.AudioOutput = new hxaudio.AudioOutput();
output.onProcess = () -> {
    output.write(Math.random(), Math.random()); // write random noise to the speaker.
}
var engine:hxaudio.AudioEngine = new hxaudio.AudioEngine(input, output);
engine.start();
```


## Dependencies

- [grig.audio](https://grig.tech/) - Literally what makes hxaudio exists
- [format](https://lib.haxe.org/p/format/) - WAV parsing
- [stb_ogg_sound](https://lib.haxe.org/p/stb_ogg_sound/) - OGG decoding

## License

MIT