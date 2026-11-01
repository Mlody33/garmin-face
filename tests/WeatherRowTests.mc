import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

(:test)
function weatherTemperaturesRoundAndHandleMissingReadingsIndependently(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(WeatherRow.temperaturesText(8.2, 4.8), "8°/5°");
    Test.assertEqual(WeatherRow.temperaturesText(-3.2, -6.8), "-3°/-7°");
    Test.assertEqual(WeatherRow.temperaturesText(0, 0), "0°/0°");
    Test.assertEqual(WeatherRow.temperaturesText(8, null), "8°/--°");
    Test.assertEqual(WeatherRow.temperaturesText(null, -2), "--°/-2°");
    Test.assertEqual(WeatherRow.temperaturesText(null, null), "--°/--°");
    return true;
}

(:test)
function weatherRowFitsLongDatesAndNegativeTemperatures(logger as Test.Logger) as Lang.Boolean {
    var bitmap = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
    var dc = bitmap.getDc();
    var saved = WeatherRow._currentTemperature;
    try {
        var dates = ["Wed, 30 Sep", "Śr, 30 Paź", "Sun, 1 Nov"];
        var temperatures = ["-40°/-50°", "--°/--°", "8°/5°"];
        for (var d = 0; d < dates.size(); d += 1) {
            for (var t = 0; t < temperatures.size(); t += 1) {
                WeatherRow._currentTemperature = temperatures[t];
                WeatherRow.draw(dc, 130, FaceLayout.DATE_Y, dates[d]);
                var width = WeatherRow._dateWidth + WeatherRow.WEATHER_WIDTH + WeatherRow._temperatureWidth;
                Test.assert(width <= WeatherRow.MAX_ROW_WIDTH);
            }
        }
        // A short row should return to the original font after a compact row.
        WeatherRow._currentTemperature = "8°/5°";
        WeatherRow.draw(dc, 130, FaceLayout.DATE_Y, "Su, 1 Nov");
        Test.assertEqual(WeatherRow._font, FaceFonts.text());
    } catch (ex) {
        WeatherRow._currentTemperature = saved;
        throw ex;
    }
    WeatherRow._currentTemperature = saved;
    WeatherRow.invalidate();
    return true;
}
