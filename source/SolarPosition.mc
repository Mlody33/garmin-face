import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;

// Read existing position data only. Never enable GPS or location events.
module SolarPosition {
    const KEY = "solarPosition";
    var _loaded as Lang.Boolean = false;
    var _cached as Position.Location or Null = null;

    function validCoordinates(value as Lang.Object or Null) as Lang.Boolean {
        if (!(value instanceof Lang.Array)) { return false; }
        var coordinates = value as Lang.Array;
        if (coordinates.size() != 2) { return false; }
        for (var i = 0; i < 2; i += 1) {
            var number = coordinates[i];
            if (!(number instanceof Lang.Number || number instanceof Lang.Float || number instanceof Lang.Double)) { return false; }
        }
        return coordinates[0] >= -90 && coordinates[0] <= 90
            && coordinates[1] >= -180 && coordinates[1] <= 180;
    }

    function invalidate() as Void { _loaded = false; _cached = null; }

    function resolve(weatherLocation as Position.Location or Null) as Position.Location or Null {
        if (!_loaded) {
            _loaded = true;
            var stored = Storage.getValue(KEY);
            if (validCoordinates(stored)) {
                var coordinates = stored as Lang.Array;
                _cached = new Position.Location({:latitude => coordinates[0], :longitude => coordinates[1], :format => :degrees});
            }
        }
        var current = Position.getInfo().position;
        if (current == null) { current = weatherLocation; }
        if (current != null) {
            var coordinates = current.toDegrees();
            if (validCoordinates(coordinates)) {
                var previous = _cached == null ? null : (_cached as Position.Location).toDegrees();
                if (previous == null || Math.round(coordinates[0] * 1000) != Math.round(previous[0] * 1000)
                    || Math.round(coordinates[1] * 1000) != Math.round(previous[1] * 1000)) {
                    Storage.setValue(KEY, coordinates);
                }
                _cached = current;
            }
        }
        return _cached;
    }
}
