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
    Test.assertEqual(options.size(), 8);
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

(:test)
function noneFieldsPersistAndCompactWithoutLosingSlotIdentity(logger as Test.Logger) as Lang.Boolean {
    var keys = [MetricFields.key(0), MetricFields.key(1), MetricFields.key(2)];
    var previous = [Storage.getValue(keys[0]), Storage.getValue(keys[1]), Storage.getValue(keys[2])];
    try {
        Test.assert(MetricFields.save(0, MetricFields.HEART_RATE));
        Test.assert(MetricFields.save(1, MetricFields.BATTERY));
        Test.assert(MetricFields.save(2, MetricFields.DISTANCE));
        Test.assertEqual(MetricFields.visibleSlots().size(), 3);

        Test.assert(MetricFields.save(1, MetricFields.NONE));
        MetricFields.load();
        Test.assertEqual(MetricFields.get(1), MetricFields.NONE);
        Test.assertEqual(MetricFields.visibleSlots().size(), 2);
        Test.assertEqual(MetricFields.visibleSlots()[0], 0);
        Test.assertEqual(MetricFields.visibleSlots()[1], 2);
        Test.assertEqual(MetricNavigation.slotAt(165, 182, MetricFields.visibleSlots()), 2);

        Test.assert(MetricFields.save(0, MetricFields.NONE));
        MetricFields.load();
        Test.assertEqual(MetricFields.visibleSlots().size(), 1);
        Test.assertEqual(MetricFields.visibleSlots()[0], 2);
        Test.assertEqual(MetricNavigation.slotAt(130, 182, MetricFields.visibleSlots()), 2);

        Test.assert(MetricFields.save(2, MetricFields.NONE));
        MetricFields.load();
        Test.assertEqual(MetricFields.visibleSlots().size(), 0);
        Test.assert(MetricNavigation.slotAt(130, 182, MetricFields.visibleSlots()) == null);
        Test.assert(MetricFields.save(1, MetricFields.STEPS));
        Test.assertEqual(MetricFields.visibleSlots().size(), 1);
        Test.assertEqual(MetricFields.visibleSlots()[0], 1);
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}

(:test)
function independentMetricsWorkWithoutActivityAndDependenciesFollowSettings(logger as Test.Logger) as Lang.Boolean {
    var keys = [MetricFields.key(0), MetricFields.key(1), MetricFields.key(2)];
    var previous = [Storage.getValue(keys[0]), Storage.getValue(keys[1]), Storage.getValue(keys[2])];
    try {
        MetricFields.save(0, MetricFields.BATTERY);
        MetricFields.save(1, MetricFields.HEART_RATE);
        MetricFields.save(2, MetricFields.NONE);
        MetricFields.load();
        Test.assert(!MetricFields.needsActivity());
        Test.assert(MetricFields.value(MetricFields.BATTERY, null) != null);
        // A missing native heart-rate reading is also valid; this must not need activity info.
        MetricFields.value(MetricFields.HEART_RATE, null);
        var metrics = [MetricFields.STEPS, MetricFields.CALORIES, MetricFields.STRESS,
            MetricFields.DISTANCE, MetricFields.FLOORS];
        for (var i = 0; i < metrics.size(); i += 1) {
            MetricFields.save(2, metrics[i]);
            Test.assert(MetricFields.needsActivity());
            Test.assert(MetricFields.value(metrics[i], null) == null);
            MetricFields.save(2, MetricFields.NONE);
            Test.assert(!MetricFields.needsActivity());
        }
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}
