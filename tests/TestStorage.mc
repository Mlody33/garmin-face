import Toybox.Application.Storage;
import Toybox.Lang;

// The whole module is excluded from normal builds by the Connect IQ compiler.
(:test)
module TestStorage {
    function restore(keys as Lang.Array<Lang.String>, previous as Lang.Array) as Void {
        for (var i = 0; i < keys.size(); i += 1) {
            if (previous[i] == null) { Storage.deleteValue(keys[i]); }
            else { Storage.setValue(keys[i], previous[i]); }
        }
        MetricFields.load();
        FaceColors.load();
    }
}
