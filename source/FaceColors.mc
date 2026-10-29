import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module FaceColors {
    const KEY = "accentColor";
    var _color as Lang.Number = Graphics.COLOR_WHITE;
    var _displayColor as Lang.Number = Graphics.COLOR_WHITE;

    function choices() as Lang.Array<Lang.Number> {
        // Keep stable choice IDs so saved accents survive palette changes.
        return [Graphics.COLOR_WHITE, Graphics.COLOR_LT_GRAY, Graphics.COLOR_RED,
            Graphics.COLOR_ORANGE, Graphics.COLOR_YELLOW, Graphics.COLOR_GREEN,
            Graphics.COLOR_BLUE, Graphics.COLOR_PURPLE, Graphics.COLOR_PINK];
    }

    function isValid(value as Lang.Object or Null) as Lang.Boolean {
        if (!(value instanceof Lang.Number)) { return false; }
        var options = choices();
        for (var i = 0; i < options.size(); i += 1) {
            if (options[i] == value) { return true; }
        }
        return false;
    }

    function load() as Void {
        var stored = Storage.getValue(KEY);
        if (stored == null) {
            // Reuse the former time color when upgrading from separate colors.
            stored = Storage.getValue("clockColor");
        }
        _color = isValid(stored) ? stored as Lang.Number : Graphics.COLOR_WHITE;
        _displayColor = displayColor(_color);
    }

    function get() as Lang.Number {
        return _color;
    }

    function getDisplayColor() as Lang.Number {
        return _displayColor;
    }

    function displayColor(color as Lang.Number) as Lang.Number {
        // Softer shades using the MIP palette's 0x00/55/AA/FF channel levels.
        // White and gray keep their original neutral shades.
        switch (color) {
            case Graphics.COLOR_RED: return 0xFFAAAA;
            case Graphics.COLOR_ORANGE: return 0xFFAA55;
            case Graphics.COLOR_YELLOW: return 0xFFFFAA;
            case Graphics.COLOR_GREEN: return 0xAAFFAA;
            case Graphics.COLOR_BLUE: return 0x55AAFF;
            case Graphics.COLOR_PURPLE: return 0xAAAAFF;
            case Graphics.COLOR_PINK: return 0xFFAAFF;
        }
        return color;
    }

    function save(color as Lang.Number) as Lang.Boolean {
        if (!isValid(color)) { return false; }
        Storage.setValue(KEY, color);
        _color = color;
        _displayColor = displayColor(color);
        return true;
    }

    function label(color as Lang.Number) as Lang.String {
        var options = choices();
        var labels = [Rez.Strings.WhiteColor, Rez.Strings.GrayColor, Rez.Strings.RedColor,
            Rez.Strings.OrangeColor, Rez.Strings.YellowColor, Rez.Strings.GreenColor,
            Rez.Strings.BlueColor, Rez.Strings.PurpleColor, Rez.Strings.PinkColor];
        for (var i = 0; i < options.size(); i += 1) {
            if (options[i] == color) {
                return WatchUi.loadResource(labels[i]) as Lang.String;
            }
        }
        return WatchUi.loadResource(Rez.Strings.WhiteColor) as Lang.String;
    }
}
