import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// Keep the dot inside the progress arcs and cache its 60 positions.
module AnalogSeconds {
    const RADIUS = 3;
    const ORBIT = 122;
    var _markers as Lang.Array<[Lang.Number, Lang.Number]> = [];

    function marker(second as Lang.Number) as [Lang.Number, Lang.Number] {
        if (_markers.size() == 0) {
            for (var i = 0; i < 60; i += 1) {
                var angle = i * Math.PI / 30.0;
                _markers.add([
                    Math.round(130 + Math.sin(angle) * ORBIT).toNumber(),
                    Math.round(130 - Math.cos(angle) * ORBIT).toNumber()
                ]);
            }
        }
        return _markers[second];
    }

    function draw(dc as Graphics.Dc, second as Lang.Number, previous as Lang.Number) as Void {
        var current = marker(second);
        var old = previous < 0 ? current : marker(previous);
        var left = current[0] < old[0] ? current[0] : old[0];
        var top = current[1] < old[1] ? current[1] : old[1];
        var right = current[0] > old[0] ? current[0] : old[0];
        var bottom = current[1] > old[1] ? current[1] : old[1];
        var margin = RADIUS + 1;
        dc.setClip(left - margin, top - margin,
            right - left + 2 * margin + 1, bottom - top + 2 * margin + 1);
        if (previous >= 0) {
            dc.setColor(FaceColors.background(), FaceColors.background());
            dc.fillCircle(old[0], old[1], RADIUS);
        }
        dc.setColor(FaceColors.getDisplayColor(), FaceColors.background());
        dc.fillCircle(current[0], current[1], RADIUS);
        dc.clearClip();
    }
}
