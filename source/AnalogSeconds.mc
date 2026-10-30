import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// Keep the dot inside the progress arcs and cache its 60 positions.
module AnalogSeconds {
    const RADIUS = 3;
    const ORBIT = 116;
    var _markers as Lang.Array<[Lang.Number, Lang.Number]> = [];
    var _clips as Lang.Array<[Lang.Number, Lang.Number, Lang.Number, Lang.Number]> = [];
    var _background as Lang.Number = Graphics.COLOR_BLACK;
    var _accent as Lang.Number = Graphics.COLOR_WHITE;

    function prepare(background as Lang.Number, accent as Lang.Number) as Void {
        _background = background;
        _accent = accent;
        marker(0);
        if (_clips.size() == 0) {
            for (var second = 0; second < 60; second += 1) {
                _clips.add(bounds(second, second == 0 ? 59 : second - 1));
            }
        }
    }

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

    function bounds(second as Lang.Number, previous as Lang.Number) as [Lang.Number, Lang.Number, Lang.Number, Lang.Number] {
        var current = _markers[second];
        var old = previous < 0 ? current : _markers[previous];
        var left = current[0] < old[0] ? current[0] : old[0];
        var top = current[1] < old[1] ? current[1] : old[1];
        var right = current[0] > old[0] ? current[0] : old[0];
        var bottom = current[1] > old[1] ? current[1] : old[1];
        return [left - RADIUS, top - RADIUS, right - left + 2 * RADIUS + 1, bottom - top + 2 * RADIUS + 1];
    }

    function draw(dc as Graphics.Dc, second as Lang.Number, previous as Lang.Number,
                  background as Graphics.BitmapType or Null) as Void {
        var current = _markers[second];
        var clip = previous == (second == 0 ? 59 : second - 1) ? _clips[second] : bounds(second, previous);
        dc.setClip(clip[0], clip[1], clip[2], clip[3]);
        if (previous >= 0) {
            if (background != null) {
                // Restore cached pixels, including any text/icon near the inner edge.
                dc.drawBitmap(0, 0, background);
            } else {
                var old = _markers[previous];
                dc.setColor(_background, _background);
                dc.fillCircle(old[0], old[1], RADIUS);
            }
        }
        dc.setColor(_accent, _background);
        dc.fillCircle(current[0], current[1], RADIUS);
        dc.clearClip();
    }
}
