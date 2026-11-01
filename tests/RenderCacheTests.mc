import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

(:test)
function renderCacheReusesUnchangedSceneAndInvalidatesSettingsAndReturn(logger as Test.Logger) as Lang.Boolean {
    var keys = [FaceOptions.KEY, FaceOptions.LIGHT_BACKGROUND_KEY,
        MetricFields.key(0), MetricFields.key(1), MetricFields.key(2), FaceColors.KEY];
    var previous = [];
    for (var i = 0; i < keys.size(); i += 1) { previous.add(Storage.getValue(keys[i])); }
    try {
        var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
        var dc = bitmap.getDc();
        FaceOptions.saveSimpleView(true);
        FaceOptions.saveLightBackground(false);
        for (var slot = 0; slot < 3; slot += 1) { MetricFields.save(slot, MetricFields.NONE); }
        FaceColors.save(Graphics.COLOR_WHITE);
        var view = new GarminFaceView();
        view.onShow();
        view.onUpdate(dc);
        Test.assertEqual(view.renderCount(), 1);
        // There is deliberately no changing activity data in this scene.
        var minute = Time.now().value() / 60;
        var count = view.renderCount();
        for (var frame = 0; frame < 10; frame += 1) { view.onUpdate(dc); }
        if (Time.now().value() / 60 == minute) { Test.assertEqual(view.renderCount(), count); }

        count = view.renderCount();
        FaceOptions.saveLightBackground(true);
        view.onUpdate(dc);
        Test.assertEqual(view.renderCount(), count + 1);
        count = view.renderCount();
        FaceOptions.saveSimpleView(false);
        view.onUpdate(dc);
        Test.assertEqual(view.renderCount(), count + 1);
        count = view.renderCount();
        MetricFields.save(1, MetricFields.BATTERY);
        view.onUpdate(dc);
        Test.assertEqual(view.renderCount(), count + 1);
        count = view.renderCount();
        FaceColors.save(Graphics.COLOR_BLUE);
        view.onUpdate(dc);
        Test.assertEqual(view.renderCount(), count + 1);
        count = view.renderCount();
        view.onShow();
        view.onUpdate(dc);
        Test.assertEqual(view.renderCount(), count + 1);
        logger.debug("CACHE invalidation and digital seconds rendered successfully");
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}
