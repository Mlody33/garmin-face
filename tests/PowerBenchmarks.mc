import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Simulator timing only; excluded from the production PRG.
(:test)
function renderingPerformance(logger as Test.Logger) as Lang.Boolean {
    var keys = [FaceOptions.KEY, FaceOptions.LIGHT_BACKGROUND_KEY, FaceOptions.ANALOG_SECONDS_KEY];
    var previous = [Storage.getValue(keys[0]), Storage.getValue(keys[1]), Storage.getValue(keys[2])];
    try {
        var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
        var dc = bitmap.getDc();
        FaceOptions.saveSimpleView(false);
        MetricFields.load();
        FaceColors.load();
        for (var light = 0; light < 2; light += 1) {
            FaceOptions.saveLightBackground(light == 1);
            for (var analog = 0; analog < 2; analog += 1) {
                FaceOptions.saveAnalogSeconds(analog == 1);
                var view = new GarminFaceView();
                view.onUpdate(dc);
                var stats = System.getSystemStats();
                logger.debug("MEMORY light=" + light + " analog=" + analog + " used=" + stats.usedMemory + " free=" + stats.freeMemory);
                var start = System.getTimer();
                for (var frame = 0; frame < 50; frame += 1) { view.onUpdate(dc); }
                logger.debug("BENCH full50 light=" + light + " analog=" + analog + " ms=" + (System.getTimer() - start));
            }
            AnalogSeconds.draw(dc, 0, -1, null);
            var start = System.getTimer();
            for (var frame = 1; frame <= 1200; frame += 1) {
                AnalogSeconds.draw(dc, frame % 60, (frame - 1) % 60, null);
            }
            logger.debug("BENCH analog1200 light=" + light + " ms=" + (System.getTimer() - start));
            var font = FaceFonts.seconds();
            DigitalSeconds.prepare(dc, font, FaceColors.background(), FaceColors.secondary());
            var width = dc.getTextWidthInPixels("00", font) + 2;
            var height = dc.getFontHeight(font) + 4;
            start = System.getTimer();
            for (var frame = 0; frame < 1200; frame += 1) {
                DigitalSeconds.draw(dc, 10, height / 2, 0, width, frame % 60, frame == 0 ? -1 : (frame - 1) % 60);
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
