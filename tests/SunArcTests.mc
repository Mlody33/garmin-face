import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
function sunNativeFieldsAreOptional(logger as Test.Logger) as Lang.Boolean {
    var sunrise = SunArc.readEvent(new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE));
    var sunset = SunArc.readEvent(new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET));
    var clock = System.getClockTime();
    var progress = SunArc.progress(clock.hour * 3600 + clock.min * 60 + clock.sec, sunrise, sunset);
    if (progress != null) { Test.assert(progress >= 0.0 && progress < 1.0); }
    return true;
}

(:test)
function sunBeforeSunrise(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(SunArc.progress(0, 21600, 64800), 0.5);
    return true;
}

(:test)
function sunAtSunriseStartsDaylight(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(SunArc.progress(21600, 21600, 64800), 0.0);
    return true;
}

(:test)
function sunDaylightProgress(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(SunArc.progress(43200, 21600, 64800), 0.5);
    return true;
}

(:test)
function sunAtSunsetStartsNight(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(SunArc.progress(64800, 21600, 64800), 0.0);
    return true;
}

(:test)
function sunNightContinuesAcrossMidnight(logger as Test.Logger) as Lang.Boolean {
    var before = SunArc.progress(86399, 21600, 64800);
    var after = SunArc.progress(0, 21600, 64800);
    if (before == null || after == null) { return false; }
    Test.assert(after > before && after - before < 0.0001);
    return true;
}

(:test)
function sunMissingBoundaryDoesNotInventProgress(logger as Test.Logger) as Lang.Boolean {
    Test.assert(SunArc.progress(43200, null, 64800) == null);
    Test.assert(SunArc.progress(43200, 21600, null) == null);
    return true;
}

(:test)
function sunNoEventsShowsUnavailable(logger as Test.Logger) as Lang.Boolean {
    Test.assert(SunArc.progress(43200, null, null) == null);
    return true;
}

(:test)
function sunDaylightAcrossMidnight(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(SunArc.progress(0, 72000, 14400), 0.5);
    return true;
}

(:test)
function sunEqualEventsDoesNotDivideByZero(logger as Test.Logger) as Lang.Boolean {
    Test.assert(SunArc.progress(43200, 21600, 21600) == null);
    return true;
}

(:test)
function sunEventTextUses24HourTimeAndMissingPlaceholder(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(SunArc.eventText(null), "--:--");
    Test.assertEqual(SunArc.eventText(0), "00:00");
    Test.assertEqual(SunArc.eventText(23009), "06:23");
    Test.assertEqual(SunArc.eventText(58562), "16:16");
    Test.assertEqual(SunArc.eventText(86399), "23:59");
    return true;
}

(:test)
function sunIntervalLabelsFollowDayAndNightIncludingMidnight(logger as Test.Logger) as Lang.Boolean {
    var sunrise = 21600;
    var sunset = 64800;
    var times = [0, 18000, 21599, 21600, 43200, 64799, 64800, 75600, 86399];
    var expectedDaylight = [false, false, false, true, true, true, false, false, false];
    for (var i = 0; i < times.size(); i += 1) {
        var daylight = SunArc.isDaylight(times[i], sunrise, sunset);
        Test.assertEqual(daylight, expectedDaylight[i]);
        Test.assertEqual(SunArc.intervalStart(daylight, sunrise, sunset), expectedDaylight[i] ? sunrise : sunset);
        Test.assertEqual(SunArc.intervalEnd(daylight, sunrise, sunset), expectedDaylight[i] ? sunset : sunrise);
    }
    Test.assertEqual(SunArc.eventText(SunArc.intervalStart(false, sunrise, sunset)), "18:00");
    Test.assertEqual(SunArc.eventText(SunArc.intervalEnd(false, sunrise, sunset)), "06:00");
    Test.assertEqual(SunArc.progress(75600, sunrise, sunset), 0.25);
    Test.assertEqual(SunArc.progress(18000, sunrise, sunset), 11.0 / 12.0);
    return true;
}

(:test)
function sunIntervalHandlesDaylightAcrossMidnightAndUnknownEvents(logger as Test.Logger) as Lang.Boolean {
    Test.assertEqual(SunArc.isDaylight(0, 72000, 14400), true);
    Test.assertEqual(SunArc.isDaylight(14400, 72000, 14400), false);
    Test.assertEqual(SunArc.intervalStart(false, 72000, 14400), 14400);
    Test.assertEqual(SunArc.intervalEnd(false, 72000, 14400), 72000);
    Test.assert(SunArc.isDaylight(43200, null, 64800) == null);
    Test.assert(SunArc.isDaylight(43200, 21600, null) == null);
    Test.assert(SunArc.isDaylight(43200, 21600, 21600) == null);
    Test.assert(SunArc.intervalStart(null, null, null) == null);
    Test.assert(SunArc.intervalEnd(null, null, null) == null);
    return true;
}
