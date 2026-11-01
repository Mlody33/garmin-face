import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.WatchUi;

class GarminFaceApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        // Remove coordinates saved by legacy versions; the current cache is RAM only.
        Storage.deleteValue("solarPosition");
        MetricFields.load();
        FaceColors.load();
        FaceOptions.load();
        return [new GarminFaceView(), new GarminFaceDelegate()];
    }

    function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
        MetricFields.load();
        FaceColors.load();
        FaceOptions.load();
        return [new FaceSettingsMenu(), new FaceSettingsDelegate()];
    }
}
