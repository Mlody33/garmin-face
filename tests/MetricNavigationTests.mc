import Toybox.Complications;
import Toybox.Lang;
import Toybox.Test;

(:test)
function metricHoldTargetsCoverIconsAndValuesWithoutOtherRows(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(MetricNavigation.slotAt(60, 182), 0);
    Test.assertEqual(MetricNavigation.slotAt(130, 182), 1);
    Test.assertEqual(MetricNavigation.slotAt(200, 182), 2);
    Test.assertEqual(MetricNavigation.slotAt(60, 210), 0);
    Test.assertEqual(MetricNavigation.slotAt(130, 210), 1);
    Test.assertEqual(MetricNavigation.slotAt(200, 210), 2);
    Test.assertEqual(MetricNavigation.slotAt(25, 166), 0);
    Test.assertEqual(MetricNavigation.slotAt(94, 228), 0);
    Test.assertEqual(MetricNavigation.slotAt(95, 200), 1);
    Test.assertEqual(MetricNavigation.slotAt(164, 200), 1);
    Test.assertEqual(MetricNavigation.slotAt(165, 200), 2);
    Test.assertEqual(MetricNavigation.slotAt(234, 228), 2);
    Test.assert(MetricNavigation.slotAt(235, 200) == null);
    Test.assert(MetricNavigation.slotAt(24, 200) == null);
    Test.assert(MetricNavigation.slotAt(130, 165) == null);
    Test.assert(MetricNavigation.slotAt(130, 229) == null);
    Test.assert(MetricNavigation.slotAt(130, 130) == null);
    Test.assert(MetricNavigation.slotAt(130, 81) == null);
    Test.assert(MetricNavigation.slotAt(130, 50) == null);
    return true;
}

(:test)
function metricHoldRoutesToMatchingNativeViews(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(MetricNavigation.complicationType(MetricFields.STEPS), Complications.COMPLICATION_TYPE_STEPS);
    Test.assertEqual(MetricNavigation.complicationType(MetricFields.CALORIES), Complications.COMPLICATION_TYPE_CALORIES);
    Test.assertEqual(MetricNavigation.complicationType(MetricFields.STRESS), Complications.COMPLICATION_TYPE_STRESS);
    Test.assertEqual(MetricNavigation.complicationType(MetricFields.HEART_RATE), Complications.COMPLICATION_TYPE_HEART_RATE);
    Test.assertEqual(MetricNavigation.complicationType(MetricFields.BATTERY), Complications.COMPLICATION_TYPE_BATTERY);
    Test.assertEqual(MetricNavigation.complicationType(MetricFields.FLOORS), Complications.COMPLICATION_TYPE_FLOORS_CLIMBED);
    Test.assertEqual(MetricNavigation.complicationType(MetricFields.DISTANCE), Complications.COMPLICATION_TYPE_STEPS);
    Test.assert(MetricNavigation.complicationType("unknown") == null);
    return true;
}
