import Toybox.Application;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;
class SolarProbeApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new SolarProbeView()]; }
}
class SolarProbeView extends WatchUi.WatchFace {
    function initialize() { WatchFace.initialize(); }
    function hhmmss(seconds) {
        if (!(seconds instanceof Lang.Number)) { return "--:--:--"; }
        return (seconds / 3600).format("%02d") + ":" + ((seconds / 60) % 60).format("%02d") + ":" + (seconds % 60).format("%02d");
    }
    function nativeTime(type) {
        try { return hhmmss(Complications.getComplication(new Complications.Id(type)).value); }
        catch (ex) { return "--:--:--"; }
    }
    function localTime(moment, location) {
        if (moment == null) { return "--:--:--"; }
        var local = Gregorian.localMoment(location, moment);
        var info = Gregorian.info(local == null ? moment : local, Time.FORMAT_SHORT);
        return hhmmss(info.hour * 3600 + info.min * 60 + info.sec);
    }
    function line(dc, y, text) {
        dc.drawText(130, y, Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_CENTER);
    }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK); dc.clear();
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        line(dc, 18, "SOLAR PROBE " + date.day + "." + date.month);
        line(dc, 43, "N " + nativeTime(Complications.COMPLICATION_TYPE_SUNRISE) + " / " + nativeTime(Complications.COMPLICATION_TYPE_SUNSET));
        var location = Position.getInfo().position;
        if (location == null) { line(dc, 90, "GPS: brak pozycji"); return; }
        var local = Gregorian.localMoment(location, now);
        var calendar = Gregorian.info(local == null ? now : local, Time.FORMAT_SHORT);
        var anchor = Gregorian.moment({:year => calendar.year, :month => calendar.month, :day => calendar.day, :hour => 12});
        for (var day = -1; day <= 1; day += 1) {
            var label = day == -1 ? "W" : (day == 0 ? "D" : "J");
            var target = new Time.Moment(anchor.value() + day * 86400);
            line(dc, 72 + (day + 1) * 27, label + " " + localTime(Weather.getSunrise(location, target), location)
                + " / " + localTime(Weather.getSunset(location, target), location));
        }
        var conditions = Weather.getCurrentConditions();
        var weatherLocation = conditions == null ? null : conditions.observationLocationPosition;
        if (weatherLocation != null) {
            line(dc, 160, "P " + localTime(Weather.getSunrise(weatherLocation, anchor), weatherLocation)
                + " / " + localTime(Weather.getSunset(weatherLocation, anchor), weatherLocation));
        }
        line(dc, 191, "N: natywne  W/D/J: GPS");
        line(dc, 214, "P: pozycja pogody");
    }
}
