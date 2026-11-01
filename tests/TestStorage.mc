import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

// The whole module is excluded from normal builds by the Connect IQ compiler.
(:test)
module TestStorage {
    // Garmin's Test.assertEqual does not accept null Storage values.
    function assertEqual(actual as Lang.Object or Null, expected as Lang.Object or Null) as Void {
        if (actual == null || expected == null) {
            Test.assert(actual == null && expected == null);
        } else {
            Test.assertEqual(actual, expected);
        }
    }

    function restore(keys as Lang.Array<Lang.String>, previous as Lang.Array) as Void {
        for (var i = 0; i < keys.size(); i += 1) {
            if (previous[i] == null) { Storage.deleteValue(keys[i]); }
            else { Storage.setValue(keys[i], previous[i]); }
        }
        MetricFields.load();
        FaceColors.load();
        FaceOptions.load();
    }
}
