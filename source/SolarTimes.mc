import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

// Events carry absolute timestamps. No 24-hour approximation is used for a night.
module SolarTimes {
    var _events as Lang.Array<[Lang.Number, Lang.Boolean]> = [];
    var _interval as [Lang.Number, Lang.Number, Lang.Boolean] or Null = null;
    var _day as Lang.Number = -1;
    var _latitude as Lang.Number = 0;
    var _longitude as Lang.Number = 0;
    var _location as Position.Location or Null = null;

    function dateAnchor(now as Time.Moment, location as Position.Location) as Time.Moment {
        var local = Gregorian.localMoment(location, now);
        var date = local == null ? Gregorian.info(now, Time.FORMAT_SHORT) : Gregorian.info(local, Time.FORMAT_SHORT);
        // Calendar labels are represented at UTC noon; offsets stay calendar days
        // even on a local 23/25-hour DST day. Returned solar events remain UTC epochs.
        return Gregorian.moment({:year => date.year, :month => date.month, :day => date.day,
            :hour => 12, :minute => 0, :second => 0});
    }

    function eventsAround(anchor as Time.Moment, location as Position.Location) as Lang.Array<[Lang.Number, Lang.Boolean]> {
        var events = [];
        // A wider window also brackets events near the International Date Line.
        for (var offset = -2; offset <= 2; offset += 1) {
            var date = new Time.Moment(anchor.value() + offset * 86400);
            var sunrise = Weather.getSunrise(location, date);
            var sunset = Weather.getSunset(location, date);
            if (sunrise != null) { events.add([sunrise.value(), true]); }
            if (sunset != null) { events.add([sunset.value(), false]); }
        }
        return events;
    }

    function refresh(now as Time.Moment, location as Position.Location or Null) as Void {
        if (location == null) {
            _events = []; _interval = null; _location = null; _day = -1;
            return;
        }
        var anchor = dateAnchor(now, location);
        var coordinates = location.toDegrees();
        var latitude = Math.round(coordinates[0] * 1000).toNumber();
        var longitude = Math.round(coordinates[1] * 1000).toNumber();
        if (_location == null || _day != anchor.value() || _latitude != latitude || _longitude != longitude) {
            _events = eventsAround(anchor, location);
            _interval = null;
            _day = anchor.value();
            _latitude = latitude;
            _longitude = longitude;
        }
        _location = location;
        update(now.value());
    }

    // Order-independent selection of the last event and the next opposite event.
    function intervalAt(now as Lang.Number, events as Lang.Array<[Lang.Number, Lang.Boolean]>)
            as [Lang.Number, Lang.Number, Lang.Boolean] or Null {
        var start = null;
        var end = null;
        for (var i = 0; i < events.size(); i += 1) {
            var event = events[i];
            if (event[0] <= now && (start == null || event[0] > start[0])) { start = event; }
            if (event[0] > now && (end == null || event[0] < end[0])) { end = event; }
        }
        if (start == null || end == null || start[1] == end[1]) { return null; }
        return [start[0], end[0], start[1]];
    }

    function update(now as Lang.Number) as Void {
        if (_interval == null || now < _interval[0] || now >= _interval[1]) {
            _interval = intervalAt(now, _events);
        }
    }

    function current() as [Lang.Number, Lang.Number, Lang.Boolean] or Null { return _interval; }

    function progress(now as Lang.Number, interval as [Lang.Number, Lang.Number, Lang.Boolean] or Null) as Lang.Float or Null {
        if (interval == null || interval[1] <= interval[0] || now < interval[0] || now >= interval[1]) { return null; }
        return (now - interval[0]).toFloat() / (interval[1] - interval[0]);
    }

    function eventText(timestamp as Lang.Number or Null) as Lang.String {
        if (timestamp == null) { return "--:--"; }
        var event = new Time.Moment(timestamp);
        var local = _location == null ? null : Gregorian.localMoment(_location as Position.Location, event);
        var info = local == null ? Gregorian.info(event, Time.FORMAT_SHORT) : Gregorian.info(local, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }
}
