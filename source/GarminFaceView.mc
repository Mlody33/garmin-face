import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class GarminFaceView extends WatchUi.WatchFace {
    private var _frame as Graphics.BufferedBitmap or Null = null;
    private var _renderCount as Lang.Number = 0;
    private var _minuteStamp as Lang.Number = -1;
    private var _dateKey as Lang.Number = -1;
    private var _dateLanguage as System.Language or Null = null;
    private var _dateText as Lang.String = "";
    private var _hour as Lang.Number = -1;
    private var _minute as Lang.Number = -1;
    private var _hourText as Lang.String = "";
    private var _minuteText as Lang.String = "";
    private var _timeFont as Graphics.FontType = Graphics.FONT_NUMBER_THAI_HOT;
    private var _timeX as Lang.Number = 0;
    private var _minuteX as Lang.Number = 0;
    private var _secondsX as Lang.Number = 0;
    private var _secondsY as Lang.Number = 0;
    private var _secondsTop as Lang.Number = 0;
    private var _secondsWidth as Lang.Number = 0;
    private var _secondsHeight as Lang.Number = 0;
    private var _secondsFont as Graphics.FontType or Null = null;
    protected var _lastSecond as Lang.Number = -1;
    private var _sleeping as Lang.Boolean = false;
    private var _frameSleeping as Lang.Boolean = false;
    private var _simple as Lang.Boolean = false;
    private var _background as Lang.Number = Graphics.COLOR_BLACK;
    private var _secondary as Lang.Number = Graphics.COLOR_LT_GRAY;
    private var _accent as Lang.Number = Graphics.COLOR_WHITE;
    private var _alarm as Lang.Boolean = false;
    private var _disconnected as Lang.Boolean = false;
    private var _fields as Lang.Array<Lang.String> = ["", "", ""];
    private var _readings as Lang.Array<Lang.Number or Lang.Float or Null> = [null, null, null];
    protected var _values as Lang.Array<Lang.String> = ["--", "--", "--"];
    private var _stepSweep as Lang.Number = -1;
    private var _historyStepSweep as Lang.Number = -1;
    private var _historyMinutesSweep as Lang.Number = -1;
    private var _activeMinutesSweep as Lang.Number = -1;
    private var _sunSweep as Lang.Number = -1;
    private var _sunDaylight as Lang.Boolean or Null = null;
    protected var _metricsUpdatedAt as Lang.Number = -1;
    private var _metricsRevision as Lang.Number = -1;
    private var _valueWidths as Lang.Array<Lang.Number> = [-1, -1, -1];
    private var _paintedWidths as Lang.Array<Lang.Number> = [0, 0, 0];
    private var _sampledAt as Lang.Array<Lang.Number> = [-1, -1, -1];
    private var _partialUpdatesEnabled as Lang.Boolean = true;
    private var _fieldTop as Lang.Number = 0;
    private var _fieldHeight as Lang.Number = 0;

    function initialize() { WatchFace.initialize(); }

    // Cheap diagnostic: number of scene rebuilds, independent of second ticks.
    function renderCount() as Lang.Number { return _renderCount; }

    function onEnterSleep() as Void {
        _sleeping = true;
        // Repaint from the scene without seconds so the last digits disappear.
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _sleeping = false;
        _partialUpdatesEnabled = true;
        WatchUi.requestUpdate();
    }

    // The next full minute update restores the screen even if Garmin rejected
    // the last partial transfer. Retry partial updates after the next wake.
    function disablePartialUpdates() as Void { _partialUpdatesEnabled = false; }

    function onShow() as Void {
        // Settings, notifications or another view may have covered the display.
        _minuteStamp = -1;
        WeatherRow.invalidate();
        SunArc.invalidate();
        GoalHistory.invalidate();
    }

    function onPartialUpdate(dc as Graphics.Dc) as Void {
        refreshSleepingFields(dc, Time.now().value());
    }

    // Only the values row is changed. Keep the cached scene in sync so a later
    // full repaint cannot restore older readings over a partial update.
    protected function refreshSleepingFields(dc as Graphics.Dc, now as Lang.Number) as Void {
        if (!_partialUpdatesEnabled || !_sleeping || !_frameSleeping || _frame == null || _minuteStamp < 0
            || _metricsRevision != MetricFields.revision() || now - _metricsUpdatedAt < 3) { return; }
        _metricsUpdatedAt = now;
        var slots = MetricFields.visibleSlots();
        if (slots.size() == 0) { return; }
        var due = 0;
        for (var index = 0; index < slots.size(); index += 1) {
            var slot = slots[index];
            if (MetricFields.firstSlot(slot) == slot
                && now - _sampledAt[slot] >= MetricFields.sleepInterval(_fields[slot])) {
                due |= 1 << slot;
            }
        }
        if (due == 0) { return; }
        var activity = (due & MetricFields.activitySlots()) != 0 ? ActivityMonitor.getInfo() : null;
        var changed = refreshMetrics(activity, now, due);
        if (changed == 0) { return; }
        repaintFields(slots, changed, dc);
    }

    // Patch only the values row in the reusable scene. Full updates still copy
    // the complete scene to the screen; sleep updates copy the clipped row.
    private function repaintFields(slots as Lang.Array<Lang.Number>, changed as Lang.Number,
                                   screen as Graphics.Dc or Null) as Void {
        var target = (_frame as Graphics.BufferedBitmap).getDc();
        var left = 260;
        var right = 0;
        for (var index = 0; index < slots.size(); index += 1) {
            var slot = slots[index];
            if ((changed & (1 << slot)) == 0) { continue; }
            var width = valueWidth(target, slot);
            var extent = (width > _paintedWidths[slot] ? width : _paintedWidths[slot]) / 2 + 2;
            var x = FaceLayout.fieldX(index, slots.size());
            if (x - extent < left) { left = x - extent; }
            if (x + extent > right) { right = x + extent; }
        }
        if (left < 0) { left = 0; }
        if (right > 260) { right = 260; }
        target.setClip(left, _fieldTop, right - left, _fieldHeight);
        target.setColor(_background, _background);
        target.fillRectangle(left, _fieldTop, right - left, _fieldHeight);
        // Preserve any icon edge intersecting the row's padded clipping region.
        drawFields(target, slots, !_sleeping);
        target.clearClip();
        if (screen != null) {
            screen.setClip(left, _fieldTop, right - left, _fieldHeight);
            screen.drawBitmap(0, 0, _frame as Graphics.BufferedBitmap);
            screen.clearClip();
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var now = Time.now();
        var stamp = now.value() / 60;
        var clock = System.getClockTime();
        var settings = System.getDeviceSettings();
        var simple = FaceOptions.simpleView();
        var showArcs = !simple && !_sleeping;
        var background = FaceColors.background();
        var secondary = FaceColors.secondary();
        var accent = FaceColors.getDisplayColor();
        var dirty = _frame == null || _minuteStamp != stamp || _background != background
            || _secondary != secondary || _accent != accent || _simple != simple
            || _frameSleeping != _sleeping;
        _simple = simple;
        _background = background;
        _secondary = secondary;
        _accent = accent;

        if (_minuteStamp != stamp || _dateLanguage != settings.systemLanguage) {
            var date = Gregorian.info(now, Time.FORMAT_SHORT);
            var dateKey = date.year * 10000 + date.month * 100 + date.day;
            if (_dateKey != dateKey || _dateLanguage != settings.systemLanguage) {
                var names = Gregorian.info(now, Time.FORMAT_MEDIUM);
                _dateText = (names.day_of_week as Lang.String) + ", " + date.day.format("%d") + " " + (names.month as Lang.String);
                _dateKey = dateKey;
                _dateLanguage = settings.systemLanguage;
                dirty = true;
            }
        }
        var alarm = settings.alarmCount > 0;
        var disconnected = !settings.phoneConnected;
        if (_alarm != alarm || _disconnected != disconnected) { dirty = true; }
        _alarm = alarm;
        _disconnected = disconnected;
        WeatherRow.refresh(stamp);

        var slots = MetricFields.visibleSlots();
        var activity = showArcs || MetricFields.needsActivity() ? ActivityMonitor.getInfo() : null;
        if (_metricsRevision != MetricFields.revision()) { dirty = true; }
        var changed = refreshMetrics(activity, now.value(), 7);
        _metricsUpdatedAt = now.value();
        var stepProgress = null;
        var activeMinutesProgress = null;
        var historySteps = null;
        var historyMinutes = null;
        var sunProgress = null;
        var sunDaylight = null;
        if (showArcs) {
            GoalHistory.refresh(now, settings.firstDayOfWeek);
            if (activity != null) {
                stepProgress = ProgressArc.goalProgress(activity.steps, activity.stepGoal);
                historySteps = ProgressArc.goalProgress(GoalHistory.steps, activity.stepGoal);
                historyMinutes = ProgressArc.goalProgress(GoalHistory.minutes, activity.activeMinutesWeekGoal);
                var minutes = activity.activeMinutesWeek;
                // Garmin's total already includes twice the vigorous minutes.
                activeMinutesProgress = ProgressArc.goalProgress(
                    minutes == null ? null : minutes.total, activity.activeMinutesWeekGoal);
            }
            var historyStepSweep = historySteps == null ? -1 : ProgressArc.sweep(historySteps);
            var historyMinutesSweep = historyMinutes == null ? -1 : ProgressArc.sweep(historyMinutes);
            if (_historyStepSweep != historyStepSweep || _historyMinutesSweep != historyMinutesSweep) { dirty = true; }
            _historyStepSweep = historyStepSweep;
            _historyMinutesSweep = historyMinutesSweep;
            SunArc.refresh(now);
            sunProgress = SunArc.currentProgress(now.value());
            sunDaylight = SunArc.currentDaylight();
            var stepSweep = ProgressArc.sweep(stepProgress);
            var activeMinutesSweep = ProgressArc.sweep(activeMinutesProgress);
            var sunSweep = ProgressArc.sweep(sunProgress);
            if (_stepSweep != stepSweep || _activeMinutesSweep != activeMinutesSweep
                || _sunSweep != sunSweep || _sunDaylight != sunDaylight) { dirty = true; }
            _stepSweep = stepSweep;
            _activeMinutesSweep = activeMinutesSweep;
            _sunSweep = sunSweep;
            _sunDaylight = sunDaylight;
        }
        if (_hour != clock.hour || _minute != clock.min) { dirty = true; }
        if (dirty) {
            if (_frame == null) {
                // Full device palette preserves the existing anti-aliased vector fonts.
                _frame = Graphics.createBufferedBitmap({:width => 260, :height => 260}).get() as Graphics.BufferedBitmap;
            }
            var target = (_frame as Graphics.BufferedBitmap).getDc();
            if (_fieldHeight == 0) {
                _fieldHeight = target.getFontHeight(FaceFonts.text()) + 4;
                _fieldTop = FaceLayout.FIELD_VALUE_Y - _fieldHeight / 2;
            }
            target.clearClip();
            target.setColor(_secondary, _background);
            target.clear();
            if (showArcs) { SunArc.draw(target, sunProgress); }
            WeatherRow.draw(target, FaceLayout.CENTER_X, FaceLayout.DATE_Y, _dateText);
            drawClock(target, clock);
            drawStatus(target);
            drawFields(target, slots, !_sleeping);
            if (showArcs) {
                ProgressArc.draw(target, 234, Graphics.ARC_COUNTER_CLOCKWISE, stepProgress, 0, true);
                ProgressArc.draw(target, 234, Graphics.ARC_COUNTER_CLOCKWISE, activeMinutesProgress,
                    ProgressArc.ACTIVE_MINUTES_INSET, true);
                ProgressArc.drawHistoryMarker(target, historySteps, 0);
                ProgressArc.drawHistoryMarker(target, historyMinutes, ProgressArc.ACTIVE_MINUTES_INSET);
            }
            _minuteStamp = stamp;
            _frameSleeping = _sleeping;
            _renderCount += 1;
        } else if (changed != 0) {
            repaintFields(slots, changed, null);
        }
        if (!_sleeping) {
            DigitalSeconds.prepare(dc, _secondsFont as Graphics.FontType, _background, _secondary);
        }
        // Always repaint the whole display on onUpdate (overlays can invalidate it).
        dc.clearClip();
        dc.drawBitmap(0, 0, _frame as Graphics.BufferedBitmap);
        _lastSecond = -1;
        if (!_sleeping) { drawSecond(dc, clock.sec); }
    }

    // Share sampling, duplicate-field reuse and formatting between power modes.
    private function refreshMetrics(activity as ActivityMonitor.Info or Null,
                                    now as Lang.Number, sources as Lang.Number) as Lang.Number {
        var configurationChanged = _metricsRevision != MetricFields.revision();
        var changedSlots = 0;
        for (var slot = 0; slot < FaceLayout.FIELD_COUNT; slot += 1) {
            var changed = false;
            if (configurationChanged) {
                var metric = MetricFields.get(slot);
                changed = !_fields[slot].equals(metric);
                _fields[slot] = metric;
            }
            if (changed) { changedSlots |= 1 << slot; }
            var metric = _fields[slot];
            if (metric.equals(MetricFields.NONE)) { continue; }
            var first = MetricFields.firstSlot(slot);
            if ((sources & (1 << first)) == 0) { continue; }
            var reading = first < slot ? _readings[first] : metricValue(metric, activity);
            _sampledAt[slot] = now;
            if (changed || reading != _readings[slot]) {
                var text = first < slot ? _values[first] : MetricFields.formatValue(metric, reading);
                if (!text.equals(_values[slot])) {
                    changedSlots |= 1 << slot;
                    _valueWidths[slot] = -1;
                }
                _values[slot] = text;
                _readings[slot] = reading;
            }
        }
        _metricsRevision = MetricFields.revision();
        return changedSlots;
    }

    protected function metricValue(metric as Lang.String, activity as ActivityMonitor.Info or Null)
            as Lang.Number or Lang.Float or Null {
        return MetricFields.value(metric, activity);
    }

    private function drawFields(dc as Graphics.Dc, slots as Lang.Array<Lang.Number>, icons as Lang.Boolean) as Void {
        var font = FaceFonts.text();
        for (var index = 0; index < slots.size(); index += 1) {
            var slot = slots[index];
            var x = FaceLayout.fieldX(index, slots.size());
            if (icons) { DataIcons.drawMetricIcon(dc, x, FaceLayout.FIELD_ICON_Y, _fields[slot]); }
            drawCentered(dc, x, FaceLayout.FIELD_VALUE_Y, font, _values[slot], _secondary);
            _paintedWidths[slot] = valueWidth(dc, slot);
        }
    }

    private function valueWidth(dc as Graphics.Dc, slot as Lang.Number) as Lang.Number {
        if (_valueWidths[slot] < 0) {
            var first = MetricFields.firstSlot(slot);
            _valueWidths[slot] = first < slot ? valueWidth(dc, first)
                : measureValueWidth(dc, _values[slot]);
        }
        return _valueWidths[slot];
    }

    protected function measureValueWidth(dc as Graphics.Dc, text as Lang.String) as Lang.Number {
        return dc.getTextWidthInPixels(text, FaceFonts.text());
    }

    private function drawStatus(dc as Graphics.Dc) as Void {
        dc.setColor(_secondary, _background);
        var x = _secondsX + (_secondsWidth - 2) / 2;
        var y = _secondsTop - 14;
        if (_alarm) { DataIcons.drawAlarm(dc, x, _disconnected ? y - 22 : y); }
        if (_disconnected) { DataIcons.drawPhoneDisconnected(dc, x, y); }
    }

    private function drawClock(dc as Graphics.Dc, clock as System.ClockTime) as Void {
        if (_secondsFont == null) {
            _secondsFont = FaceFonts.seconds();
            _secondsWidth = dc.getTextWidthInPixels("00", _secondsFont as Graphics.FontType) + 2;
            _secondsHeight = dc.getFontHeight(_secondsFont as Graphics.FontType) + 4;
        }
        if (_hour != clock.hour || _minute != clock.min) {
            _hour = clock.hour;
            _minute = clock.min;
            _hourText = _hour.format("%02d");
            _minuteText = _minute.format("%02d");
            _timeFont = Graphics.FONT_NUMBER_THAI_HOT;
            var hourWidth = dc.getTextWidthInPixels(_hourText, _timeFont);
            var width = hourWidth + 10 + dc.getTextWidthInPixels(_minuteText, _timeFont);
            var secondsWidth = _secondsWidth - 2;
            var gap = 5;
            if (width + gap + secondsWidth > 236) {
                _timeFont = Graphics.FONT_NUMBER_HOT;
                hourWidth = dc.getTextWidthInPixels(_hourText, _timeFont);
                width = hourWidth + 10 + dc.getTextWidthInPixels(_minuteText, _timeFont);
            }
            var left = (260 - width - gap - secondsWidth) / 2;
            _timeX = left;
            _minuteX = left + hourWidth + 10;
            _secondsX = left + width + 5;
            _secondsY = 130 + (_timeFont == Graphics.FONT_NUMBER_THAI_HOT ? 21 : 17);
            _secondsTop = _secondsY - _secondsHeight / 2;
        }
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_timeX, 130, _timeFont, _hourText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_minuteX, 130, _timeFont, _minuteText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawSecond(dc as Graphics.Dc, second as Lang.Number) as Void {
        DigitalSeconds.draw(dc, _secondsX, _secondsY, _secondsTop, _secondsWidth, second);
        _lastSecond = second;
    }

    private function drawCentered(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
                                 font as Graphics.FontType, text as Lang.String, color as Lang.Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
