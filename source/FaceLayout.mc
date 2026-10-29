import Toybox.Lang;

// Geometry for the only supported device: round FR955, 260 x 260.
module FaceLayout {
    const STATUS_Y = 23;
    const SUN_Y = 50;
    const DATE_Y = 81;
    const FIELD_COUNT = 3;
    const FIELD_FIRST_X = 60;
    const FIELD_SPACING = 70;
    const FIELD_ICON_Y = 182;
    const FIELD_VALUE_Y = 210;
    const FIELD_TOUCH_TOP = 166;
    const FIELD_TOUCH_BOTTOM = 228;

    function fieldX(slot as Lang.Number) as Lang.Number {
        return FIELD_FIRST_X + slot * FIELD_SPACING;
    }
}
