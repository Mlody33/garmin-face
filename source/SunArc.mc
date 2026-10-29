import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module SunArc {
    var _font as Graphics.FontType or Null = null;
    var _sunriseId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE);
    var _sunsetId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET);
    var _sunrise as Lang.Number or Null = null;
    var _sunset as Lang.Number or Null = null;
    var _sunriseText as Lang.String = "--:--";
    var _sunsetText as Lang.String = "--:--";

    function draw(dc as Graphics.Dc, secondsToday as Lang.Number) as Void {
        var sunrise = readEvent(_sunriseId);
        var sunset = readEvent(_sunsetId);
        if (sunrise != _sunrise) {
            _sunrise = sunrise;
            _sunriseText = eventText(sunrise);
        }
        if (sunset != _sunset) {
            _sunset = sunset;
            _sunsetText = eventText(sunset);
        }
        ProgressArc.draw(dc, 126, Graphics.ARC_CLOCKWISE, progress(secondsToday, sunrise, sunset));
        if (_font == null) {
            _font = Graphics.getVectorFont({:face => "RobotoCondensedRegular", :size => 21});
            if (_font == null) { _font = Graphics.FONT_XTINY; }
        }
        dc.setColor(FaceColors.secondary(), FaceColors.background());
        var font = _font as Graphics.FontType;
        dc.drawText(FaceLayout.fieldX(0, FaceLayout.FIELD_COUNT), FaceLayout.SUN_Y, font, _sunriseText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(FaceLayout.fieldX(2, FaceLayout.FIELD_COUNT), FaceLayout.SUN_Y, font, _sunsetText,
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
