package hxaudio.player;

/**
 * Interface for all audio players.
 */
interface IPlayer {
    /**
     * Playback volume. Defaults to 1.
     */
    public var volume:Float;
    /**
     * Whether the player should loop. Defaults to false.
     */
    public var loop:Bool;
    /**
     * Playback pitch/speed multiplier. Defaults to 1.
     */
    public var pitch:Float;
    /**
     * Whether the player has reached the end of the file.
     */
    public var finished(get, never):Bool;
    /**
     * Current playback time in milliseconds.
     */
    public var time(get, never):Float;
    /**
     * Total length of the audio in milliseconds.
     */
    public var length(get, never):Float;
    /**
     * Start playback.
     */
    public function play():Void;
    /**
     * Pause playback.
     */
    public function pause():Void;
    /**
     * Stop playback and reset position.
     */
    public function stop():Void;
    /**
     * Seek to a specific time in milliseconds.
     * @param ms Time in milliseconds.
     */
    public function seek(ms:Float):Void;
    /**
     * Process and return the next stereo sample.
     */
    public function process():{l:Float, r:Float};
}