import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

(:test)
module SolarTest {
    function epoch(day as Lang.Number, hour as Lang.Number, minute as Lang.Number) as Lang.Number {
        return Gregorian.moment({:year => 2026, :month => 10, :day => day,
            :hour => hour, :minute => minute, :second => 0}).value();
    }

    function events() as Lang.Array<[Lang.Number, Lang.Boolean]> {
        return [[epoch(28, 5, 21), true], [epoch(28, 15, 18), false],
            [epoch(29, 5, 23), true], [epoch(29, 15, 16), false],
            [epoch(30, 5, 25), true], [epoch(30, 15, 14), false]];
    }
}

(:test)
function solarAfterSunsetEndsAtTomorrowsDifferentSunrise(logger as Test.Logger) as Lang.Boolean {
    var interval = SolarTimes.intervalAt(SolarTest.epoch(29, 18, 0), SolarTest.events());
    Test.assert(interval != null);
    Test.assertEqual(interval[0], SolarTest.epoch(29, 15, 16));
    Test.assertEqual(interval[1], SolarTest.epoch(30, 5, 25));
    Test.assertEqual(interval[2], false);
    Test.assert(interval[1] != SolarTest.epoch(29, 5, 23) + 86400);
    return true;
}

(:test)
function solarBeforeSunriseStartsAtYesterdaysDifferentSunset(logger as Test.Logger) as Lang.Boolean {
    var interval = SolarTimes.intervalAt(SolarTest.epoch(29, 3, 0), SolarTest.events());
    Test.assert(interval != null);
    Test.assertEqual(interval[0], SolarTest.epoch(28, 15, 18));
    Test.assertEqual(interval[1], SolarTest.epoch(29, 5, 23));
    Test.assertEqual(interval[2], false);
    return true;
}

(:test)
function solarDayUsesTodaysSunriseAndSunset(logger as Test.Logger) as Lang.Boolean {
    var interval = SolarTimes.intervalAt(SolarTest.epoch(29, 12, 0), SolarTest.events());
    Test.assert(interval != null);
    Test.assertEqual(interval[0], SolarTest.epoch(29, 5, 23));
    Test.assertEqual(interval[1], SolarTest.epoch(29, 15, 16));
    Test.assertEqual(interval[2], true);
    return true;
}

(:test)
function solarTransitionsSelectNewIntervalAtExactEvent(logger as Test.Logger) as Lang.Boolean {
    var events = SolarTest.events();
    var sunrise = SolarTest.epoch(29, 5, 23);
    var sunset = SolarTest.epoch(29, 15, 16);
    var day = SolarTimes.intervalAt(sunrise, events);
    var night = SolarTimes.intervalAt(sunset, events);
    Test.assert(day != null && night != null);
    Test.assertEqual(day[2], true);
    Test.assertEqual(night[2], false);
    Test.assertEqual(SolarTimes.progress(sunrise, day), 0.0);
    Test.assertEqual(SolarTimes.progress(sunset, night), 0.0);
    return true;
}

(:test)
function solarNightContinuesAcrossLocalMidnight(logger as Test.Logger) as Lang.Boolean {
    // Warsaw local midnight at this date is 23:00 UTC.
    var midnight = SolarTest.epoch(29, 23, 0);
    var before = SolarTimes.intervalAt(midnight - 1, SolarTest.events());
    var after = SolarTimes.intervalAt(midnight, SolarTest.events());
    Test.assert(before != null && after != null);
    Test.assertEqual(before[0], after[0]);
    Test.assertEqual(before[1], after[1]);
    var first = SolarTimes.progress(midnight - 1, before);
    var second = SolarTimes.progress(midnight, after);
    Test.assert(first != null && second != null);
    Test.assert(second > first && second - first < 0.0001);
    return true;
}

(:test)
function solarAbsoluteDurationHandlesShortAndLongDstNights(logger as Test.Logger) as Lang.Boolean {
    var spring = Gregorian.moment({:year => 2026, :month => 3, :day => 28, :hour => 17}).value();
    var autumn = Gregorian.moment({:year => 2026, :month => 10, :day => 24, :hour => 16}).value();
    // Synthetic events around a clock change: measure UTC elapsed time, not wall time.
    Test.assertEqual(SolarTimes.progress(spring + 20400, [spring, spring + 40800, false]), 0.5);
    Test.assertEqual(SolarTimes.progress(autumn + 24000, [autumn, autumn + 48000, false]), 0.5);
    return true;
}

(:test)
function solarSelectionHandlesYearRolloverAndUnsortedEvents(logger as Test.Logger) as Lang.Boolean {
    var sunset = Gregorian.moment({:year => 2026, :month => 12, :day => 31, :hour => 15}).value();
    var sunrise = Gregorian.moment({:year => 2027, :month => 1, :day => 1, :hour => 7}).value();
    var interval = SolarTimes.intervalAt(sunset + 3600, [[sunrise, true], [sunset, false]]);
    Test.assert(interval != null);
    Test.assertEqual(interval[0], sunset);
    Test.assertEqual(interval[1], sunrise);
    return true;
}

