import Toybox.Graphics;
import Toybox.Lang;

// Rasterize ten digits once per theme, then draw over the restored full scene.
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
        var fontChanged = _font != font;
        _font = font;
        _background = background;
        _foreground = foreground;
        // Colours change the pixels, but not the font's dimensions or spacing.
        if (fontChanged) {
            _height = dc.getFontHeight(font) + 4;
            _digitWidth = dc.getTextWidthInPixels("0", font);
            _canRasterize = true;
            for (var digit = 0; digit < 10; digit += 1) {
                if (dc.getTextWidthInPixels(digit.toString(), font) != _digitWidth) { _canRasterize = false; }
            }
            for (var second = 0; second < 60; second += 1) {
                if (dc.getTextWidthInPixels(second.format("%02d"), font) != 2 * _digitWidth) { _canRasterize = false; }
            }
        }
        if (!_canRasterize) {
            if (_text.size() == 0) {
                for (var second = 0; second < 60; second += 1) { _text.add(second.format("%02d")); }
            }
            _digits = [];
            return;
        }
        if (_text.size() != 0) { _text = []; }
        for (var digit = 0; digit < 10; digit += 1) {
            if (_digits.size() <= digit) {
                _digits.add(Graphics.createBufferedBitmap({:width => _digitWidth, :height => _height}).get() as Graphics.BufferedBitmap);
            } else if (_digits[digit].getWidth() != _digitWidth || _digits[digit].getHeight() != _height) {
                _digits[digit] = Graphics.createBufferedBitmap({:width => _digitWidth, :height => _height}).get() as Graphics.BufferedBitmap;
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
        // onUpdate has already restored every pixel from the scene bitmap.
        // The opaque tiles need no extra erase or clipping operations.
        if (_canRasterize) {
            dc.drawBitmap(x, top, _digits[second / 10]);
            dc.drawBitmap(x + _digitWidth, top, _digits[second % 10]);
        } else {
            // Preserve native spacing for a proportional fallback font.
            dc.setClip(x - 1, top, width, _height);
            dc.setColor(_foreground, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, _font as Graphics.FontType, _text[second],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.clearClip();
        }
    }
}
