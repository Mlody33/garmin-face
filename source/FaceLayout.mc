import Toybox.Lang;

// Geometry for the only supported device: round FR955, 260 x 260.
module FaceLayout {
    const SUN_Y = 45;
    const CENTER_X = 130;
    const CENTER_Y = 130;
    const DATA_ROW_GAP = 52;
    const DATE_Y = CENTER_Y - DATA_ROW_GAP;
    const FIELD_COUNT = 3;
    const FIELD_SPACING = 70;
    const FIELD_VALUE_Y = CENTER_Y + DATA_ROW_GAP;
    const FIELD_ICON_Y = 210;
    const FIELD_TOUCH_TOP = 166;
    const FIELD_TOUCH_BOTTOM = 228;

    function fieldX(index as Lang.Number, visibleCount as Lang.Number) as Lang.Number {
        return CENTER_X + (2 * index - visibleCount + 1) * FIELD_SPACING / 2;
    }

}
