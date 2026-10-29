import Toybox.Graphics;

module FaceFonts {
    var _text as Graphics.FontType or Null = null;

    function text() as Graphics.FontType {
        if (_text == null) {
            // FR955 FONT_GLANCE is 24 px high; retain regular weight at +1 px.
            _text = Graphics.getVectorFont({:face => "RobotoCondensedRegular", :size => 25});
            if (_text == null) { _text = Graphics.FONT_GLANCE; }
        }
        return _text as Graphics.FontType;
    }
}
