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
    var previousSet = Weather.getSunset(warsaw, new Time.Moment(today.value() - 86400));
    Test.assert(todayRise != null && tomorrowRise != null && todaySet != null);
    Test.assert(previousSet != null);
    var sunsetChangeSeconds = todaySet.value() - previousSet.value() - 86400;
    Test.assert(sunsetChangeSeconds > -120 && sunsetChangeSeconds < -60);
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
    logger.debug("DATED SOLAR: today rise=" + todayRise.value() + " tomorrow rise=" + tomorrowRise.value());
    logger.debug("SUNSET signed seconds change=" + sunsetChangeSeconds);
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
function solarChangesCompareRoundedTimesAndHandleDst(logger as Test.Logger) as Lang.Boolean {
    var warsaw = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    var previous = Gregorian.moment({:year => 2026, :month => 10, :day => 24, :hour => 15, :minute => 20}).value();
    var current = SolarTest.epoch(25, 15, 18);
    // 17:20 CEST -> 16:18 CET is 62 minutes earlier on the watch's clock.
    Test.assertEqual(SolarTimes.changeMinutes(current, false, [[previous, false]], warsaw), -62);
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 18) + 59, false,
        [[SolarTest.epoch(28, 15, 18) + 1, false]], warsaw), 1);
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 18) + 1, false,
        [[SolarTest.epoch(28, 15, 18) + 59, false]], warsaw), -1);
    return true;
}

(:test)
function solarLabelsRoundNearestAcrossMidnightWithoutChangingProgress(logger as Test.Logger) as Lang.Boolean {
    var warsaw = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    SolarTimes.refresh(new Time.Moment(SolarTest.epoch(30, 12, 0)), warsaw);
    var interval = SolarTimes.current();
    Test.assert(interval != null);
    var start = interval[0];
    var end = interval[1];
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 5, 25) + 58), "06:26");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 15, 18) + 59), "16:19");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 5, 27) + 86400 + 40), "06:28");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 15, 17) + 86400 + 11), "16:17");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 5, 28)), "06:28");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 5, 28) + 1), "06:28");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 5, 28) + 29), "06:28");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 5, 28) + 30), "06:29");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 5, 28) + 31), "06:29");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 5, 59) + 31), "07:00");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 22, 59) + 1), "23:59");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 22, 59) + 30), "00:00");
    Test.assertEqual(SolarTimes.eventText(SolarTest.epoch(31, 22, 59) + 31), "00:00");
    Test.assertEqual(SolarTimes.current()[0], start);
    Test.assertEqual(SolarTimes.current()[1], end);
    return true;
}

(:test)
function solarChangesUseBothNearestMinuteEventTimes(logger as Test.Logger) as Lang.Boolean {
    var warsaw = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    var previousRise = SolarTest.epoch(31, 5, 25) + 58;
    var currentRise = SolarTest.epoch(31, 5, 27) + 86400 + 40;
    var previousSet = SolarTest.epoch(31, 15, 18) + 59;
    var currentSet = SolarTest.epoch(31, 15, 17) + 86400 + 11;
    var events = [[previousRise, true], [previousSet, false], [currentRise, true], [currentSet, false]];
    Test.assertEqual(SolarTimes.changeMinutes(currentRise, true, events, warsaw), 2);
    Test.assertEqual(SolarTimes.changeMinutes(currentSet, false, events, warsaw), -2);
    // Round both displayed clock times before subtracting them.
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 19) + 7, false,
        [[SolarTest.epoch(28, 15, 20) + 55, false]], warsaw), -2);
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 18) + 29, false,
        [[SolarTest.epoch(28, 15, 18), false]], warsaw), 0);
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 18), false,
        [[SolarTest.epoch(28, 15, 18) + 30, false]], warsaw), -1);
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 18) + 30, false,
        [[SolarTest.epoch(28, 15, 18) + 31, false]], warsaw), 0);
    Test.assertEqual(SolarTimes.changeMinutes(SolarTest.epoch(29, 15, 18) + 31, false,
        [[SolarTest.epoch(28, 15, 18) + 30, false]], warsaw), 0);
    // A location shift can move yesterday across :00; respect both displayed times.
    events = [[previousRise + 5, true], [previousSet + 5, false],
        [currentRise + 5, true], [currentSet + 5, false]];
    Test.assertEqual(SolarTimes.changeMinutes(currentRise + 5, true, events, warsaw), 2);
    Test.assertEqual(SolarTimes.changeMinutes(currentSet + 5, false, events, warsaw), -2);
    return true;
}

