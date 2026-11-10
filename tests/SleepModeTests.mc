import Toybox.Application.Storage;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

(:test)
class SleepTestView extends GarminFaceView {
    function initialize() { GarminFaceView.initialize(); }
    function lastDrawnSecond() as Lang.Number { return _lastSecond; }
    function metricsUpdatedAt() as Lang.Number { return _metricsUpdatedAt; }
    function partialAt(dc as Graphics.Dc, now as Lang.Number) as Void {
        refreshSleepingFields(dc, now);
    }
}

(:test)
class ChangingMetricTestView extends SleepTestView {
    var stress as Lang.Number or Null = 7;
    var samples as Lang.Number = 0;
    var widthMeasurements as Lang.Number = 0;

    function initialize() { SleepTestView.initialize(); }
    function fieldText(slot as Lang.Number) as Lang.String { return _values[slot]; }
    protected function measureValueWidth(dc as Graphics.Dc, text as Lang.String) as Lang.Number {
        widthMeasurements += 1;
        return GarminFaceView.measureValueWidth(dc, text);
    }
    protected function metricValue(metric as Lang.String, activity as ActivityMonitor.Info or Null)
            as Lang.Number or Lang.Float or Null {
        samples += 1;
        return metric.equals(MetricFields.STRESS) ? stress : 2000;
    }
}

