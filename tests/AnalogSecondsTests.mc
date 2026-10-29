import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Test;

(:test)
function analogPointerRunsClockwiseOutsideWatchFaceContent(logger as Test.Logger) as Lang.Boolean {
    var top = AnalogSeconds.marker(0);
    var right = AnalogSeconds.marker(15);
    var bottom = AnalogSeconds.marker(30);
    var left = AnalogSeconds.marker(45);
    Test.assertEqual(top[0], 130);
    Test.assertEqual(top[1], 8);
    Test.assertEqual(right[0], 252);
    Test.assertEqual(right[1], 130);
    Test.assertEqual(bottom[0], 130);
    Test.assertEqual(bottom[1], 252);
    Test.assertEqual(left[0], 8);
    Test.assertEqual(left[1], 130);
    for (var second = 0; second < 60; second += 1) {
        var point = AnalogSeconds.marker(second);
        for (var x = -AnalogSeconds.RADIUS; x <= AnalogSeconds.RADIUS; x += 1) {
            for (var y = -AnalogSeconds.RADIUS; y <= AnalogSeconds.RADIUS; y += 1) {
                if (x * x + y * y > AnalogSeconds.RADIUS * AnalogSeconds.RADIUS) { continue; }
                var dx = point[0] + x - 130;
                var dy = point[1] + y - 130;
                var distanceSquared = dx * dx + dy * dy;
                // Stay inside the arcs' inner radius (126 px) at every second.
                Test.assert(distanceSquared < 126 * 126);
                Test.assert(distanceSquared >= 118 * 118);
            }
        }
    }
    return true;
}

(:test)
function analogClipsCoverBothPositionsIncludingMinuteWrapAndSkippedTicks(logger as Test.Logger) as Lang.Boolean {
    AnalogSeconds.prepare(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    for (var second = 0; second < 60; second += 1) {
        for (var skipped = 0; skipped < 3; skipped += 1) {
            var previous = skipped == 0 ? -1 : (second + 60 - skipped) % 60;
            var clip = AnalogSeconds.bounds(second, previous);
            var old = previous < 0 ? second : previous;
            var currentPoint = AnalogSeconds.marker(second);
            var oldPoint = AnalogSeconds.marker(old);
            for (var index = 0; index < 2; index += 1) {
                var point = index == 0 ? currentPoint : oldPoint;
                Test.assert(clip[0] <= point[0] - AnalogSeconds.RADIUS);
                Test.assert(clip[1] <= point[1] - AnalogSeconds.RADIUS);
                Test.assert(clip[0] + clip[2] > point[0] + AnalogSeconds.RADIUS);
                Test.assert(clip[1] + clip[3] > point[1] + AnalogSeconds.RADIUS);
            }
            Test.assert(clip[0] >= 0 && clip[1] >= 0);
            Test.assert(clip[0] + clip[2] <= 260 && clip[1] + clip[3] <= 260);
            if (skipped == 1) {
                Test.assert(clip[2] <= 20 && clip[3] <= 20);
            }
        }
    }
    return true;
}
