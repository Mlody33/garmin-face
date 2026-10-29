import Toybox.Graphics;

module FaceFonts {
    var _text as Graphics.FontType or Null = null;
    var _seconds as Graphics.FontType or Null = null;

    function text() as Graphics.FontType {
        if (_text == null) {
            _text = Graphics.getVectorFont({:face => "RobotoCondensedBold", :size => 26});
            if (_text == null) { _text = Graphics.FONT_GLANCE; }
        }
        return _text as Graphics.FontType;
    }

    function seconds() as Graphics.FontType {
        if (_seconds == null) {
            _seconds = Graphics.getVectorFont({:face => "RobotoCondensedRegular", :size => 25});
            if (_seconds == null) { _seconds = Graphics.FONT_GLANCE; }
        }
        return _seconds as Graphics.FontType;
    }
}
