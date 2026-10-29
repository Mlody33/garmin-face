import Toybox.Lang;
import Toybox.Test;

(:test)
function arcProgressIsClampedAndNeverTurnsTinyFillIntoFullCircle(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(ProgressArc.sweep(null), 0);
    Test.assertEqual(ProgressArc.sweep(-1.0), 0);
    Test.assertEqual(ProgressArc.sweep(0.0), 0);
    Test.assertEqual(ProgressArc.sweep(0.00001), 1);
    Test.assertEqual(ProgressArc.sweep(0.5), 36);
    Test.assertEqual(ProgressArc.sweep(1.0), 72);
    Test.assertEqual(ProgressArc.sweep(1.5), 72);
    return true;
}