(:test)
function solarMissingOrPolarEventsDoNotInventAnInterval(logger as Test.Logger) as Lang.Boolean {
    Test.assert(SolarTimes.intervalAt(100, []) == null);
    Test.assert(SolarTimes.intervalAt(100, [[200, true]]) == null);
    Test.assert(SolarTimes.intervalAt(100, [[50, false]]) == null);
    Test.assert(SolarTimes.intervalAt(100, [[50, true], [200, true]]) == null);
    Test.assert(SolarTimes.progress(100, null) == null);
    Test.assert(SolarTimes.progress(100, [100, 100, false]) == null);
    Test.assert(SolarTimes.progress(99, [100, 200, false]) == null);
    Test.assert(SolarTimes.progress(200, [100, 200, false]) == null);
    return true;
}

(:test)
function solarNativeApiReturnsDatedNextDaySunrise(logger as Test.Logger) as Lang.Boolean {
    var warsaw = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    var today = Gregorian.moment({:year => 2026, :month => 10, :day => 29, :hour => 12});
    var tomorrow = new Time.Moment(today.value() + 86400);
    var todayRise = Weather.getSunrise(warsaw, today);
    var tomorrowRise = Weather.getSunrise(warsaw, tomorrow);
    var todaySet = Weather.getSunset(warsaw, today);
    Test.assert(todayRise != null && tomorrowRise != null && todaySet != null);
    Test.assert(tomorrowRise.value() > todaySet.value());
    Test.assert(tomorrowRise.value() != todayRise.value() + 86400);
    var interval = SolarTimes.intervalAt(todaySet.value() + 600, SolarTimes.eventsAround(today, warsaw));
    Test.assert(interval != null);
    Test.assertEqual(interval[0], todaySet.value());
    Test.assertEqual(interval[1], tomorrowRise.value());
    SolarTimes.refresh(new Time.Moment(todaySet.value() + 600), warsaw);
    var current = SolarTimes.current();
    Test.assert(current != null);
    Test.assertEqual(current[1], tomorrowRise.value());
    Test.assertEqual(SolarTimes.eventText(current[0]), "16:16");
    Test.assertEqual(SolarTimes.eventText(current[1]), "06:25");
    Test.assertEqual(SolarTimes.eventLabel(current[0], false), "16:16 -2");
    Test.assertEqual(SolarTimes.eventLabel(current[1], true), "06:25 +2");
    logger.debug("DATED SOLAR: today rise=" + todayRise.value() + " tomorrow rise=" + tomorrowRise.value());
    return true;
}

(:test)
function solarCalendarAnchorHandlesLocalDateAndDst(logger as Test.Logger) as Lang.Boolean {
    var warsaw = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    var beforeMidnightUtc = Gregorian.moment({:year => 2026, :month => 3, :day => 28, :hour => 23, :minute => 30});
    var anchor = Gregorian.utcInfo(SolarTimes.dateAnchor(beforeMidnightUtc, warsaw), Time.FORMAT_SHORT);
    Test.assertEqual(anchor.year, 2026);
    Test.assertEqual(anchor.month, 3);
    Test.assertEqual(anchor.day, 29);
    Test.assertEqual(anchor.hour, 12);
    return true;
}

(:test)
function solarPositionValidatesPersistedCoordinates(logger as Test.Logger) as Lang.Boolean {
    Test.assert(SolarPosition.validCoordinates([52.2297, 21.0122]));
    Test.assert(SolarPosition.validCoordinates([0, 0]));
    Test.assert(!SolarPosition.validCoordinates(null));
    Test.assert(!SolarPosition.validCoordinates([91, 21]));
    Test.assert(!SolarPosition.validCoordinates([52, -181]));
    Test.assert(!SolarPosition.validCoordinates(["52", "21"]));
    Test.assert(!SolarPosition.validCoordinates([52]));
    return true;
}

(:test)
function solarNoLocationDoesNotReuseAnUndatedTime(logger as Test.Logger) as Lang.Boolean {
    SolarTimes.refresh(Time.now(), null);
    Test.assert(SolarTimes.current() == null);
    Test.assertEqual(SolarTimes.eventText(null), "--:--");
    return true;
}

(:test)
function solarChangesCompareSameEventOnPreviousCalendarDay(logger as Test.Logger) as Lang.Boolean {
    var warsaw = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    var events = SolarTest.events();
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 5, 23), true, events, warsaw), 2);
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 16), false, events, warsaw), -2);
    // After sunset the right endpoint is tomorrow's sunrise, compared with today's.
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(30, 5, 25), true, events, warsaw), 2);
    // Never substitute a sunrise for a missing sunset or skip a missing calendar day.
    Test.assert(SolarTimes.changeMinutes(SolarTest.epoch(28, 15, 18), false, events, warsaw) == null);
    Test.assert(SolarTimes.changeMinutes(SolarTest.epoch(30, 15, 14), false,
        [[SolarTest.epoch(28, 15, 18), false]], warsaw) == null);
    return true;
}

(:test)
function solarChangesFollowDisplayedMinutesAndHandleDst(logger as Test.Logger) as Lang.Boolean {
    var warsaw = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    var previous = Gregorian.moment({:year => 2026, :month => 10, :day => 24, :hour => 15, :minute => 20}).value();
    var current = SolarTest.epoch(25, 15, 18);
    // 17:20 CEST -> 16:18 CET is 62 minutes earlier on the watch's clock.
    Test.assertEqual(SolarTimes.changeMinutes(current, false, [[previous, false]], warsaw), -62);
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 18) + 59, false,
        [[SolarTest.epoch(28, 15, 18) + 1, false]], warsaw), 0);
    return true;
}
