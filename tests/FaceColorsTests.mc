import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

(:test)
function accentPersistsAndMigratesPreviousClockColor(logger as Test.Logger) as Lang.Boolean {
    var previous = [Storage.getValue(FaceColors.KEY), Storage.getValue("clockColor"),
        Storage.getValue(FaceOptions.LIGHT_BACKGROUND_KEY)];
    var savedMetric = Storage.getValue(MetricFields.key(0));
    try {
        FaceOptions.saveLightBackground(false);
        Storage.deleteValue(FaceColors.KEY);
        Storage.deleteValue("clockColor");
        FaceColors.load();
        Test.assertEqual(FaceColors.get(), Graphics.COLOR_WHITE);

        Storage.setValue("clockColor", Graphics.COLOR_GREEN);
        FaceColors.load();
        Test.assertEqual(FaceColors.get(), Graphics.COLOR_GREEN);
        Test.assertEqual(FaceColors.getDisplayColor(), 0xAAFFAA);

        Test.assert(FaceColors.save(Graphics.COLOR_BLUE));
        Test.assertEqual(FaceColors.getDisplayColor(), 0x55AAFF);
        Storage.setValue("clockColor", Graphics.COLOR_RED);
        FaceColors.load();
        Test.assertEqual(FaceColors.get(), Graphics.COLOR_BLUE);
        Test.assertEqual(FaceColors.getDisplayColor(), 0x55AAFF);
        Test.assertEqual(Storage.getValue(MetricFields.key(0)), savedMetric);
        Test.assert(!FaceColors.save(Graphics.COLOR_BLACK));
        FaceColors.load();
        Test.assertEqual(FaceColors.get(), Graphics.COLOR_BLUE);

        Storage.setValue(FaceColors.KEY, "invalid");
        FaceColors.load();
        Test.assertEqual(FaceColors.get(), Graphics.COLOR_WHITE);
        Test.assertEqual(FaceColors.getDisplayColor(), Graphics.COLOR_WHITE);
        Storage.setValue(FaceColors.KEY, Graphics.COLOR_BLACK);
        FaceColors.load();
        Test.assertEqual(FaceColors.get(), Graphics.COLOR_WHITE);
        Storage.deleteValue(FaceColors.KEY);
        Storage.setValue("clockColor", "invalid");
        FaceColors.load();
        Test.assertEqual(FaceColors.get(), Graphics.COLOR_WHITE);

        var options = FaceColors.choices();
        for (var i = 0; i < options.size(); i += 1) {
            Test.assert(FaceColors.save(options[i]));
            FaceColors.load();
            Test.assertEqual(FaceColors.get(), options[i]);
            Test.assert(FaceColors.label(options[i]).length() > 0);
        }
    } catch (ex) {
        TestStorage.restore([FaceColors.KEY, "clockColor", FaceOptions.LIGHT_BACKGROUND_KEY], previous);
        throw ex;
    }
    TestStorage.restore([FaceColors.KEY, "clockColor", FaceOptions.LIGHT_BACKGROUND_KEY], previous);
    return true;
}

(:test)
function changingBackgroundKeepsAccentAndReadableColors(logger as Test.Logger) as Lang.Boolean {
    var keys = [FaceColors.KEY, FaceOptions.LIGHT_BACKGROUND_KEY];
    var previous = [Storage.getValue(FaceColors.KEY), Storage.getValue(FaceOptions.LIGHT_BACKGROUND_KEY)];
    try {
        var options = FaceColors.choices();
        for (var i = 0; i < options.size(); i += 1) {
            FaceOptions.saveLightBackground(false);
            Test.assert(FaceColors.save(options[i]));
            var darkAccent = FaceColors.getDisplayColor();
            FaceOptions.saveLightBackground(true);
            Test.assertEqual(FaceColors.background(), Graphics.COLOR_WHITE);
            Test.assertEqual(FaceColors.secondary(), Graphics.COLOR_DK_GRAY);
            Test.assert(FaceColors.getDisplayColor() != FaceColors.background());
            Test.assert(FaceColors.track() != FaceColors.background());
            Test.assertEqual(Storage.getValue(FaceColors.KEY), options[i]);
            if (options[i] == Graphics.COLOR_WHITE) {
                Test.assertEqual(FaceColors.getDisplayColor(), Graphics.COLOR_BLACK);
            }
            FaceOptions.saveLightBackground(false);
            Test.assertEqual(FaceColors.background(), Graphics.COLOR_BLACK);
            Test.assertEqual(FaceColors.secondary(), Graphics.COLOR_LT_GRAY);
            Test.assertEqual(FaceColors.getDisplayColor(), darkAccent);
        }
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}
