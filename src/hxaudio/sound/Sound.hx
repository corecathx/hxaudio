package hxaudio.sound;

import hxaudio.midi.Midi;
import hxaudio.player.MidiPlayer;
import haxe.io.Path;
import sys.io.File;
import haxe.io.BytesInput;
import format.wav.Reader as WavReader;
import hxaudio.player.IPlayer;
import hxaudio.player.WavPlayer;
import hxaudio.player.OggPlayer;
import hxaudio.AudioEngine;

/**
 * Sound loader and player.
 * usage:
 * ```haxe
 * /// set up engine first
 * var engine = new hxaudio.AudioEngine(null, new hxaudio.AudioOutput());
 * engine.start();
 *
 * /// then just load and play
 * var sound = Sound.load('cats.wav');
 * sound.play();
 *
 * /// chainable too
 * Sound.load('cats.ogg').play();
 * ```
 */
class Sound {
    var player:IPlayer;
    /**
     * Playback volume. Defaults to 1.
     */
    public var volume(get, set):Float;
    function get_volume() return player.volume;
    function set_volume(v:Float) return player.volume = v;
    /**
     * Whether the sound should loop. Defaults to false.
     */
    public var loop(get, set):Bool;
    function get_loop() return player.loop;
    function set_loop(v:Bool) return player.loop = v;
    /**
     * Playback pitch/speed multiplier. Defaults to 1.
     */
    public var pitch(get, set):Float;
    function get_pitch() return player.pitch;
    function set_pitch(v:Float) return player.pitch = v;
    /**
     * Whether the sound has finished playing.
     */
    public var finished(get, never):Bool;
    function get_finished() return player.finished;
    /**
     * Current playback time in milliseconds.
     */
    public var time(get, never):Float;
    function get_time() return player.time;
    /**
     * Total length of the audio in milliseconds.
     */
    public var length(get, never):Float;
    function get_length() return player.length;

    /**
     * Initialize a new sound.
     * It is recommended to call `Sound.load(path)` unless you want to manually setup the player.
     * @param player Player instance.
     */
    function new(player:IPlayer) {
        this.player = player;
        var engine:AudioEngine = AudioEngine.instance;
        if (engine == null) throw "No active AudioEngine. Call AudioEngine.start() first.";
        engine.sounds.push(player);
    }
    /**
     * Load a sound file. Supports `.wav` and `.ogg`.
     * Automatically picks the right player based on file extension.
     * @param path Path to the sound file.
     */
    public static function load(path:String):Sound {
        var ext:String = Path.extension(path);
        return switch ext {
            case 'mid': new Sound(new MidiPlayer(Midi.parse(path)));
            case 'wav': new Sound(new WavPlayer(new WavReader(new BytesInput(File.getBytes(path))).read()));
            case 'ogg': new Sound(new OggPlayer(File.getBytes(path)));
            default: throw 'Unsupported audio format: $ext. Supported formats: wav, ogg';
        }
    }
    /**
     * Start playback.
     */
    public function play():Sound { player.play(); return this; }
    /**
     * Pause playback.
     */
    public function pause():Sound { player.pause(); return this; }
    /**
     * Stop playback and reset position.
     */
    public function stop():Sound { player.stop(); return this; }
    /**
     * Seek to a specific time in milliseconds.
     * @param ms Time in milliseconds.
     */
    public function seek(ms:Float):Sound { player.seek(ms); return this; }

    /**
     * Remove sound from AudioEngine.
     */
    public function dispose() {
        AudioEngine.instance.sounds.remove(player);
    }
}