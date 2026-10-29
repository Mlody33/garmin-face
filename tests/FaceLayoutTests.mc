import Toybox.Lang;
import Toybox.Test;

(:test)
function layoutsCenterAllVisibleCountsAndKeepDataRowsSymmetric(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(FaceLayout.fieldX(0, 3), 60);
    Test.assertEqual(FaceLayout.fieldX(1, 3), 130);
    Test.assertEqual(FaceLayout.fieldX(2, 3), 200);
    Test.assertEqual(FaceLayout.fieldX(0, 2), 95);
    Test.assertEqual(FaceLayout.fieldX(1, 2), 165);
    Test.assertEqual((FaceLayout.fieldX(0, 2) + FaceLayout.fieldX(1, 2)) / 2, 130);
    Test.assertEqual(FaceLayout.fieldX(0, 1), 130);
    Test.assertEqual(FaceLayout.DATE_Y, 78);
    Test.assertEqual(FaceLayout.CENTER_Y - FaceLayout.DATE_Y,
        FaceLayout.FIELD_VALUE_Y - FaceLayout.CENTER_Y);
    return true;
}

(:test)
function compactedHoldTargetsKeepOriginalSlotsAndExcludeHiddenFields(logger as Test.Logger) as Lang.Boolean {
    var pair = [0, 2];
    Test.assertEqual(MetricNavigation.slotAt(95, 182, pair), 0);
    Test.assertEqual(MetricNavigation.slotAt(165, 182, pair), 2);
    Test.assertEqual(MetricNavigation.slotAt(95, 210, pair), 0);
    Test.assertEqual(MetricNavigation.slotAt(165, 210, pair), 2);
    Test.assertEqual(MetricNavigation.slotAt(60, 166, pair), 0);
    Test.assertEqual(MetricNavigation.slotAt(129, 228, pair), 0);
    Test.assertEqual(MetricNavigation.slotAt(130, 166, pair), 2);
    Test.assertEqual(MetricNavigation.slotAt(199, 228, pair), 2);
    Test.assert(MetricNavigation.slotAt(59, 200, pair) == null);
    Test.assert(MetricNavigation.slotAt(200, 200, pair) == null);
    Test.assert(MetricNavigation.slotAt(130, 165, pair) == null);
    Test.assert(MetricNavigation.slotAt(130, 229, pair) == null);
    Test.assert(MetricNavigation.slotAt(130, 130, pair) == null);
    Test.assertEqual(MetricNavigation.slotAt(130, 182, [2]), 2);
    Test.assertEqual(MetricNavigation.slotAt(95, 210, [2]), 2);
    Test.assert(MetricNavigation.slotAt(165, 210, [2]) == null);
    Test.assert(MetricNavigation.slotAt(130, 182, []) == null);
    return true;
}
