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

(:test)
function activityGoalsHandleMissingDataAndCapCompletedWeeklyProgress(logger as Test.Logger) as Lang.Boolean {
    Test.assert(ProgressArc.goalProgress(null, 150) == null);
    Test.assert(ProgressArc.goalProgress(75, null) == null);
    Test.assert(ProgressArc.goalProgress(75, 0) == null);
    Test.assert(ProgressArc.goalProgress(75, -150) == null);
    Test.assert(ProgressArc.goalProgress(-1, 150) == null);
    Test.assertEqual(ProgressArc.sweep(ProgressArc.goalProgress(0, 150)), 0);
    Test.assertEqual(ProgressArc.sweep(ProgressArc.goalProgress(75, 150)), 36);
    Test.assertEqual(ProgressArc.sweep(ProgressArc.goalProgress(150, 150)), 72);
    Test.assertEqual(ProgressArc.sweep(ProgressArc.goalProgress(300, 150)), 72);
    // Respect the user's configured weekly goal, not a hardcoded 150 minutes.
    Test.assertEqual(ProgressArc.sweep(ProgressArc.goalProgress(75, 300)), 18);
    return true;
}