(:test)
function solarNativeReferenceMatchesAllThreeDaysAndNightComparison(logger as Test.Logger) as Lang.Boolean {
    var savedEvents = SolarTimes._events;
    var savedLocation = SolarTimes._location;
    try {
        // Physical FR955 SolarProbe photo, 4 Nov 2026. Local readings are CET.
        var base = Gregorian.moment({:year => 2026, :month => 11, :day => 3, :hour => 0}).value();
        var riseYesterday = base + 5 * 3600 + 31 * 60 + 30;
        var setYesterday = base + 15 * 3600 + 11 * 60 + 47;
        var riseToday = base + 86400 + 5 * 3600 + 33 * 60 + 13;
        var setToday = base + 86400 + 15 * 3600 + 10 * 60 + 2;
        var riseTomorrow = base + 172800 + 5 * 3600 + 34 * 60 + 57;
        var setTomorrow = base + 172800 + 15 * 3600 + 8 * 60 + 19;
        var events = [[riseYesterday, true], [setYesterday, false], [riseToday, true],
            [setToday, false], [riseTomorrow, true], [setTomorrow, false]];
        var expected = ["06:32", "16:12", "06:33", "16:10", "06:35", "16:08"];
        SolarTimes._events = events;
        SolarTimes._location = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
        for (var i = 0; i < events.size(); i += 1) {
            Test.assertEqual(SolarTimes.eventText(events[i][0]), expected[i]);
        }
        Test.assertEqual(SolarTimes.eventLabel(riseToday, true), "06:33 +1");
        Test.assertEqual(SolarTimes.eventLabel(setToday, false), "16:10 -2");
        Test.assertEqual(SolarTimes.eventLabel(riseTomorrow, true), "06:35 +2");
        Test.assertEqual(SolarTimes.eventLabel(setTomorrow, false), "16:08 -2");
        var night = SolarTimes.intervalAt(setToday + 600, events);
        Test.assert(night != null && !night[2]);
        Test.assertEqual(SolarTimes.eventLabel(night[0], false), "16:10 -2");
        Test.assertEqual(SolarTimes.eventLabel(night[1], true), "06:35 +2");
        Test.assertEqual(SolarTimes.previousEvent(night[0], false, events,
            SolarTimes._location as Position.Location), setYesterday);
        Test.assertEqual(SolarTimes.previousEvent(night[1], true, events,
            SolarTimes._location as Position.Location), riseToday);
    } catch (ex) {
        SolarTimes._events = savedEvents;
        SolarTimes._location = savedLocation;
        throw ex;
    }
    SolarTimes._events = savedEvents;
    SolarTimes._location = savedLocation;
    return true;
}

(:test)
function solarPreviousEventKeepsCorrectKindDateAndExactSeconds(logger as Test.Logger) as Lang.Boolean {
    var location = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    var events = [
        [SolarTest.epoch(27, 15, 20) + 3, false],
        [SolarTest.epoch(28, 5, 21) + 1, true],
        [SolarTest.epoch(28, 15, 18) + 59, false],
        [SolarTest.epoch(29, 5, 23) + 17, true],
        [SolarTest.epoch(29, 15, 16) + 11, false],
        [SolarTest.epoch(30, 5, 25) + 40, true]
    ];
    Test.assertEqual(SolarTimes.previousEvent(SolarTest.epoch(29, 15, 16) + 11, false, events, location),
        SolarTest.epoch(28, 15, 18) + 59);
    Test.assertEqual(SolarTimes.previousEvent(SolarTest.epoch(30, 5, 25) + 40, true, events, location),
        SolarTest.epoch(29, 5, 23) + 17);
    Test.assertEqual(SolarTimes.previousEvent(SolarTest.epoch(28, 15, 18) + 59, false, events, location),
        SolarTest.epoch(27, 15, 20) + 3);
    Test.assert(SolarTimes.previousEvent(SolarTest.epoch(28, 5, 21) + 1, true, events, location) == null);
    return true;
}

