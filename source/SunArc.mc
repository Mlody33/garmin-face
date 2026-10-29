import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module SunArc {
    var _font as Graphics.FontType or Null = null;
    var _sunriseId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE);
    var _sunsetId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET);
    var _sunrise as Lang.Number or Null = null;
    var _sunset as Lang.Number or Null = null;
    var _startEvent as Lang.Number or Null = null;
    var _endEvent as Lang.Number or Null = null;
    var _startText as Lang.String = "--:--";
    var _endText as Lang.String = "--:--";
    var _stamp as Lang.Number = -1;

    function invalidate() as Void { _stamp = -1; }

    function refresh(stamp as Lang.Number) as Void {
        if (_stamp == stamp) { return; }
        _stamp = stamp;
        _sunrise = readEvent(_sunriseId);
        _sunset = readEvent(_sunsetId);
    }

    function currentProgress(secondsToday as Lang.Number) as Lang.Float or Null {
        return progress(secondsToday, _sunrise, _sunset);
    }

    function currentDaylight(secondsToday as Lang.Number) as Lang.Boolean or Null {
        return isDaylight(secondsToday, _sunrise, _sunset);
    }

    function intervalStart(daylight as Lang.Boolean or Null, sunrise as Lang.Number or Null,
                           sunset as Lang.Number or Null) as Lang.Number or Null {
        return daylight == false ? sunset : sunrise;
    }

    function intervalEnd(daylight as Lang.Boolean or Null, sunrise as Lang.Number or Null,
                         sunset as Lang.Number or Null) as Lang.Number or Null {
        return daylight == false ? sunrise : sunset;
    }

    function draw(dc as Graphics.Dc, sunProgress as Lang.Float or Null,
                  daylight as Lang.Boolean or Null) as Void {
        var start = intervalStart(daylight, _sunrise, _sunset);
        var end = intervalEnd(daylight, _sunrise, _sunset);
        if (start != _startEvent) { _startEvent = start; _startText = eventText(start); }
        if (end != _endEvent) { _endEvent = end; _endText = eventText(end); }
        ProgressArc.draw(dc, 126, Graphics.ARC_CLOCKWISE, sunProgress);
        if (_font == null) {
            _font = Graphics.getVectorFont({:face => "RobotoCondensedRegular", :size => 21});
            if (_font == null) { _font = Graphics.FONT_XTINY; }
        }
        dc.setColor(FaceColors.secondary(), FaceColors.background());
        var font = _font as Graphics.FontType;
        dc.drawText(FaceLayout.fieldX(0, FaceLayout.FIELD_COUNT), FaceLayout.SUN_Y, font, _startText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(FaceLayout.fieldX(2, FaceLayout.FIELD_COUNT), FaceLayout.SUN_Y, font, _endText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function eventText(seconds as Lang.Number or Null) as Lang.String {
        if (seconds == null) { return "--:--"; }
        return (seconds / 3600).format("%02d") + ":" + ((seconds % 3600) / 60).format("%02d");
    }

    function readEvent(id as Complications.Id) as Lang.Number or Null {
        try {
            var value = Complications.getComplication(id).value;
            if (value instanceof Lang.Number && value >= 0 && value < 86400) { return value; }
        } catch (ex instanceof Complications.ComplicationNotFoundException) {
            // Solar times may be unavailable until the watch has a location.
        }
        return null;
    }

    // Progress through daylight or the following night, continuous at midnight.
    function isDaylight(now as Lang.Number, sunrise as Lang.Number or Null,
                        sunset as Lang.Number or Null) as Lang.Boolean or Null {
        if (sunrise == null || sunset == null || sunrise == sunset) { return null; }
        return (now - sunrise + 86400) % 86400 < (sunset - sunrise + 86400) % 86400;
    }

    function progress(now as Lang.Number, sunrise as Lang.Number or Null,
                      sunset as Lang.Number or Null) as Lang.Float or Null {
        if (sunrise == null || sunset == null) { return null; }
        var daylight = (sunset - sunrise + 86400) % 86400;
        if (daylight == 0) { return null; }
        var elapsed = (now - sunrise + 86400) % 86400;
        return elapsed < daylight ? elapsed.toFloat() / daylight
            : (elapsed - daylight).toFloat() / (86400 - daylight);
    }
}
