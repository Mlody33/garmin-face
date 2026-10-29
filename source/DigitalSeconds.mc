import Toybox.Graphics;
import Toybox.Lang;

// Rasterize only ten digits, once per theme. The partial-update path allocates nothing.
module DigitalSeconds {
    var _digits as Lang.Array<Graphics.BufferedBitmap> = [];
    var _background as Lang.Number = -2;
    var _foreground as Lang.Number = -2;
    var _digitWidth as Lang.Number = 0;
    var _height as Lang.Number = 0;
    var _font as Graphics.FontType or Null = null;
    var _text as Lang.Array<Lang.String> = [];
    var _canRasterize as Lang.Boolean = false;

    function prepare(dc as Graphics.Dc, font as Graphics.FontType,
                     background as Lang.Number, foreground as Lang.Number) as Void {
        if (_font == font && _background == background && _foreground == foreground) { return; }
        _font = font;
        _background = background;
        _foreground = foreground;
        _height = dc.getFontHeight(font) + 4;
        _digitWidth = dc.getTextWidthInPixels("0", font);
        _canRasterize = true;
        for (var digit = 0; digit < 10; digit += 1) {
            if (dc.getTextWidthInPixels(digit.toString(), font) != _digitWidth) { _canRasterize = false; }
        }
        if (_text.size() == 0) {
            for (var second = 0; second < 60; second += 1) { _text.add(second.format("%02d")); }
        }
        for (var second = 0; second < 60; second += 1) {
            if (dc.getTextWidthInPixels(_text[second], font) != 2 * _digitWidth) { _canRasterize = false; }
        }
        if (!_canRasterize) { _digits = []; return; }
        for (var digit = 0; digit < 10; digit += 1) {
            if (_digits.size() <= digit) {
                _digits.add(Graphics.createBufferedBitmap({:width => _digitWidth, :height => _height}).get() as Graphics.BufferedBitmap);
            }
            var target = _digits[digit].getDc();
            target.setColor(background, background);
            target.clear();
            target.setColor(foreground, background);
            target.drawText(0, _height / 2, font, digit.toString(),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function draw(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
                  top as Lang.Number, width as Lang.Number, second as Lang.Number) as Void {
        dc.setClip(x - 1, top, width, _height);
        dc.setColor(_background, _background);
        dc.fillRectangle(x - 1, top, width, _height);
        if (_canRasterize) {
            dc.drawBitmap(x, top, _digits[second / 10]);
            dc.drawBitmap(x + _digitWidth, top, _digits[second % 10]);
        } else {
            // Preserve native spacing for a proportional fallback font.
            dc.setColor(_foreground, _background);
            dc.drawText(x, y, _font as Graphics.FontType, _text[second],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.clearClip();
    }
}
