import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

(:test)
function simpleViewDefaultsAndPersistsWithoutChangingOtherSettings(logger as Test.Logger) as Lang.Boolean {
    var previous = [Storage.getValue(FaceOptions.KEY), Storage.getValue(FaceOptions.ANALOG_SECONDS_KEY)];
    var accent = Storage.getValue(FaceColors.KEY);
    var metric = Storage.getValue(MetricFields.key(0));
    try {
        FaceOptions.saveAnalogSeconds(false);
        Storage.deleteValue(FaceOptions.KEY);
        FaceOptions.load();
        Test.assert(!FaceOptions.simpleView());
        Storage.setValue(FaceOptions.KEY, "true");
        FaceOptions.load();
        Test.assert(!FaceOptions.simpleView());
        Storage.setValue(FaceOptions.KEY, 1);
        FaceOptions.load();
        Test.assert(!FaceOptions.simpleView());

        FaceOptions.saveSimpleView(true);
        Test.assert(FaceOptions.simpleView());
        FaceOptions.load();
        Test.assert(FaceOptions.simpleView());
        FaceOptions.saveSimpleView(false);
        FaceOptions.load();
        Test.assert(!FaceOptions.simpleView());
        Test.assertEqual(Storage.getValue(FaceColors.KEY), accent);
        Test.assertEqual(Storage.getValue(MetricFields.key(0)), metric);
    } catch (ex) {
        TestStorage.restore([FaceOptions.KEY, FaceOptions.ANALOG_SECONDS_KEY], previous);
        throw ex;
    }
    TestStorage.restore([FaceOptions.KEY, FaceOptions.ANALOG_SECONDS_KEY], previous);
    return true;
}

(:test)
function analogSecondsPersistIndependentlyOfSimpleView(logger as Test.Logger) as Lang.Boolean {
    var keys = [FaceOptions.KEY, FaceOptions.ANALOG_SECONDS_KEY];
    var previous = [Storage.getValue(FaceOptions.KEY), Storage.getValue(FaceOptions.ANALOG_SECONDS_KEY)];
    var background = Storage.getValue(FaceOptions.LIGHT_BACKGROUND_KEY);
    var accent = Storage.getValue(FaceColors.KEY);
    try {
        Storage.deleteValue(FaceOptions.ANALOG_SECONDS_KEY);
        FaceOptions.load();
        Test.assert(!FaceOptions.analogSeconds());
        FaceOptions.saveSimpleView(false);
        FaceOptions.saveAnalogSeconds(true);
        Test.assert(FaceOptions.analogSeconds());
        Test.assert(!FaceOptions.simpleView());
        FaceOptions.load();
        Test.assert(FaceOptions.analogSeconds());
        Test.assert(!FaceOptions.simpleView());
        FaceOptions.saveAnalogSeconds(false);
        Test.assert(!FaceOptions.analogSeconds());
        Test.assert(!FaceOptions.simpleView());
        FaceOptions.saveAnalogSeconds(true);
        FaceOptions.saveSimpleView(false);
        FaceOptions.load();
        Test.assert(FaceOptions.analogSeconds());
        Test.assert(!FaceOptions.simpleView());
        FaceOptions.saveSimpleView(true);
        FaceOptions.load();
        Test.assert(FaceOptions.analogSeconds());
        Test.assert(FaceOptions.simpleView());
        FaceOptions.saveAnalogSeconds(false);
        FaceOptions.load();
        Test.assert(FaceOptions.simpleView());
        Test.assert(!FaceOptions.analogSeconds());

        Storage.setValue(FaceOptions.ANALOG_SECONDS_KEY, "true");
        FaceOptions.load();
        Test.assert(!FaceOptions.analogSeconds());
        Storage.setValue(FaceOptions.ANALOG_SECONDS_KEY, true);
        Storage.setValue(FaceOptions.KEY, false);
        FaceOptions.load();
        Test.assert(FaceOptions.analogSeconds());
        Test.assert(!FaceOptions.simpleView());
        Test.assertEqual(Storage.getValue(FaceOptions.LIGHT_BACKGROUND_KEY), background);
        Test.assertEqual(Storage.getValue(FaceColors.KEY), accent);
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}

(:test)
function lightBackgroundDefaultsAndPersistsIndependently(logger as Test.Logger) as Lang.Boolean {
    var previous = [Storage.getValue(FaceOptions.LIGHT_BACKGROUND_KEY)];
    var simple = Storage.getValue(FaceOptions.KEY);
    var accent = Storage.getValue(FaceColors.KEY);
    var metric = Storage.getValue(MetricFields.key(0));
    try {
        Storage.deleteValue(FaceOptions.LIGHT_BACKGROUND_KEY);
        FaceOptions.load();
        Test.assert(!FaceOptions.lightBackground());
        Storage.setValue(FaceOptions.LIGHT_BACKGROUND_KEY, "true");
        FaceOptions.load();
        Test.assert(!FaceOptions.lightBackground());
        Storage.setValue(FaceOptions.LIGHT_BACKGROUND_KEY, 1);
        FaceOptions.load();
        Test.assert(!FaceOptions.lightBackground());

        FaceOptions.saveLightBackground(true);
        Test.assert(FaceOptions.lightBackground());
        FaceOptions.load();
        Test.assert(FaceOptions.lightBackground());
        Test.assertEqual(Storage.getValue(FaceOptions.KEY), simple);
        Test.assertEqual(Storage.getValue(FaceColors.KEY), accent);
        Test.assertEqual(Storage.getValue(MetricFields.key(0)), metric);
        FaceOptions.saveLightBackground(false);
        FaceOptions.load();
        Test.assert(!FaceOptions.lightBackground());
    } catch (ex) {
        TestStorage.restore([FaceOptions.LIGHT_BACKGROUND_KEY], previous);
        throw ex;
    }
    TestStorage.restore([FaceOptions.LIGHT_BACKGROUND_KEY], previous);
    return true;
}
