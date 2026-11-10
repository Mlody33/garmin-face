import Toybox.ActivityMonitor;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Cache completed calendar days: Garmin exposes at most seven history entries.
module GoalHistory {
    const KEY = "goalHistoryDays";
    var _days as Lang.Array<[Lang.Number, Lang.Number or Null, Lang.Number or Null]> = [];
    var _loaded as Lang.Boolean = false;
    var _checkStamp as Lang.Number = -1;
    var _firstDay as Lang.Number = -1;
    var steps as Lang.Number or Null = null;
    var minutes as Lang.Number or Null = null;

    function invalidate() as Void { _checkStamp = -1; }

    function calendarDay(moment as Time.Moment) as Lang.Number {
        var date = Gregorian.info(moment, Time.FORMAT_SHORT);
        return Gregorian.moment({:year => date.year, :month => date.month, :day => date.day,
            :hour => 12}).value() / 86400;
    }

    function refresh(now as Time.Moment, firstDay as Lang.Number) as Void {
        var minute = now.value() / 60;
        if (_checkStamp == minute && _firstDay == firstDay) { return; }
        _checkStamp = minute;
        var today = calendarDay(now);
        _firstDay = firstDay;
        if (!_loaded) {
            _loaded = true;
            var saved = Storage.getValue(KEY);
            if (saved instanceof Lang.Array) {
                for (var i = 0; i + 2 < saved.size(); i += 3) {
                    if (!(saved[i] instanceof Lang.Number)) { continue; }
                    if (saved[i + 1] != null && !(saved[i + 1] instanceof Lang.Number)) { continue; }
                    if (saved[i + 2] != null && !(saved[i + 2] instanceof Lang.Number)) { continue; }
                    merge(saved[i], saved[i + 1], saved[i + 2]);
                }
            }
        }
        var changed = false;
        var history = ActivityMonitor.getHistory();
        for (var i = 0; i < history.size(); i += 1) {
            var entry = history[i];
            if (entry.startOfDay == null) { continue; }
            var day = calendarDay(entry.startOfDay);
            if (day >= today || day < today - 14) { continue; }
            var active = entry has :activeMinutes ? entry.activeMinutes : null;
            if (merge(day, entry.steps, active == null ? null : active.total)) { changed = true; }
        }
        for (var i = _days.size() - 1; i >= 0; i -= 1) {
            if (_days[i][0] < today - 14 || _days[i][0] >= today) {
                _days.remove(_days[i]); changed = true;
            }
        }
        if (changed) {
            var saved = [] as Lang.Array<Storage.ValueType>;
            for (var i = 0; i < _days.size(); i += 1) {
                saved.add(_days[i][0]); saved.add(_days[i][1]); saved.add(_days[i][2]);
            }
            Storage.setValue(KEY, saved);
        }
        var weekday = Gregorian.info(now, Time.FORMAT_SHORT).day_of_week;
        var result = previous(today, weekday, firstDay, _days);
        steps = result[0]; minutes = result[1];
        // getHistory() is newest-completed-day first. Read this independently
        // of the complete calendar week; the simulator's Yesterday editor can
        // retain older startOfDay timestamps even after its clock advances.
        if (history.size() > 0 && history[0].steps != null && history[0].steps >= 0) {
            steps = history[0].steps;
        }
    }

    function merge(day as Lang.Number, count as Lang.Number or Null, active as Lang.Number or Null) as Lang.Boolean {
        if (count != null && count < 0) { count = null; }
        if (active != null && active < 0) { active = null; }
        for (var i = 0; i < _days.size(); i += 1) {
            var row = _days[i];
            if (row[0] != day) { continue; }
            var changed = false;
            if (count != null && row[1] != count) { row[1] = count; changed = true; }
            if (active != null && row[2] != active) { row[2] = active; changed = true; }
            return changed;
        }
        _days.add([day, count, active]);
        return true;
    }

    function previous(today as Lang.Number, weekday as Lang.Number, firstDay as Lang.Number,
            days as Lang.Array<[Lang.Number, Lang.Number or Null, Lang.Number or Null]>)
            as [Lang.Number or Null, Lang.Number or Null] {
        var count = null;
        var start = today - (weekday - firstDay + 7) % 7 - 7;
        var found = 0;
        var total = 0;
        for (var offset = 0; offset < 7; offset += 1) {
            for (var i = 0; i < days.size(); i += 1) {
                var row = days[i];
                if (row[0] == start + offset && row[2] != null && row[2] >= 0) {
                    total += row[2]; found += 1; break;
                }
            }
        }
        for (var i = 0; i < days.size(); i += 1) {
            if (days[i][0] == today - 1) { count = days[i][1]; break; }
        }
        return [count != null && count >= 0 ? count : null, found == 7 ? total : null];
    }
}
