import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// All lower-field icons are ready-made Garmin Support assets.
module DataIcons {
    var _icons as Lang.Dictionary<Lang.String, WatchUi.BitmapResource> = {};

    function drawMetricIcon(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
                            metric as Lang.String) as Void {
        var icon = _icons[metric];
        if (icon == null) {
            var resource = resourceFor(metric);
            if (resource == null) { return; }
            icon = WatchUi.loadResource(resource) as WatchUi.BitmapResource;
            _icons[metric] = icon;
        }
        dc.drawBitmap(x - icon.getWidth() / 2, y - icon.getHeight() / 2, icon);
    }

    function resourceFor(metric as Lang.String) as Lang.ResourceId or Null {
        switch (metric) {
            case MetricFields.STEPS: return Rez.Drawables.StepsIcon;
            case MetricFields.CALORIES: return Rez.Drawables.CaloriesIcon;
            case MetricFields.STRESS: return Rez.Drawables.StressIcon;
            case MetricFields.HEART_RATE: return Rez.Drawables.HeartRateIcon;
            case MetricFields.BATTERY: return Rez.Drawables.BatteryIcon;
            case MetricFields.DISTANCE: return Rez.Drawables.DistanceIcon;
            case MetricFields.FLOORS: return Rez.Drawables.FloorsIcon;
        }
        return null;
    }

    function drawPhoneDisconnected(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number) as Void {
        // Bluetooth rune with a separated diagonal strike for a lost phone link.
        dc.drawLine(x, y - 8, x, y + 8);
        dc.drawLine(x, y - 8, x + 6, y - 3);
        dc.drawLine(x + 6, y - 3, x - 5, y + 5);
        dc.drawLine(x - 5, y - 5, x + 6, y + 3);
        dc.drawLine(x + 6, y + 3, x, y + 8);
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawLine(x - 7, y - 8, x + 7, y + 8);
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine(x - 7, y - 8, x + 7, y + 8);
    }

    function drawAlarm(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number) as Void {
        dc.drawCircle(x, y, 6);
        dc.drawLine(x, y - 4, x, y);
        dc.drawLine(x, y, x + 3, y + 2);
        dc.drawLine(x - 8, y - 5, x - 4, y - 9);
        dc.drawLine(x - 7, y - 4, x - 3, y - 8);
        dc.drawLine(x + 4, y - 9, x + 8, y - 5);
        dc.drawLine(x + 3, y - 8, x + 7, y - 4);
        dc.drawLine(x - 4, y + 5, x - 6, y + 8);
        dc.drawLine(x + 4, y + 5, x + 6, y + 8);
    }

}