(:test)
function solarCacheClearsWithoutAnyPositionAndRecovers(logger as Test.Logger) as Lang.Boolean {
    var location = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
    var now = new Time.Moment(SolarTest.epoch(30, 12, 0));
    SolarTimes.refresh(now, location);
    var revision = SolarTimes.revision();
    Test.assert(SolarTimes.current() != null);
    SolarTimes.refresh(now, location);
    Test.assertEqual(SolarTimes.revision(), revision);
    SolarTimes.refresh(now, null);
    Test.assert(SolarTimes.current() == null);
    Test.assertEqual(SolarTimes.eventLabel(null, true), "--:--");
    Test.assert(SolarTimes.revision() > revision);
    revision = SolarTimes.revision();
    SolarTimes.refresh(now, location);
    Test.assert(SolarTimes.current() != null);
    Test.assert(SolarTimes.revision() > revision);
    return true;
}

(:test)
function solarUsesDevicePositionWithoutWeatherFallback(logger as Test.Logger) as Lang.Boolean {
    var savedPosition = SolarPosition._last;
    try {
        SolarPosition._last = null;
        var expected = Position.getInfo().position;
        SunArc.invalidate();
        SunArc.refresh(Time.now());
        var actual = SolarTimes._location;
        if (expected == null) {
            Test.assert(actual == null);
            Test.assert(SolarTimes.current() == null);
        } else {
            Test.assert(actual != null);
            var a = actual.toDegrees();
            var b = expected.toDegrees();
            Test.assertEqual(a[0], b[0]);
            Test.assertEqual(a[1], b[1]);
        }
        var interval = SolarTimes.current();
        Test.assert(SunArc.currentDaylight() == (interval == null ? null : interval[2]));
        logger.debug("DEVICE SOLAR: start=" + SolarTimes.eventText(interval == null ? null : interval[0])
            + " end=" + SolarTimes.eventText(interval == null ? null : interval[1]));
    } catch (ex) {
        SolarPosition._last = savedPosition;
        SunArc.invalidate();
        throw ex;
    }
    SolarPosition._last = savedPosition;
    SunArc.invalidate();
    return true;
}

(:test)
function solarPositionKeepsLastDeviceFixAndAcceptsANewerOne(logger as Test.Logger) as Lang.Boolean {
    var saved = SolarPosition._last;
    try {
        SolarPosition._last = null;
        Test.assert(SolarPosition.retain(null) == null);
        var first = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
        var newer = new Position.Location({:latitude => 50.0647, :longitude => 19.9450, :format => :degrees});
        Test.assert(SolarPosition.retain(first) == first);
        Test.assert(SolarPosition.retain(null) == first);
        Test.assert(SolarPosition.retain(newer) == newer);
        Test.assert(SolarPosition.retain(null) == newer);
    } catch (ex) {
        SolarPosition._last = saved;
        throw ex;
    }
    SolarPosition._last = saved;
    return true;
}

(:test)
function solarRetainedDeviceFixFeedsCorrectDatedEvents(logger as Test.Logger) as Lang.Boolean {
    var saved = SolarPosition._last;
    try {
        var retained = new Position.Location({:latitude => 52.2297, :longitude => 21.0122, :format => :degrees});
        SolarPosition.retain(retained);
        var latest = Position.getInfo().position;
        var expected = latest == null ? retained : latest;
        var date = new Time.Moment(SolarTest.epoch(29, 12, 0));
        SunArc.invalidate();
        SunArc.refresh(date);
        var interval = SolarTimes.current();
        Test.assert(interval != null);
        var events = SolarTimes.eventsAround(SolarTimes.dateAnchor(date, expected), expected);
        var selected = SolarTimes.intervalAt(date.value(), events);
        Test.assert(selected != null);
        Test.assertEqual(interval[0], selected[0]);
        Test.assertEqual(interval[1], selected[1]);
        Test.assertEqual(interval[2], selected[2]);
    } catch (ex) {
        SolarPosition._last = saved;
        SunArc.invalidate();
        throw ex;
    }
    SolarPosition._last = saved;
    SunArc.invalidate();
    return true;
}
