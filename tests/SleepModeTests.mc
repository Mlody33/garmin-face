import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

(:test)
class SleepTestView extends GarminFaceView {
    function initialize() { GarminFaceView.initialize(); }
    function lastDrawnSecond() as Lang.Number { return _lastSecond; }
}

(:test)
function secondsDisappearInSleepAndReturnAfterWakeForBothModes(logger as Test.Logger) as Lang.Boolean {
    var keys = [FaceOptions.ANALOG_SECONDS_KEY, FaceOptions.LIGHT_BACKGROUND_KEY];
    var previous = [Storage.getValue(keys[0]), Storage.getValue(keys[1])];
    try {
        var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
        var dc = bitmap.getDc();
        for (var light = 0; light < 2; light += 1) {
            FaceOptions.saveLightBackground(light == 1);
            for (var analog = 0; analog < 2; analog += 1) {
                FaceOptions.saveAnalogSeconds(analog == 1);
                var view = new SleepTestView();
                view.onUpdate(dc);
                Test.assert(view.lastDrawnSecond() >= 0);
                for (var cycle = 0; cycle < 2; cycle += 1) {
                    view.onEnterSleep();
                    view.onUpdate(dc);
                    Test.assertEqual(view.lastDrawnSecond(), -1);
                    // Returning from an overlay and minute updates must stay asleep.
                    view.onShow();
                    view.onUpdate(dc);
                    view.onUpdate(dc);
                    Test.assertEqual(view.lastDrawnSecond(), -1);
                    // Switching seconds mode during sleep must not show either type.
                    FaceOptions.saveAnalogSeconds(!FaceOptions.analogSeconds());
                    view.onUpdate(dc);
                    Test.assertEqual(view.lastDrawnSecond(), -1);
                    view.onExitSleep();
                    view.onUpdate(dc);
                    Test.assert(view.lastDrawnSecond() >= 0);
                }
                // Some lifecycle sequences enter sleep before the first frame.
                view = new SleepTestView();
                view.onEnterSleep();
                view.onUpdate(dc);
                Test.assertEqual(view.lastDrawnSecond(), -1);
                view.onExitSleep();
                view.onUpdate(dc);
                Test.assert(view.lastDrawnSecond() >= 0);
            }
        }
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}
