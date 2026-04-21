class Main {
    static function main() {
        var output = new hxaudio.AudioOutput();
        var engine = new hxaudio.AudioEngine(null, output);
        engine.onReady = () -> trace("engine started!");
        engine.onError = (e) -> trace("error: " + e);
        engine.start();

        Sys.sleep(2);
    }
}