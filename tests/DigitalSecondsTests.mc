import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

(:test)
function digitalSecondsRenderAllValuesAndRebuildForDifferentFonts(logger as Test.Logger) as Lang.Boolean {
    var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
    var dc = bitmap.getDc();
    var fonts = [FaceFonts.seconds(), Graphics.FONT_XTINY, FaceFonts.text(), FaceFonts.seconds()];
    for (var light = 0; light < 2; light += 1) {
        var background = light == 0 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var foreground = light == 0 ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
        for (var f = 0; f < fonts.size(); f += 1) {
            var font = fonts[f];
            DigitalSeconds.prepare(dc, font, background, foreground);
            var width = dc.getTextWidthInPixels("00", font) + 2;
            var height = dc.getFontHeight(font) + 4;
            if (DigitalSeconds._canRasterize) {
                Test.assertEqual(DigitalSeconds._digits.size(), 10);
                Test.assertEqual(DigitalSeconds._text.size(), 0);
                for (var digit = 0; digit < 10; digit += 1) {
                    Test.assertEqual(DigitalSeconds._digits[digit].getHeight(), height);
                    Test.assertEqual(DigitalSeconds._digits[digit].getWidth(), dc.getTextWidthInPixels("0", font));
                }
            } else {
                Test.assertEqual(DigitalSeconds._text.size(), 60);
            }
            for (var second = 0; second < 60; second += 1) {
                // Every production update restores the complete scene first.
                dc.setColor(background, background);
                dc.clear();
                DigitalSeconds.draw(dc, 10, height / 2, 0, width, second);
            }
            logger.debug("DIGITAL values light=" + light + " font=" + f + " atlas=" + DigitalSeconds._canRasterize);
        }
    }
    return true;
}
