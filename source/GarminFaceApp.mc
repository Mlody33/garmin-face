import Toybox.Application;
import Toybox.WatchUi;

class GarminFaceApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        MetricFields.load();
        FaceColors.load();
        return [new GarminFaceView(), new GarminFaceDelegate()];
    }

    function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
        MetricFields.load();
        FaceColors.load();
        return [new FaceSettingsMenu(), new FaceSettingsDelegate()];
    }
}
