import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

module ProgressArc {
    const SWEEP = 72;
    const STROKE_WIDTH = 3;
    const EDGE_INSET = 6;
    // Keep the same radial thickness and a two-pixel gap for all goal arcs.
    const ACTIVE_MINUTES_INSET = STROKE_WIDTH + 2;
    // A small rectangle sits on the arc at the historical value.
    // The underlying track and fill retain current data.
    function drawHistoryMarker(dc as Graphics.Dc, progress as Lang.Float or Null, inset as Lang.Number) as Void {
        if (progress == null || FaceOptions.simpleView()) { return; }
        var angle = (234 + sweep(progress)) * Math.PI / 180.0;
        var ux = Math.cos(angle);
        var uy = -Math.sin(angle);
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var radius = x - EDGE_INSET - inset;
        var cx = x + radius * ux;
        var cy = y + radius * uy;
        // Cover the complete stroke, including its anti-aliased edges.
        var halfHeight = (STROKE_WIDTH + 2) / 2.0;
        var halfWidth = 1.5;
        dc.setAntiAlias(true);
        dc.setColor(FaceColors.background(), FaceColors.background());
        dc.fillPolygon([
            [Math.round(cx - halfHeight * ux - halfWidth * uy).toNumber(),
                Math.round(cy - halfHeight * uy + halfWidth * ux).toNumber()],
            [Math.round(cx + halfHeight * ux - halfWidth * uy).toNumber(),
                Math.round(cy + halfHeight * uy + halfWidth * ux).toNumber()],
            [Math.round(cx + halfHeight * ux + halfWidth * uy).toNumber(),
                Math.round(cy + halfHeight * uy - halfWidth * ux).toNumber()],
            [Math.round(cx - halfHeight * ux + halfWidth * uy).toNumber(),
                Math.round(cy - halfHeight * uy - halfWidth * ux).toNumber()]
        ]);
        dc.setAntiAlias(false);
    }

    function goalProgress(value as Lang.Number or Null, goal as Lang.Number or Null) as Lang.Float or Null {
        if (value == null || value < 0 || goal == null || goal <= 0) { return null; }
        return value.toFloat() / goal;
    }

    function sweep(progress as Lang.Float or Null) as Lang.Number {
        if (progress == null || progress <= 0.0) { return 0; }
        if (progress >= 1.0) { return SWEEP; }
        // Equal start/end angles draw a full circle, so retain at least 1 degree.
        var degrees = (SWEEP * progress).toNumber();
        return degrees < 1 ? 1 : degrees;
    }

    function draw(dc as Graphics.Dc, start as Lang.Number,
                  direction as Graphics.ArcDirection, progress as Lang.Float or Null,
                  inset as Lang.Number, isGoal as Lang.Boolean) as Void {
        if (FaceOptions.simpleView()) { return; }
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var radius = x - EDGE_INSET - inset;
        var sign = direction == Graphics.ARC_CLOCKWISE ? -1 : 1;
        // The scene bitmap uses the full device palette, allowing native AA.
        dc.setAntiAlias(true);
        dc.setPenWidth(STROKE_WIDTH);
        dc.setColor(FaceColors.track(), FaceColors.background());
        // Normalize both halves to the same native drawing direction.
        dc.drawArc(x, y, radius, Graphics.ARC_CLOCKWISE,
            sign > 0 ? start + SWEEP : start, sign > 0 ? start : start - SWEEP);
        var fill = sweep(progress);
        if (fill > 0) {
            var color = isGoal && progress != null && progress >= 1.0
                ? FaceColors.completedGoal() : FaceColors.getDisplayColor();
            dc.setColor(color, FaceColors.background());
            dc.drawArc(x, y, radius, Graphics.ARC_CLOCKWISE,
                sign > 0 ? start + fill : start, sign > 0 ? start : start - fill);
        }
        dc.setPenWidth(1);
        dc.setAntiAlias(false);
    }
}
