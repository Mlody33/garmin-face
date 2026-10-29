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

    var _fields as Lang.Array<Lang.String> = [STEPS, CALORIES, STRESS];
    var _heartRateId as Complications.Id or Null = null;

    function choices() as Lang.Array<Lang.String> {
        return [STEPS, CALORIES, STRESS, HEART_RATE, BATTERY, DISTANCE, FLOORS];
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
    }

    function get(slot as Lang.Number) as Lang.String {
        return _fields[slot];
    }

    function save(slot as Lang.Number, metric as Lang.String) as Lang.Boolean {
        if (slot < 0 || slot >= FaceLayout.FIELD_COUNT || !isValid(metric)) { return false; }
        Storage.setValue(key(slot), metric);
        _fields[slot] = metric;
        return true;
    }

    function label(metric as Lang.String) as Lang.String {
        var resource = Rez.Strings.StepsLabel;
        switch (metric) {
            case CALORIES: resource = Rez.Strings.CaloriesLabel; break;
            case STRESS: resource = Rez.Strings.StressLabel; break;
            case HEART_RATE: resource = Rez.Strings.HeartRateLabel; break;
            case BATTERY: resource = Rez.Strings.BatteryLabel; break;
            case DISTANCE: resource = Rez.Strings.DistanceLabel; break;
            case FLOORS: resource = Rez.Strings.FloorsLabel; break;
        }
        return WatchUi.loadResource(resource) as Lang.String;
    }

    function value(metric as Lang.String, activity as ActivityMonitor.Info) as Lang.Number or Lang.Float or Null {
        switch (metric) {
            case STEPS: return activity.steps;
            case CALORIES: return activity.calories;
            case STRESS: return activity has :stressScore ? activity.stressScore : null;
            case BATTERY: return System.getSystemStats().battery;
            case DISTANCE: return activity.distance;
            case FLOORS: return activity.floorsClimbed;
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
