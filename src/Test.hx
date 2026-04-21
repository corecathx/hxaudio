package;

import sys.FileSystem;
import haxe.io.Path;
import hxaudio.Analyzer;
import hxaudio.AudioEngine;
import hxaudio.AudioOutput;
import hxaudio.sound.Sound;

class Test {
    static var engine:AudioEngine;
    static var analyzer:Analyzer = new Analyzer(48000);

    static function main() {
        engine = new AudioEngine(null, new AudioOutput());
        engine.onPostProcess = (l, r) -> analyzer.feed(l, r);
        engine.start();
        playAudio('test.wav', []);
        // playAudio(
        //     "c:/Users/CoreCat/Music/corecat/[4] High - CoreCat Mix/Inst.ogg", 
        //     [
        //         "c:/Users/CoreCat/Music/corecat/[4] High - CoreCat Mix/Voices-core.ogg",
        //         "c:/Users/CoreCat/Music/corecat/[4] High - CoreCat Mix/Voices-mom.ogg"
        //     ]
        // );
    }

    static var barLength:Int = 30;
    static var bands:Int = 40;

    static function playAudio(path:String, otherAudios:Array<String>) {
        var sound:Sound = Sound.load(path);
        sound.pitch = 0.9;
        sound.volume = otherAudios.length > 0 ? 0.7 : 1;
        var sounds:Array<Sound> = [];
        for (i in otherAudios) {
            var s:Sound = Sound.load(i);
            s.volume = 0.9;
            sounds.push(s);
        }
        sound.play();
        for (s in sounds) s.play();

        var logs:Array<String> = [];
        Sys.print("/033[2J\033[?25l");

        path = FileSystem.absolutePath(path);
        var frames:Array<Float> = [];
        while (true) {
            var now = Sys.time();

            frames.push(now);

            while (frames.length > 0 && frames[0] < now - 1) {
                frames.shift();
            }

            var fps = frames.length;
            var buf:StringBuf = new StringBuf();
            buf.add("\033[H");
            buf.add(':: Output Device: ${engine.output.info.portName}[${engine.output.info.portID}] at ${engine.options.sampleRate}hz - FPS: ${Std.int(fps)} (no limit)\033[K\n');
            buf.add('LISTENING TO: $path\033[K\n${formatTime(sound.time)} ');

            var chars:Array<String> = [" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉"];
            var barCount:Float = (sound.time / sound.length) * barLength;
            var filled:Int = Std.int(barCount);
            var partial:Int = Std.int((barCount - filled) * chars.length);
            for (i in 0...barLength) {
                if (i < filled) buf.add("█");
                else if (i == filled) buf.add(chars[partial]);
                else buf.add(" ");
            }
            buf.add('${''} ${formatTime(sound.length)}\033[K\n\033[K\n');

            var bands = analyzer.getBands(bands);
            var vizRows = 6;
            var blocks = [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"];
            var subSteps = blocks.length - 1;

            for (row in 0...vizRows) {
                for (b in bands) {
                    var scaled = b * vizRows * subSteps;
                    var rowStart = (vizRows - row - 1) * subSteps;
                    var rowEnd   = rowStart + subSteps;
                    if (scaled >= rowEnd)        buf.add("█ ");
                    else if (scaled > rowStart)  buf.add(blocks[Std.int(scaled - rowStart)] + " ");
                    else                         buf.add("  ");
                }
                buf.add("\033[K\n");
            }
            buf.add("\033[K\n");

            for (index => i in sounds) {
                var diff = Math.abs(sound.time - i.time);
                buf.add('Sound $index: ${i.time} (${diff}ms diff)\033[K\n');
                if (diff > 200) {
                    if (logs.length >= 10) logs.shift();
                    logs.push('Sound $index desynced! resyncing...');
                    i.seek(sound.time);
                }
            }

            buf.add('== [LOGS] ==\033[K\n');
            for (l in logs) buf.add('-$l\033[K\n');

            Sys.stdout().writeString(buf.toString());
            Sys.stdout().flush();
            Sys.sleep(0.001);
        }
    }

    static function formatTime(s:Float) {
        return '${Std.int((s / 1000) / 60)}:${StringTools.lpad(Std.string(Std.int((s / 1000) % 60)), "0", 2)}';
    }
}