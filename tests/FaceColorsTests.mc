import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

(:test)
function accentPersistsAndMigratesPreviousClockColor(logger as Test.Logger) as Lang.Boolean {
    var previous = [Storage.getValue(FaceColors.KEY), Storage.getValue("clockColor")];
    var savedMetric = Storage.getValue(MetricFields.key(0));
    try {
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
        TestStorage.restore([FaceColors.KEY, "clockColor"], previous);
        throw ex;
    }
    TestStorage.restore([FaceColors.KEY, "clockColor"], previous);
    return true;
}
