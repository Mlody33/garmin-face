import Toybox.Application.Storage;
import Toybox.Lang;

module FaceOptions {
    const KEY = "simpleView";
    const LIGHT_BACKGROUND_KEY = "lightBackground";
    var _simpleView as Lang.Boolean = false;
    var _lightBackground as Lang.Boolean = false;

    function load() as Void {
        var stored = Storage.getValue(KEY);
        _simpleView = stored instanceof Lang.Boolean && (stored as Lang.Boolean);
        stored = Storage.getValue(LIGHT_BACKGROUND_KEY);
        _lightBackground = stored instanceof Lang.Boolean && (stored as Lang.Boolean);
    }

    function simpleView() as Lang.Boolean {
        return _simpleView;
    }

    function saveSimpleView(enabled as Lang.Boolean) as Void {
        Storage.setValue(KEY, enabled);
        _simpleView = enabled;
    }

    function lightBackground() as Lang.Boolean {
        return _lightBackground;
    }

    function saveLightBackground(enabled as Lang.Boolean) as Void {
        Storage.setValue(LIGHT_BACKGROUND_KEY, enabled);
        _lightBackground = enabled;
    }
}
