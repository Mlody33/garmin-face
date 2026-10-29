import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

(:test)
function metricValuesHandleMissingAndBoundaries(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(MetricFields.formatValue(MetricFields.STRESS, 0), "0");
    Test.assertEqual(MetricFields.formatValue(MetricFields.STRESS, 100), "100");
    Test.assertEqual(MetricFields.formatValue(MetricFields.STRESS, 101), "--");
    Test.assertEqual(MetricFields.formatValue(MetricFields.HEART_RATE, 0), "--");
    Test.assertEqual(MetricFields.formatValue(MetricFields.HEART_RATE, 72), "72");
    Test.assertEqual(MetricFields.formatValue(MetricFields.STEPS, null), "--");
    Test.assertEqual(MetricFields.formatValue(MetricFields.CALORIES, -1), "--");
    Test.assertEqual(MetricFields.formatValue(MetricFields.FLOORS, 0), "0");
    return true;
}

(:test)
function metricUnitsAndChoices(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(MetricFields.formatValue(MetricFields.DISTANCE, 123456), "1.2km");
    Test.assertEqual(MetricFields.formatValue(MetricFields.DISTANCE, 0), "0.0km");
    Test.assertEqual(MetricFields.formatValue(MetricFields.BATTERY, 56.8), "56%");
    Test.assertEqual(MetricFields.formatValue(MetricFields.BATTERY, 101), "--");
    var options = MetricFields.choices();
    Test.assertEqual(options.size(), 7);
    for (var i = 0; i < options.size(); i += 1) {
        Test.assert(MetricFields.isValid(options[i]));
        Test.assert(MetricFields.label(options[i]).length() > 0);
        for (var j = i + 1; j < options.size(); j += 1) {
            Test.assert(!options[i].equals(options[j]));
        }
    }
    return true;
}

(:test)
function metricSlotsPersistIndependentlyAndRecoverInvalidData(logger as Test.Logger) as Lang.Boolean {
    var previous = [Storage.getValue(MetricFields.key(0)),
                    Storage.getValue(MetricFields.key(1)), Storage.getValue(MetricFields.key(2))];
    try {
        Storage.deleteValue(MetricFields.key(0));
        Storage.setValue(MetricFields.key(1), "removedMetric");
        Storage.setValue(MetricFields.key(2), 42);
        MetricFields.load();
        Test.assertEqual(MetricFields.get(0), MetricFields.STEPS);
        Test.assertEqual(MetricFields.get(1), MetricFields.CALORIES);
        Test.assertEqual(MetricFields.get(2), MetricFields.STRESS);

        Test.assert(MetricFields.save(0, MetricFields.HEART_RATE));
        Test.assert(MetricFields.save(1, MetricFields.BATTERY));
        Test.assert(MetricFields.save(2, MetricFields.DISTANCE));
        MetricFields.load();
        Test.assertEqual(MetricFields.get(0), MetricFields.HEART_RATE);
        Test.assertEqual(MetricFields.get(1), MetricFields.BATTERY);
        Test.assertEqual(MetricFields.get(2), MetricFields.DISTANCE);

        Test.assert(!MetricFields.save(-1, MetricFields.STEPS));
        Test.assert(!MetricFields.save(3, MetricFields.STEPS));
        Test.assert(!MetricFields.save(0, "unknown"));
        Test.assertEqual(MetricFields.get(0), MetricFields.HEART_RATE);
        Test.assertEqual(Storage.getValue(MetricFields.key(0)), MetricFields.HEART_RATE);

        // Repeated metrics are allowed, and changing one slot leaves the others intact.
        Test.assert(MetricFields.save(2, MetricFields.HEART_RATE));
        MetricFields.load();
        Test.assertEqual(MetricFields.get(0), MetricFields.HEART_RATE);
        Test.assertEqual(MetricFields.get(1), MetricFields.BATTERY);
        Test.assertEqual(MetricFields.get(2), MetricFields.HEART_RATE);
    } catch (ex) {
        TestStorage.restore([MetricFields.key(0), MetricFields.key(1), MetricFields.key(2)], previous);
        throw ex;
    }
    TestStorage.restore([MetricFields.key(0), MetricFields.key(1), MetricFields.key(2)], previous);
    return true;
}
