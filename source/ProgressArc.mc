import Toybox.Graphics;
import Toybox.Lang;

module ProgressArc {
    const SWEEP = 72;

    function sweep(progress as Lang.Float or Null) as Lang.Number {
        if (progress == null || progress <= 0.0) { return 0; }
        if (progress >= 1.0) { return SWEEP; }
        // Equal start/end angles draw a full circle, so retain at least 1 degree.
        var degrees = (SWEEP * progress).toNumber();
        return degrees < 1 ? 1 : degrees;
    }

    function draw(dc as Graphics.Dc, start as Lang.Number,
                  direction as Graphics.ArcDirection, progress as Lang.Float or Null) as Void {
        if (FaceOptions.simpleView()) { return; }
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var radius = x - 2;
        var sign = direction == Graphics.ARC_CLOCKWISE ? -1 : 1;
        dc.setPenWidth(4);
        dc.setColor(FaceColors.track(), FaceColors.background());
        dc.drawArc(x, y, radius, direction, start, start + sign * SWEEP);
        var fill = sweep(progress);
        if (fill > 0) {
            dc.setColor(FaceColors.getDisplayColor(), FaceColors.background());
            dc.drawArc(x, y, radius, direction, start, start + sign * fill);
        }
        dc.setPenWidth(1);
    }
}
