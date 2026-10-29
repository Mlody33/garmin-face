import Toybox.Lang;
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
