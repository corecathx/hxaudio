# hxaudio
**hxaudio** is a wrapper for [grig.audio](https://grig.tech) that makes it easier to use with less boilerplate.

Supports WAV, OGG, and MIDI playback, plus FFT-based frequency analysis.

## Installation

soon

## Examples

### Playing a sound

```haxe
var engine = new hxaudio.AudioEngine(null, new hxaudio.AudioOutput());
engine.start();

Sound.load("music.ogg").play();
```

### Microphone input

```haxe
var input = new hxaudio.AudioInput();
input.onProcess = (sample:Float) -> trace(sample);

var engine = new hxaudio.AudioEngine(input, new hxaudio.AudioOutput());
engine.start();
```

### FFT analysis

```haxe
var analyzer = new hxaudio.Analyzer();
engine.onPostProcess = (l, r) -> analyzer.feed(l, r);

var bands = analyzer.getBands(32); // 32 bands, normalized 0..1
```

### Raw output

```haxe
var output = new hxaudio.AudioOutput();
output.onProcess = () -> output.write(Math.random(), Math.random());

var engine = new hxaudio.AudioEngine(null, output);
engine.start();
```

## Dependencies

- [grig.audio](https://grig.tech/) - Literally what makes hxaudio exists
- [format](https://lib.haxe.org/p/format/) - WAV parsing
- [stb_ogg_sound](https://lib.haxe.org/p/stb_ogg_sound/) - OGG decoding

## License

MIT