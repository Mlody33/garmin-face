import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time.Gregorian;

(:test)
function historyMarkersRemainIndependentWhenOnlyOneMetricIsAvailable(logger as Test.Logger) as Lang.Boolean {
    var rows = [[98, 2000, null]] as Lang.Array<[Lang.Number, Lang.Number or Null, Lang.Number or Null]>;
    var result = GoalHistory.previous(99, Gregorian.DAY_TUESDAY, Gregorian.DAY_MONDAY, rows);
    Test.assertEqual(result[0], 2000);
    Test.assert(result[1] == null);
    rows = [];
    for (var day = 91; day <= 97; day += 1) { rows.add([day, null, 20]); }
    result = GoalHistory.previous(99, Gregorian.DAY_TUESDAY, Gregorian.DAY_MONDAY, rows);
    Test.assert(result[0] == null);
    Test.assertEqual(result[1], 140);
    return true;
}

(:test)
function historicalGoalsRequireCalendarWeekAndKeepZeroDifferentFromMissing(logger as Test.Logger) as Lang.Boolean {
    // Tuesday: yesterday belongs to this week, previous week is days 91..97.
    var rows = [] as Lang.Array<[Lang.Number, Lang.Number or Null, Lang.Number or Null]>;
    for (var day = 91; day <= 97; day += 1) { rows.add([day, 4000, day - 91]); }
    rows.add([98, 8000, 900]);
    var result = GoalHistory.previous(99, Gregorian.DAY_TUESDAY, Gregorian.DAY_MONDAY, rows);
    Test.assertEqual(result[0], 8000);
    Test.assertEqual(result[1], 21); // Excludes this week's 900 minutes.
    rows.remove(rows[0]);
    Test.assert(GoalHistory.previous(99, Gregorian.DAY_TUESDAY, Gregorian.DAY_MONDAY, rows)[1] == null);
    rows.add([91, null, 0]);
    Test.assertEqual(GoalHistory.previous(99, Gregorian.DAY_TUESDAY, Gregorian.DAY_MONDAY, rows)[1], 21);
    rows[0][2] = null;
    Test.assert(GoalHistory.previous(99, Gregorian.DAY_TUESDAY, Gregorian.DAY_MONDAY, rows)[1] == null);
    Test.assert(GoalHistory.previous(100, Gregorian.DAY_WEDNESDAY, Gregorian.DAY_MONDAY, rows)[0] == null);
    return true;
}

(:test)
function historicalGoalsRespectWeekStartAndDstCalendarDays(logger as Test.Logger) as Lang.Boolean {
    var rows = [] as Lang.Array<[Lang.Number, Lang.Number or Null, Lang.Number or Null]>;
    for (var day = 91; day <= 97; day += 1) { rows.add([day, 0, 10]); }
    Test.assertEqual(GoalHistory.previous(98, Gregorian.DAY_MONDAY, Gregorian.DAY_MONDAY, rows)[1], 70);
    // Sunday starts a new week only when the watch is configured accordingly.
    Test.assertEqual(GoalHistory.previous(98, Gregorian.DAY_SUNDAY, Gregorian.DAY_SUNDAY, rows)[1], 70);
    Test.assert(GoalHistory.previous(98, Gregorian.DAY_SUNDAY, Gregorian.DAY_MONDAY, rows)[1] == null);
    var before = Gregorian.moment({:year => 2026, :month => 10, :day => 24, :hour => 12});
    var after = Gregorian.moment({:year => 2026, :month => 10, :day => 26, :hour => 12});
    Test.assertEqual(GoalHistory.calendarDay(after) - GoalHistory.calendarDay(before), 2);
    return true;
}

(:test)
function historicalGoalMergeKeepsKnownValuesAndAcceptsCorrections(logger as Test.Logger) as Lang.Boolean {
    var saved = GoalHistory._days;
    try {
        GoalHistory._days = [];
        Test.assert(GoalHistory.merge(100, 5000, 20));
        Test.assert(!GoalHistory.merge(100, null, null));
        Test.assert(!GoalHistory.merge(100, -1, -1));
        Test.assert(GoalHistory.merge(100, 6000, 30));
        Test.assertEqual(GoalHistory._days.size(), 1);
        Test.assertEqual(GoalHistory._days[0][1], 6000);
        Test.assertEqual(GoalHistory._days[0][2], 30);
    } catch (ex) { GoalHistory._days = saved; throw ex; }
    GoalHistory._days = saved;
    return true;
}
