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
    var _revision as Lang.Number = -1;

    function invalidate() as Void { _stamp = -1; }

    function refresh(now as Time.Moment) as Void {
        var stamp = now.value() / 60;
        if (_stamp == stamp) { return; }
        _stamp = stamp;
        SolarTimes.refresh(now, WeatherRow.location());
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
        ProgressArc.draw(dc, 126, Graphics.ARC_CLOCKWISE, sunProgress, 0, false);
        var interval = SolarTimes.current();
        var start = interval == null ? null : interval[0];
        var end = interval == null ? null : interval[1];
        var revision = SolarTimes.revision();
        var daylight = interval != null && interval[2];
        if (start != _startEvent || _revision != revision) {
            _startEvent = start;
            _startText = SolarTimes.eventLabel(start, daylight);
        }
        if (end != _endEvent || _revision != revision) {
            _endEvent = end;
            _endText = SolarTimes.eventLabel(end, !daylight);
        }
        _revision = revision;
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
