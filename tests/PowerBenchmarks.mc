import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.Time;

// Simulator timing only; excluded from the production PRG.
(:test)
function renderingPerformance(logger as Test.Logger) as Lang.Boolean {
    var keys = [FaceOptions.KEY, FaceOptions.LIGHT_BACKGROUND_KEY];
    var previous = [Storage.getValue(keys[0]), Storage.getValue(keys[1])];
    try {
        var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
        var dc = bitmap.getDc();
        FaceOptions.saveSimpleView(false);
        MetricFields.load();
        FaceColors.load();
        for (var light = 0; light < 2; light += 1) {
            FaceOptions.saveLightBackground(light == 1);
            var view = new SleepTestView();
            view.onUpdate(dc);
            var stats = System.getSystemStats();
            logger.debug("MEMORY light=" + light + " used=" + stats.usedMemory + " free=" + stats.freeMemory);
            var start = System.getTimer();
            for (var frame = 0; frame < 50; frame += 1) { view.onUpdate(dc); }
            logger.debug("BENCH full50 light=" + light + " ms=" + (System.getTimer() - start));
            view.onEnterSleep();
            view.onUpdate(dc);
            var epoch = view.metricsUpdatedAt();
            start = System.getTimer();
            for (var second = 1; second < 60; second += 1) { view.partialAt(dc, epoch + second); }
            logger.debug("BENCH partial59 light=" + light + " ms=" + (System.getTimer() - start));
            var font = FaceFonts.seconds();
            DigitalSeconds.prepare(dc, font, FaceColors.background(), FaceColors.secondary());
            var width = dc.getTextWidthInPixels("00", font) + 2;
            var height = dc.getFontHeight(font) + 4;
            start = System.getTimer();
            for (var frame = 0; frame < 1200; frame += 1) {
                // Production onUpdate restores the scene before every second.
                DigitalSeconds.draw(dc, 10, height / 2, 0, width, frame % 60);
            }
            logger.debug("BENCH digital1200 light=" + light + " ms=" + (System.getTimer() - start)
                + " atlas=" + DigitalSeconds._canRasterize);
            start = System.getTimer();
            for (var frame = 0; frame < 1200; frame += 1) {
                dc.setClip(9, 0, width, height);
                dc.setColor(FaceColors.background(), FaceColors.background());
                dc.fillRectangle(9, 0, width, height);
                dc.setColor(FaceColors.secondary(), FaceColors.background());
                dc.drawText(10, height / 2, font, (frame % 60).format("%02d"),
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.clearClip();
            }
            logger.debug("BENCH nativeDigital1200 light=" + light + " ms=" + (System.getTimer() - start));
        }
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}

(:test)
function changingMetricAndPartialUpdatePerformance(logger as Test.Logger) as Lang.Boolean {
    var keys = [MetricFields.key(0), MetricFields.key(1), MetricFields.key(2),
        FaceOptions.KEY, FaceOptions.LIGHT_BACKGROUND_KEY];
    var previous = [];
    for (var i = 0; i < keys.size(); i += 1) { previous.add(Storage.getValue(keys[i])); }
    try {
        MetricFields.save(0, MetricFields.STEPS);
        MetricFields.save(1, MetricFields.CALORIES);
        MetricFields.save(2, MetricFields.STRESS);
        FaceOptions.saveSimpleView(false);
        FaceColors.load();
        var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
        var dc = bitmap.getDc();
        for (var theme = 0; theme < 2; theme += 1) {
            FaceOptions.saveLightBackground(theme == 1);
            for (var changing = 0; changing < 2; changing += 1) {
                var view = new ChangingMetricTestView();
                view.onUpdate(dc);
                var renders = view.renderCount();
                var samples = view.samples;
                var clockMinute = Time.now().value() / 60;
                var start = System.getTimer();
                for (var i = 0; i < 50; i += 1) {
                    if (changing == 1) { view.stress = 7 + i % 2; }
                    view.onUpdate(dc);
                }
                logger.debug("BENCH active50 light=" + theme + " changing=" + changing
                    + " ms=" + (System.getTimer() - start) + " rebuilds=" + (view.renderCount() - renders)
                    + " samples=" + (view.samples - samples)
                    + " sameMinute=" + (clockMinute == Time.now().value() / 60));
                view.onEnterSleep();
                view.onUpdate(dc);
                var epoch = view.metricsUpdatedAt();
                renders = view.renderCount();
                samples = view.samples;
                start = System.getTimer();
                // Simulate all 59 per-second callbacks between minute updates.
                for (var second = 1; second < 60; second += 1) {
                    if (changing == 1) { view.stress = 7 + (second / 3) % 2; }
                    view.partialAt(dc, epoch + second);
                }
                logger.debug("BENCH sleep59 light=" + theme + " changing=" + changing
                    + " ms=" + (System.getTimer() - start) + " rebuilds=" + (view.renderCount() - renders)
                    + " samples=" + (view.samples - samples));
                Test.assertEqual(view.samples - samples, 38);
                Test.assertEqual(view.renderCount(), renders);
            }
        }
    } catch (ex) {
        TestStorage.restore(keys, previous);
        throw ex;
    }
    TestStorage.restore(keys, previous);
    return true;
}
