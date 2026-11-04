import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Weather;

// Current temperature from Garmin's cached weather reading.
module WeatherRow {
    const MAX_ROW_WIDTH = 220;
    const WEATHER_WIDTH = 38; // 14 px gap and 24 px icon/spacing.
    var _dateText as Lang.String = "";
    var _temperatureText as Lang.String = "";
    var _dateWidth as Lang.Number = 0;
    var _temperatureWidth as Lang.Number = 0;
    var _stamp as Lang.Number = -1;
    var _condition as Lang.Number or Null = null;
    var _currentTemperature as Lang.String = "--°";
    var _font as Graphics.FontType = Graphics.FONT_GLANCE;
    var _compactFont as Graphics.FontType or Null = null;

    function invalidate() as Void { _stamp = -1; }

    function refresh(stamp as Lang.Number) as Void {
        if (_stamp == stamp) { return; }
        _stamp = stamp;
        var conditions = Weather.getCurrentConditions();
        _currentTemperature = temperatureText(conditions == null ? null : conditions.temperature);
        _condition = conditions == null ? null : conditions.condition;
    }

    function draw(dc as Graphics.Dc, centerX as Lang.Number, y as Lang.Number,
                  dateText as Lang.String) as Void {
        var text = _currentTemperature;

        if (!text.equals(_temperatureText) || !dateText.equals(_dateText)) {
            _temperatureText = text;
            _dateText = dateText;
            _font = FaceFonts.text();
            _temperatureWidth = dc.getTextWidthInPixels(text, _font);
            _dateWidth = dc.getTextWidthInPixels(dateText, _font);
            // Long dates and negative temperatures must fit the round display.
            if (_dateWidth + WEATHER_WIDTH + _temperatureWidth > MAX_ROW_WIDTH) {
                if (_compactFont == null) {
                    _compactFont = Graphics.getVectorFont({:face => "RobotoCondensedBold", :size => 22});
                    if (_compactFont == null) { _compactFont = Graphics.FONT_XTINY; }
                }
                _font = _compactFont as Graphics.FontType;
                _temperatureWidth = dc.getTextWidthInPixels(text, _font);
                _dateWidth = dc.getTextWidthInPixels(dateText, _font);
            }
        }
        var font = _font;
        var gap = 14;
        var rowLeft = centerX - (_dateWidth + WEATHER_WIDTH + _temperatureWidth) / 2;
        dc.setColor(FaceColors.secondary(), FaceColors.background());
        dc.drawText(rowLeft, y, font, dateText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        var left = rowLeft + _dateWidth + gap;
        drawIcon(dc, left + 8, y, _condition);
        dc.drawText(left + 24, y, font, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function temperatureText(value as Lang.Numeric or Null) as Lang.String {
        if (value == null) {
            return "--°";
        }
        return Math.round(value).toNumber().toString() + "°";
    }

    function drawIcon(dc as Graphics.Dc, x as Lang.Number,
                      y as Lang.Number, condition as Lang.Number or Null) as Void {
        // Draw vector shapes: no dependence on emoji or weather-font glyphs.
        if (condition == null) {
            dc.drawLine(x - 5, y, x + 5, y);
            return;
        }
        switch (condition) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_FAIR:
            case Weather.CONDITION_MOSTLY_CLEAR:
                drawSun(dc, x, y);
                return;
            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_THIN_CLOUDS:
                drawSun(dc, x - 3, y - 3);
                drawCloud(dc, x + 2, y + 2);
                return;
            case Weather.CONDITION_MOSTLY_CLOUDY:
            case Weather.CONDITION_CLOUDY:
                drawCloud(dc, x, y);
                return;
            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
                drawCloud(dc, x, y - 3);
                dc.drawLine(x + 1, y, x - 2, y + 4);
                dc.drawLine(x - 2, y + 4, x + 2, y + 4);
                dc.drawLine(x + 2, y + 4, x - 1, y + 8);
                return;
            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:
            case Weather.CONDITION_CHANCE_OF_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
            case Weather.CONDITION_FLURRIES:
            case Weather.CONDITION_ICE_SNOW:
                drawCloud(dc, x, y - 3);
                dc.drawLine(x - 5, y + 3, x + 1, y + 7);
                dc.drawLine(x + 1, y + 3, x - 5, y + 7);
                dc.drawLine(x - 2, y + 2, x - 2, y + 8);
                return;
            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_SCATTERED_SHOWERS:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_LIGHT_SHOWERS:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_HEAVY_SHOWERS:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
            case Weather.CONDITION_FREEZING_RAIN:
            case Weather.CONDITION_WINTRY_MIX:
            case Weather.CONDITION_LIGHT_RAIN_SNOW:
            case Weather.CONDITION_HEAVY_RAIN_SNOW:
            case Weather.CONDITION_RAIN_SNOW:
            case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_SLEET:
            case Weather.CONDITION_HAIL:
            case Weather.CONDITION_UNKNOWN_PRECIPITATION:
                drawCloud(dc, x, y - 3);
                dc.drawLine(x - 4, y + 3, x - 6, y + 7);
                dc.drawLine(x + 1, y + 3, x - 1, y + 7);
                dc.drawLine(x + 6, y + 3, x + 4, y + 7);
                return;
            case Weather.CONDITION_WINDY:
            case Weather.CONDITION_SQUALL:
            case Weather.CONDITION_TORNADO:
            case Weather.CONDITION_HURRICANE:
            case Weather.CONDITION_TROPICAL_STORM:
                dc.drawLine(x - 8, y - 4, x + 5, y - 4);
                dc.drawLine(x - 5, y, x + 8, y);
                dc.drawLine(x - 8, y + 4, x + 3, y + 4);
                return;
            case Weather.CONDITION_FOG:
            case Weather.CONDITION_MIST:
            case Weather.CONDITION_HAZY:
            case Weather.CONDITION_HAZE:
            case Weather.CONDITION_DUST:
            case Weather.CONDITION_SMOKE:
            case Weather.CONDITION_SAND:
            case Weather.CONDITION_SANDSTORM:
            case Weather.CONDITION_VOLCANIC_ASH:
                drawCloud(dc, x, y - 3);
                dc.drawLine(x - 7, y + 4, x + 7, y + 4);
                dc.drawLine(x - 5, y + 7, x + 5, y + 7);
                return;
            default:
                dc.drawLine(x - 5, y, x + 5, y);
        }
    }

    function drawSun(dc as Graphics.Dc, x as Lang.Number,
                     y as Lang.Number) as Void {
        dc.drawCircle(x, y, 4);
        dc.drawLine(x, y - 8, x, y - 6);
        dc.drawLine(x, y + 6, x, y + 8);
        dc.drawLine(x - 8, y, x - 6, y);
        dc.drawLine(x + 6, y, x + 8, y);
        dc.drawLine(x - 6, y - 6, x - 5, y - 5);
        dc.drawLine(x + 5, y - 5, x + 6, y - 6);
        dc.drawLine(x - 6, y + 6, x - 5, y + 5);
        dc.drawLine(x + 5, y + 5, x + 6, y + 6);
    }

    function drawCloud(dc as Graphics.Dc, x as Lang.Number,
                       y as Lang.Number) as Void {
        dc.fillCircle(x - 5, y + 1, 4);
        dc.fillCircle(x, y - 2, 5);
        dc.fillCircle(x + 5, y + 1, 4);
        dc.fillRectangle(x - 5, y, 11, 5);
    }
}
