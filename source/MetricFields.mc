import Toybox.ActivityMonitor;
import Toybox.Application.Storage;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module MetricFields {
    const STEPS = "steps";
    const CALORIES = "calories";
    const STRESS = "stress";
    const HEART_RATE = "heartRate";
    const BATTERY = "battery";
    const DISTANCE = "distance";
    const FLOORS = "floors";
    const NONE = "none";

    var _fields as Lang.Array<Lang.String> = [STEPS, CALORIES, STRESS];
    var _visibleSlots as Lang.Array<Lang.Number> = [0, 1, 2];
    var _firstSlots as Lang.Array<Lang.Number> = [0, 1, 2];
    var _heartRateId as Complications.Id or Null = null;
    var _revision as Lang.Number = 0;
    var _needsActivity as Lang.Boolean = true;
    var _activitySlots as Lang.Number = 7;

    function choices() as Lang.Array<Lang.String> {
        return [STEPS, CALORIES, STRESS, HEART_RATE, BATTERY, DISTANCE, FLOORS, NONE];
    }

    function key(slot as Lang.Number) as Lang.String {
        return "metricSlot" + slot.toString();
    }

    function isValid(value as Lang.Object or Null) as Lang.Boolean {
        if (!(value instanceof Lang.String)) { return false; }
        var options = choices();
        for (var i = 0; i < options.size(); i += 1) {
            if (options[i].equals(value)) { return true; }
        }
        return false;
    }

    function load() as Void {
        var defaults = [STEPS, CALORIES, STRESS];
        for (var slot = 0; slot < FaceLayout.FIELD_COUNT; slot += 1) {
            var stored = Storage.getValue(key(slot));
            _fields[slot] = isValid(stored) ? stored as Lang.String : defaults[slot];
        }
        updateVisibleSlots();
    }

    function get(slot as Lang.Number) as Lang.String {
        return _fields[slot];
    }

    function save(slot as Lang.Number, metric as Lang.String) as Lang.Boolean {
        if (slot < 0 || slot >= FaceLayout.FIELD_COUNT || !isValid(metric)) { return false; }
        Storage.setValue(key(slot), metric);
        _fields[slot] = metric;
        updateVisibleSlots();
        return true;
    }

    function visibleSlots() as Lang.Array<Lang.Number> {
        return _visibleSlots;
    }

    function firstSlot(slot as Lang.Number) as Lang.Number { return _firstSlots[slot]; }

    function revision() as Lang.Number { return _revision; }

    function updateVisibleSlots() as Void {
        _revision += 1;
        _visibleSlots = [];
        _needsActivity = false;
        _activitySlots = 0;
        for (var slot = 0; slot < FaceLayout.FIELD_COUNT; slot += 1) {
            var metric = _fields[slot];
            // The configuration changes rarely; resolve shared readings here.
            _firstSlots[slot] = slot;
            for (var prior = 0; prior < slot; prior += 1) {
                if (_fields[prior].equals(metric)) { _firstSlots[slot] = prior; break; }
            }
            if (!metric.equals(NONE)) {
                _visibleSlots.add(slot);
                if (!metric.equals(BATTERY) && !metric.equals(HEART_RATE)) {
                    _needsActivity = true;
                    _activitySlots |= 1 << slot;
                }
            }
        }
    }

    function needsActivity() as Lang.Boolean { return _needsActivity; }

    function activitySlots() as Lang.Number { return _activitySlots; }

    function sleepInterval(metric as Lang.String) as Lang.Number {
        switch (metric) {
            case STEPS:
            case HEART_RATE:
            case STRESS: return 3;
        }
        return 60;
    }

    function label(metric as Lang.String) as Lang.String {
        var resource = Rez.Strings.StepsLabel;
        switch (metric) {
            case NONE: resource = Rez.Strings.NoneLabel; break;
            case CALORIES: resource = Rez.Strings.CaloriesLabel; break;
            case STRESS: resource = Rez.Strings.StressLabel; break;
            case HEART_RATE: resource = Rez.Strings.HeartRateLabel; break;
            case BATTERY: resource = Rez.Strings.BatteryLabel; break;
            case DISTANCE: resource = Rez.Strings.DistanceLabel; break;
            case FLOORS: resource = Rez.Strings.FloorsLabel; break;
        }
        return WatchUi.loadResource(resource) as Lang.String;
    }

    function value(metric as Lang.String, activity as ActivityMonitor.Info or Null) as Lang.Number or Lang.Float or Null {
        switch (metric) {
            case STEPS: return activity == null ? null : activity.steps;
            case CALORIES: return activity == null ? null : activity.calories;
            case STRESS: return activity != null && activity has :stressScore ? activity.stressScore : null;
            case BATTERY:
                // Only whole percent is displayed; sub-percent changes need no formatting.
                var battery = System.getSystemStats().battery;
                return battery >= 0 && battery <= 100 ? battery.toNumber() : null;
            case DISTANCE: return activity == null ? null : activity.distance;
            case FLOORS: return activity == null ? null : activity.floorsClimbed;
            case HEART_RATE:
                // Read the watch's existing measurement; do not start a sensor session.
                if (_heartRateId == null) {
                    _heartRateId = new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE);
                }
                try {
                    var reading = Complications.getComplication(_heartRateId as Complications.Id).value;
                    if (reading instanceof Lang.Number || reading instanceof Lang.Float) {
                        return reading;
                    }
                } catch (ex instanceof Complications.ComplicationNotFoundException) {
                    return null;
                }
                return null;
        }
        return null;
    }

    function formatValue(metric as Lang.String, reading as Lang.Number or Lang.Float or Null) as Lang.String {
        if (reading == null || reading < 0) { return "--"; }
        if ((metric.equals(STRESS) || metric.equals(BATTERY)) && reading > 100) { return "--"; }
        if (metric.equals(HEART_RATE) && reading == 0) { return "--"; }
        if (metric.equals(DISTANCE)) {
            // ActivityMonitor reports centimetres. All distance fields use kilometres.
            return (reading.toFloat() / 100000.0).format("%.1f") + "km";
        }
        var text = reading.toNumber().toString();
        return metric.equals(BATTERY) ? text + "%" : text;
    }
}
