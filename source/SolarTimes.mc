import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

// Dated events come from Garmin Weather using the device's last known position.
// Retain coordinates in RAM only; never activate GPS or estimate a night as 24 hours.
module SolarTimes {
    var _events as Lang.Array<[Lang.Number, Lang.Boolean]> = [];
    var _interval as [Lang.Number, Lang.Number, Lang.Boolean] or Null = null;
    var _day as Lang.Number = -1;
    var _latitude as Lang.Number = 0;
    var _longitude as Lang.Number = 0;
    var _location as Position.Location or Null = null;
    var _revision as Lang.Number = 0;

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
            if (_location != null) { _revision += 1; }
            _events = []; _interval = null; _location = null; _day = -1;
            return;
        }
        var anchor = dateAnchor(now, location);
        var coordinates = location.toDegrees();
        var latitude = Math.round(coordinates[0] * 1000).toNumber();
        var longitude = Math.round(coordinates[1] * 1000).toNumber();
        if (_location == null || _day != anchor.value() || _latitude != latitude || _longitude != longitude) {
            _events = eventsAround(anchor, location);
            _revision += 1;
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

    function revision() as Lang.Number { return _revision; }

    function roundedEvent(timestamp as Lang.Number) as Time.Moment {
        var remainder = timestamp % 60;
        return new Time.Moment(timestamp - remainder + (remainder >= 30 ? 60 : 0));
    }

    function localMinute(timestamp as Lang.Number, location as Position.Location) as Lang.Number {
        var event = roundedEvent(timestamp);
        var local = Gregorian.localMoment(location, event);
        var info = local == null ? Gregorian.info(event, Time.FORMAT_SHORT) : Gregorian.info(local, Time.FORMAT_SHORT);
        return info.hour * 60 + info.min;
    }

    // Select the same kind of event on the previous local calendar day.
    function previousEvent(timestamp as Lang.Number, sunrise as Lang.Boolean,
            events as Lang.Array<[Lang.Number, Lang.Boolean]>, location as Position.Location) as Lang.Number or Null {
        var previousDay = dateAnchor(new Time.Moment(timestamp), location).value() - 86400;
        for (var i = 0; i < events.size(); i += 1) {
            var event = events[i];
            if (event[1] != sunrise || event[0] >= timestamp) { continue; }
            if (dateAnchor(new Time.Moment(event[0]), location).value() != previousDay) { continue; }
            return event[0];
        }
        return null;
    }

    // Compare both displayed times after rounding each event to the nearest minute.
    // The previous event may belong to yesterday or two days ago for a night interval.
    function changeMinutes(timestamp as Lang.Number, sunrise as Lang.Boolean,
            events as Lang.Array<[Lang.Number, Lang.Boolean]>, location as Position.Location) as Lang.Number or Null {
        var previous = previousEvent(timestamp, sunrise, events, location);
        if (previous == null) { return null; }
        var difference = localMinute(timestamp, location) - localMinute(previous, location);
        // A solar event crossing local midnight still shifts by only a few minutes.
        if (difference > 720) { difference -= 1440; }
        else if (difference < -720) { difference += 1440; }
        return difference;
    }

    function eventLabel(timestamp as Lang.Number or Null, sunrise as Lang.Boolean) as Lang.String {
        var text = eventText(timestamp);
        if (timestamp == null || _location == null) { return text; }
        var change = changeMinutes(timestamp, sunrise, _events, _location as Position.Location);
        if (change == null) { return text; }
        return text + " " + (change >= 0 ? "+" : "") + change.toString();
    }

    function progress(now as Lang.Number, interval as [Lang.Number, Lang.Number, Lang.Boolean] or Null) as Lang.Float or Null {
        if (interval == null || interval[1] <= interval[0] || now < interval[0] || now >= interval[1]) { return null; }
        return (now - interval[0]).toFloat() / (interval[1] - interval[0]);
    }

    function eventText(timestamp as Lang.Number or Null) as Lang.String {
        if (timestamp == null) { return "--:--"; }
        // Round labels to the nearest minute; exact timestamps still drive progress and date selection.
        var event = roundedEvent(timestamp);
        var local = _location == null ? null : Gregorian.localMoment(_location as Position.Location, event);
        var info = local == null ? Gregorian.info(event, Time.FORMAT_SHORT) : Gregorian.info(local, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }
}
