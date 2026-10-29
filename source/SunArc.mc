import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;

module SunArc {
    var _font as Graphics.FontType or Null = null;
    var _startEvent as Lang.Number or Null = null;
    var _endEvent as Lang.Number or Null = null;
    var _startText as Lang.String = "--:--";
    var _endText as Lang.String = "--:--";
    var _stamp as Lang.Number = -1;

    function invalidate() as Void { _stamp = -1; }

    function refresh(now as Time.Moment) as Void {
        var stamp = now.value() / 60;
        if (_stamp == stamp) { return; }
        _stamp = stamp;
        SolarTimes.refresh(now, SolarPosition.resolve(WeatherRow.location()));
    }

    function currentProgress(now as Lang.Number) as Lang.Float or Null {
        SolarTimes.update(now);
        return SolarTimes.progress(now, SolarTimes.current());
    }

    function currentDaylight() as Lang.Boolean or Null {
        var interval = SolarTimes.current();
        return interval == null ? null : interval[2];
    }

    function draw(dc as Graphics.Dc, sunProgress as Lang.Float or Null) as Void {
        var interval = SolarTimes.current();
        var start = interval == null ? null : interval[0];
        var end = interval == null ? null : interval[1];
        if (start != _startEvent) { _startEvent = start; _startText = SolarTimes.eventText(start); }
        if (end != _endEvent) { _endEvent = end; _endText = SolarTimes.eventText(end); }
        ProgressArc.draw(dc, 126, Graphics.ARC_CLOCKWISE, sunProgress);
        if (_font == null) {
            _font = Graphics.getVectorFont({:face => "RobotoCondensedRegular", :size => 21});
            if (_font == null) { _font = Graphics.FONT_XTINY; }
        }
        dc.setColor(FaceColors.secondary(), FaceColors.background());
        var font = _font as Graphics.FontType;
        dc.drawText(FaceLayout.CENTER_X - FaceLayout.SUN_OFFSET_X, FaceLayout.SUN_Y, font, _startText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(FaceLayout.CENTER_X + FaceLayout.SUN_OFFSET_X, FaceLayout.SUN_Y, font, _endText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
