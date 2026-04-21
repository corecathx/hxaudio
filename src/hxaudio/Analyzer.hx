package hxaudio;

class Analyzer {
    public var minDb:Float = -70;
    public var maxDb:Float = -20;
    public var smoothing:Float = 0.6;
    public var minFreq:Float = 50;
    public var maxFreq:Float = 20000;
    public var fftSize(default, set):Int;

    var sampleRate:Float;
    var window:Array<Float>;
    var ptr:Int = 0;
    var hann:Array<Float>;
    var real:Array<Float>;
    var imag:Array<Float>;
    var mag:Array<Float>;
    var smoothed:Array<Float> = [];

    public function new(sampleRate:Float = 48000, fftSize:Int = 2048) {
        this.sampleRate = sampleRate;
        this.fftSize = fftSize;
    }

    public function feed(l:Float, r:Float) {
        window[ptr] = (l + r) * 0.5;
        ptr = (ptr + 1) % fftSize;
    }

    public function getBands(n:Int):Array<Float> {
        runFFT();

        if (smoothed.length != n) {
            smoothed = [for (_ in 0...n) 0];
        }

        var binHz = sampleRate / fftSize;
        for (i in 0...n) {
            var f1 = minFreq * Math.pow(maxFreq / minFreq,  i      / n);
            var f2 = minFreq * Math.pow(maxFreq / minFreq, (i + 1) / n);
            var b1 = Std.int(f1 / binHz);
            var b2 = Std.int(f2 / binHz);
            if (b2 >= mag.length) b2 = mag.length - 1;
            if (b1 > b2) b1 = b2;

            var peak:Float = 0;
            for (j in b1...b2 + 1) if (mag[j] > peak) peak = mag[j];

            var db = 20 * Math.log(peak + 1e-9) / Math.log(10);
            var norm = (db - minDb) / (maxDb - minDb);
            norm = norm < 0 ? 0 : norm > 1 ? 1 : norm;

            smoothed[i] = smoothing * smoothed[i] + (1 - smoothing) * norm;
        }
        return smoothed;
    }

    function runFFT() {
        for (i in 0...fftSize) {
            real[i] = window[(ptr + i) % fftSize] * hann[i];
            imag[i] = 0;
        }
        var j = 0;
        for (i in 0...fftSize) {
            if (i < j) {
                var t = real[i]; real[i] = real[j]; real[j] = t;
            }
            var m = fftSize >> 1;
            while (m >= 1 && j >= m) { j -= m; m >>= 1; }
            j += m;
        }
        // Cooley-Tukey
        var size = 2;
        while (size <= fftSize) {
            var half = size >> 1;
            var step = Math.PI / half;
            for (i in 0...fftSize) {
                if (i % size < half) {
                    var k = i + half;
                    var angle = (i % size) * step;
                    var wr = Math.cos(angle);
                    var wi = -Math.sin(angle);
                    var tr = real[k] * wr - imag[k] * wi;
                    var ti = real[k] * wi + imag[k] * wr;
                    real[k] = real[i] - tr;
                    imag[k] = imag[i] - ti;
                    real[i] += tr;
                    imag[i] += ti;
                }
            }
            size <<= 1;
        }
        var n = fftSize;
        for (i in 0...mag.length)
            mag[i] = Math.sqrt(real[i] * real[i] + imag[i] * imag[i]) / n;
    }

    function set_fftSize(v:Int):Int {
        fftSize = v;
        window   = [for (i in 0...v) 0];
        hann     = [for (i in 0...v) 0.5 * (1 - Math.cos(2 * Math.PI * i / (v - 1)))];
        real     = [for (i in 0...v) 0];
        imag     = [for (i in 0...v) 0];
        mag      = [for (i in 0...v >> 1) 0];
        ptr      = 0;
        return v;
    }
}