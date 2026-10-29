import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module MetricNavigation {
    function slotAt(x as Lang.Number, y as Lang.Number) as Lang.Number or Null {
        // FR955: 70 px columns centered at 60/130/200, covering icons and values.
        // Leave the time, date and the goal arc outside the press targets.
        var left = FaceLayout.FIELD_FIRST_X - FaceLayout.FIELD_SPACING / 2;
        if (x < left || x >= left + FaceLayout.FIELD_COUNT * FaceLayout.FIELD_SPACING
            || y < FaceLayout.FIELD_TOUCH_TOP || y > FaceLayout.FIELD_TOUCH_BOTTOM) { return null; }
        return (x - left) / FaceLayout.FIELD_SPACING;
    }

    function complicationType(metric as Lang.String) as Complications.Type or Null {
        switch (metric) {
            case MetricFields.STEPS: return Complications.COMPLICATION_TYPE_STEPS;
            case MetricFields.CALORIES: return Complications.COMPLICATION_TYPE_CALORIES;
            case MetricFields.STRESS: return Complications.COMPLICATION_TYPE_STRESS;
            case MetricFields.HEART_RATE: return Complications.COMPLICATION_TYPE_HEART_RATE;
            case MetricFields.BATTERY: return Complications.COMPLICATION_TYPE_BATTERY;
            case MetricFields.FLOORS: return Complications.COMPLICATION_TYPE_FLOORS_CLIMBED;
            // Garmin has no daily-distance complication; use its steps overview.
            case MetricFields.DISTANCE: return Complications.COMPLICATION_TYPE_STEPS;
        }
        return null;
    }
}

class GarminFaceDelegate extends WatchUi.WatchFaceDelegate {
    function initialize() {
        WatchFaceDelegate.initialize();
    }

    function onPress(event as WatchUi.ClickEvent) as Lang.Boolean {
        var point = event.getCoordinates();
        var slot = MetricNavigation.slotAt(point[0], point[1]);
        if (slot == null) { return false; }
        var type = MetricNavigation.complicationType(MetricFields.get(slot));
        if (type == null) { return false; }
        try {
            Complications.exitTo(new Complications.Id(type));
            return true;
        } catch (ex instanceof Lang.InvalidValueException) {
            System.println("Native metric view unavailable: " + type.toString());
        } catch (ex instanceof Complications.ComplicationNotFoundException) {
            System.println("Native metric complication unavailable: " + type.toString());
        }
        return false;
    }
}