(:test)
function sleepingMetricsShareSourcesRetainUpdatesAndRejectStaleLayout(logger as Test.Logger) as Lang.Boolean {
    var keys = [MetricFields.key(0), MetricFields.key(1), MetricFields.key(2), FaceOptions.LIGHT_BACKGROUND_KEY];
    var previous = [];
    for (var i = 0; i < keys.size(); i += 1) { previous.add(Storage.getValue(keys[i])); }
    try {
        MetricFields.save(0, MetricFields.STRESS);
        MetricFields.save(1, MetricFields.CALORIES);
        MetricFields.save(2, MetricFields.STRESS);
        var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
        var dc = bitmap.getDc();
        for (var light = 0; light < 2; light += 1) {
            FaceOptions.saveLightBackground(light == 1);
            var view = new ChangingMetricTestView();
            view.onEnterSleep();
            view.onUpdate(dc);
            Test.assertEqual(view.samples, 2);
            var start = view.metricsUpdatedAt();
            var renders = view.renderCount();
            view.stress = 100; // Grow a one-digit reading into three digits.
            view.partialAt(dc, start + 3);
            Test.assertEqual(view.samples, 3); // Calories wait for the 60-second deadline.
            Test.assertEqual(view.fieldText(0), "100");
            Test.assertEqual(view.fieldText(2), "100");
            Test.assertEqual(view.renderCount(), renders);
            view.stress = null; // Erase the wider reading and show missing data.
            view.partialAt(dc, start + 6);
            Test.assertEqual(view.fieldText(0), "--");
            Test.assertEqual(view.fieldText(2), "--");
            view.onUpdate(dc);
            Test.assertEqual(view.renderCount(), renders); // Scene already contains the updated values.
            var samples = view.samples;
            MetricFields.save(0, MetricFields.NONE);
            view.partialAt(dc, start + 9);
            Test.assertEqual(view.samples, samples); // No painting against an outdated layout.
            view.onUpdate(dc);
            Test.assertEqual(view.renderCount(), renders + 1);
            MetricFields.save(0, MetricFields.STRESS);
        }
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}

(:test)
function sleepingMetricsPollEveryThreeSecondsWithoutFullRenders(logger as Test.Logger) as Lang.Boolean {
    var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
    var dc = bitmap.getDc();
    var view = new SleepTestView();
    view.onEnterSleep();
    view.partialAt(dc, Time.now().value()); // No scene exists yet.
    Test.assertEqual(view.metricsUpdatedAt(), -1);
    view.onUpdate(dc);
    var start = view.metricsUpdatedAt();
    var renders = view.renderCount();
    view.partialAt(dc, start + 1);
    view.partialAt(dc, start + 2);
    Test.assertEqual(view.metricsUpdatedAt(), start);
    view.partialAt(dc, start + 3);
    Test.assertEqual(view.metricsUpdatedAt(), start + 3);
    view.partialAt(dc, start + 5);
    Test.assertEqual(view.metricsUpdatedAt(), start + 3);
    view.partialAt(dc, start + 6);
    Test.assertEqual(view.metricsUpdatedAt(), start + 6);
    Test.assertEqual(view.renderCount(), renders);
    Test.assertEqual(view.lastDrawnSecond(), -1);
    view.onShow(); // Do not reuse a scene invalidated by an overlay/settings.
    view.partialAt(dc, start + 9);
    Test.assertEqual(view.metricsUpdatedAt(), start + 6);
    view.onUpdate(dc);
    view.onExitSleep();
    start = view.metricsUpdatedAt();
    view.partialAt(dc, start + 3);
    Test.assertEqual(view.metricsUpdatedAt(), start);
    return true;
}

(:test)
function digitalSecondsDisappearInSleepAndReturnAfterWake(logger as Test.Logger) as Lang.Boolean {
    var keys = [FaceOptions.KEY, FaceOptions.LIGHT_BACKGROUND_KEY];
    var previous = [Storage.getValue(keys[0]), Storage.getValue(keys[1])];
    try {
        var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
        var dc = bitmap.getDc();
        for (var light = 0; light < 2; light += 1) {
            FaceOptions.saveLightBackground(light == 1);
            for (var simple = 0; simple < 2; simple += 1) {
                FaceOptions.saveSimpleView(simple == 1);
                var view = new SleepTestView();
                view.onUpdate(dc);
                Test.assert(view.lastDrawnSecond() >= 0);
                for (var cycle = 0; cycle < 2; cycle += 1) {
                    var renders = view.renderCount();
                    view.onEnterSleep();
                    view.onUpdate(dc);
                    // Icons, arcs and solar labels are part of the cached scene.
                    Test.assertEqual(view.renderCount(), renders + 1);
                    Test.assertEqual(view.lastDrawnSecond(), -1);
                    // Returning from an overlay and minute updates must stay asleep.
                    view.onShow();
                    view.onUpdate(dc);
                    view.onUpdate(dc);
                    Test.assertEqual(view.lastDrawnSecond(), -1);
                    // Changing the layout during sleep must not restore seconds.
                    FaceOptions.saveSimpleView(!FaceOptions.simpleView());
                    view.onUpdate(dc);
                    Test.assertEqual(view.lastDrawnSecond(), -1);
                    renders = view.renderCount();
                    view.onExitSleep();
                    view.onUpdate(dc);
                    Test.assertEqual(view.renderCount(), renders + 1);
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

(:test)
function activeMetricChangesReuseSceneAndWidthsAcrossThemes(logger as Test.Logger) as Lang.Boolean {
    var keys = [MetricFields.key(0), MetricFields.key(1), MetricFields.key(2),
        FaceOptions.KEY, FaceOptions.LIGHT_BACKGROUND_KEY];
    var previous = [];
    for (var i = 0; i < keys.size(); i += 1) { previous.add(Storage.getValue(keys[i])); }
    try {
        MetricFields.save(0, MetricFields.STRESS);
        MetricFields.save(1, MetricFields.CALORIES);
        MetricFields.save(2, MetricFields.STRESS);
        FaceOptions.saveSimpleView(true);
        var dc = (Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap).getDc();
        for (var light = 0; light < 2; light += 1) {
            FaceOptions.saveLightBackground(light == 1);
            var view = new ChangingMetricTestView();
            view.onUpdate(dc);
            Test.assertEqual(view.widthMeasurements, 2); // Duplicate stress shares its width.
            var renders = view.renderCount();
            var minute = Time.now().value() / 60;
            view.stress = 100;
            view.onUpdate(dc);
            Test.assertEqual(view.fieldText(0), "100");
            Test.assertEqual(view.fieldText(2), "100");
            Test.assertEqual(view.widthMeasurements, 3);
            view.stress = null;
            view.onUpdate(dc);
            Test.assertEqual(view.fieldText(0), "--");
            Test.assertEqual(view.widthMeasurements, 4);
            if (Time.now().value() / 60 == minute) { Test.assertEqual(view.renderCount(), renders); }
            view.onShow(); // Full restoration after an overlay remains mandatory.
            renders = view.renderCount();
            view.onUpdate(dc);
            Test.assertEqual(view.renderCount(), renders + 1);
            Test.assertEqual(view.widthMeasurements, 4);
        }
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}

(:test)
function sleepingMetricDeadlinesRespectFastSlowAndDuplicateSources(logger as Test.Logger) as Lang.Boolean {
    var keys = [MetricFields.key(0), MetricFields.key(1), MetricFields.key(2)];
    var previous = [Storage.getValue(keys[0]), Storage.getValue(keys[1]), Storage.getValue(keys[2])];
    try {
        var dc = (Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap).getDc();
        var metrics = [MetricFields.STEPS, MetricFields.HEART_RATE, MetricFields.STRESS,
            MetricFields.BATTERY, MetricFields.CALORIES, MetricFields.FLOORS, MetricFields.DISTANCE];
        var intervals = [3, 3, 3, 60, 60, 60, 60];
        for (var i = 0; i < metrics.size(); i += 1) {
            MetricFields.save(0, metrics[i]);
            MetricFields.save(1, MetricFields.NONE);
            MetricFields.save(2, metrics[i]);
            var view = new ChangingMetricTestView();
            view.onEnterSleep();
            view.onUpdate(dc);
            Test.assertEqual(view.samples, 1);
            var start = view.metricsUpdatedAt();
            for (var second = 1; second < intervals[i]; second += 1) { view.partialAt(dc, start + second); }
            Test.assertEqual(view.samples, 1);
            view.partialAt(dc, start + intervals[i]);
            Test.assertEqual(view.samples, 2);
            view.onExitSleep();
            view.onUpdate(dc);
            Test.assertEqual(view.samples, 3); // Active updates always read fresh data.
        }
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}

(:test)
function partialBudgetFallbackKeepsMinuteUpdatesAndRecoversAfterWake(logger as Test.Logger) as Lang.Boolean {
    var keys = [MetricFields.key(0), MetricFields.key(1), MetricFields.key(2)];
    var previous = [Storage.getValue(keys[0]), Storage.getValue(keys[1]), Storage.getValue(keys[2])];
    try {
        MetricFields.save(0, MetricFields.STRESS);
        MetricFields.save(1, MetricFields.NONE);
        MetricFields.save(2, MetricFields.NONE);
        var dc = (Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap).getDc();
        var view = new ChangingMetricTestView();
        view.onEnterSleep();
        view.onUpdate(dc);
        var start = view.metricsUpdatedAt();
        view.disablePartialUpdates();
        view.stress = 100;
        view.partialAt(dc, start + 3);
        Test.assertEqual(view.samples, 1);
        view.onShow();
        view.onUpdate(dc);
        Test.assertEqual(view.fieldText(0), "100");
        Test.assertEqual(view.samples, 2);
        view.partialAt(dc, view.metricsUpdatedAt() + 3);
        Test.assertEqual(view.samples, 2); // Full updates must not clear the backoff.
        view.onExitSleep();
        view.onUpdate(dc);
        view.onEnterSleep();
        view.onUpdate(dc);
        var samples = view.samples;
        view.stress = 7;
        view.partialAt(dc, view.metricsUpdatedAt() + 3);
        Test.assertEqual(view.samples, samples + 1);
        Test.assertEqual(view.fieldText(0), "7");
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}
