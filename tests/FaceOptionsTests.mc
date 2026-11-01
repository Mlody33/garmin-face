import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

(:test)
function simpleViewDefaultsAndPersistsWithoutChangingOtherSettings(logger as Test.Logger) as Lang.Boolean {
    var previous = [Storage.getValue(FaceOptions.KEY)];
    var accent = Storage.getValue(FaceColors.KEY);
    var metric = Storage.getValue(MetricFields.key(0));
    try {
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
        TestStorage.assertEqual(Storage.getValue(FaceColors.KEY), accent);
        TestStorage.assertEqual(Storage.getValue(MetricFields.key(0)), metric);
    } catch (ex) {
        TestStorage.restore([FaceOptions.KEY], previous);
        throw ex;
    }
    TestStorage.restore([FaceOptions.KEY], previous);
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
        TestStorage.assertEqual(Storage.getValue(FaceOptions.KEY), simple);
        TestStorage.assertEqual(Storage.getValue(FaceColors.KEY), accent);
        TestStorage.assertEqual(Storage.getValue(MetricFields.key(0)), metric);
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
