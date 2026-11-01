import Toybox.Position;

// Passive device location only. Never start GPS or persist coordinates.
module SolarPosition {
    var _last as Position.Location or Null = null;

    function resolve() as Position.Location or Null {
        return retain(Position.getInfo().position);
    }

    function retain(position as Position.Location or Null) as Position.Location or Null {
        if (position != null) { _last = position; }
        return _last;
    }
}
