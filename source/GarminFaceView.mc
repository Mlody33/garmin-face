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
    private var _timeText as Lang.String = "";
    private var _timeFont as Graphics.FontType = Graphics.FONT_NUMBER_THAI_HOT;
    private var _timeX as Lang.Number = 0;
    private var _secondsX as Lang.Number = 0;
    private var _secondsY as Lang.Number = 0;
    private var _secondsTop as Lang.Number = 0;
    private var _secondsWidth as Lang.Number = 0;
    private var _secondsHeight as Lang.Number = 0;
    private var _secondsFont as Graphics.FontType or Null = null;
    private var _lastSecond as Lang.Number = -1;
    private var _analog as Lang.Boolean = false;
    private var _simple as Lang.Boolean = false;
    private var _background as Lang.Number = Graphics.COLOR_BLACK;
    private var _secondary as Lang.Number = Graphics.COLOR_LT_GRAY;
    private var _accent as Lang.Number = Graphics.COLOR_WHITE;
    private var _alarm as Lang.Boolean = false;
    private var _disconnected as Lang.Boolean = false;
    private var _fields as Lang.Array<Lang.String> = ["", "", ""];
    private var _readings as Lang.Array<Lang.Number or Lang.Float or Null> = [null, null, null];
    private var _values as Lang.Array<Lang.String> = ["--", "--", "--"];
    private var _stepSweep as Lang.Number = -1;
    private var _sunSweep as Lang.Number = -1;
    private var _sunDaylight as Lang.Boolean or Null = null;

    function initialize() { WatchFace.initialize(); }

    // Cheap diagnostic: number of scene rebuilds, independent of second ticks.
    function renderCount() as Lang.Number { return _renderCount; }

    function onShow() as Void {
        // Settings, notifications or another view may have covered the display.
        _minuteStamp = -1;
        WeatherRow.invalidate();
        SunArc.invalidate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var now = Time.now();
        var stamp = now.value() / 60;
        var clock = System.getClockTime();
        var settings = System.getDeviceSettings();
        var simple = FaceOptions.simpleView();
        var analog = FaceOptions.analogSeconds();
        var background = FaceColors.background();
        var secondary = FaceColors.secondary();
        var accent = FaceColors.getDisplayColor();
        var dirty = _frame == null || _minuteStamp != stamp || _background != background
            || _secondary != secondary || _accent != accent || _simple != simple || _analog != analog;
        // Invalidate clock geometry immediately when the seconds layout changes.
        if (_analog != analog) { _hour = -1; }
        _simple = simple;
        _analog = analog;
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
        var activity = slots.size() > 0 || !simple ? ActivityMonitor.getInfo() : null;
        for (var slot = 0; slot < FaceLayout.FIELD_COUNT; slot += 1) {
            var metric = MetricFields.get(slot);
            var changed = !_fields[slot].equals(metric);
            if (changed) { dirty = true; }
            _fields[slot] = metric;
            if (metric.equals(MetricFields.NONE)) { continue; }
            // Repeated fields share the first reading and formatted text this frame.
            var duplicate = -1;
            for (var prior = 0; prior < slot; prior += 1) {
                if (_fields[prior].equals(metric)) { duplicate = prior; break; }
            }
            var reading = duplicate >= 0 ? _readings[duplicate]
                : MetricFields.value(metric, activity as ActivityMonitor.Info);
            if (changed || reading != _readings[slot]) {
                var text = duplicate >= 0 ? _values[duplicate] : MetricFields.formatValue(metric, reading);
                if (!_values[slot].equals(text)) { dirty = true; }
                _values[slot] = text;
                _readings[slot] = reading;
            }
        }
        var stepProgress = null;
        var sunProgress = null;
        var sunDaylight = null;
        if (!simple) {
            if (activity != null && activity.steps != null && activity.stepGoal != null && activity.stepGoal > 0) {
                stepProgress = activity.steps.toFloat() / activity.stepGoal;
            }
            SunArc.refresh(now);
            sunProgress = SunArc.currentProgress(now.value());
            sunDaylight = SunArc.currentDaylight();
            var stepSweep = ProgressArc.sweep(stepProgress);
            var sunSweep = ProgressArc.sweep(sunProgress);
            if (_stepSweep != stepSweep || _sunSweep != sunSweep || _sunDaylight != sunDaylight) { dirty = true; }
            _stepSweep = stepSweep;
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
            target.clearClip();
            target.setColor(_secondary, _background);
            target.clear();
            if (!simple) { SunArc.draw(target, sunProgress); }
            WeatherRow.draw(target, FaceLayout.CENTER_X, FaceLayout.DATE_Y, _dateText);
            drawStatus(target);
            drawClock(target, clock);
            for (var index = 0; index < slots.size(); index += 1) {
                var slot = slots[index];
                var x = FaceLayout.fieldX(index, slots.size());
                DataIcons.drawMetricIcon(target, x, FaceLayout.FIELD_ICON_Y, _fields[slot]);
                drawCentered(target, x, FaceLayout.FIELD_VALUE_Y, FaceFonts.text(), _values[slot], _secondary);
            }
            ProgressArc.draw(target, 234, Graphics.ARC_COUNTER_CLOCKWISE, stepProgress);
            _minuteStamp = stamp;
            _renderCount += 1;
        }
        if (analog) { AnalogSeconds.prepare(_background, _accent); }
        else { DigitalSeconds.prepare(dc, _secondsFont as Graphics.FontType, _background, _secondary); }
        // Always repaint the whole display on onUpdate (overlays can invalidate it).
        dc.clearClip();
        dc.drawBitmap(0, 0, _frame as Graphics.BufferedBitmap);
        _lastSecond = -1;
        drawSecond(dc, clock.sec);
    }

    private function drawStatus(dc as Graphics.Dc) as Void {
        dc.setColor(_secondary, _background);
        if (_alarm) { DataIcons.drawAlarm(dc, _disconnected ? 117 : 130, FaceLayout.STATUS_Y); }
        if (_disconnected) { DataIcons.drawPhoneDisconnected(dc, _alarm ? 143 : 130, FaceLayout.STATUS_Y); }
    }

    private function drawClock(dc as Graphics.Dc, clock as System.ClockTime) as Void {
        if (_secondsFont == null && !_analog) {
            _secondsFont = FaceFonts.seconds();
            _secondsWidth = dc.getTextWidthInPixels("00", _secondsFont as Graphics.FontType) + 2;
            _secondsHeight = dc.getFontHeight(_secondsFont as Graphics.FontType) + 4;
        }
        if (_hour != clock.hour || _minute != clock.min) {
            _hour = clock.hour;
            _minute = clock.min;
            _timeText = _hour.format("%02d") + " " + _minute.format("%02d");
            _timeFont = Graphics.FONT_NUMBER_THAI_HOT;
            var width = dc.getTextWidthInPixels(_timeText, _timeFont);
            var secondsWidth = _analog ? 0 : _secondsWidth - 2;
            var gap = _analog ? 0 : 5;
            if (width + gap + secondsWidth > 236) {
                _timeFont = Graphics.FONT_NUMBER_HOT;
                width = dc.getTextWidthInPixels(_timeText, _timeFont);
            }
            var left = (260 - width - gap - secondsWidth) / 2;
            _timeX = left + width / 2;
            _secondsX = left + width + 5;
            _secondsY = 130 + (_timeFont == Graphics.FONT_NUMBER_THAI_HOT ? 21 : 17);
            _secondsTop = _secondsY - _secondsHeight / 2;
        }
        drawCentered(dc, _timeX, 130, _timeFont, _timeText, _accent);
    }

    function onPartialUpdate(dc as Graphics.Dc) as Void {
        if (_frame != null) { drawSecond(dc, System.getClockTime().sec); }
    }

    private function drawSecond(dc as Graphics.Dc, second as Lang.Number) as Void {
        if (_lastSecond == second) { return; }
        if (_analog) {
            AnalogSeconds.draw(dc, second, _lastSecond, _frame);
        } else {
            DigitalSeconds.draw(dc, _secondsX, _secondsY, _secondsTop, _secondsWidth, second);
        }
        _lastSecond = second;
    }

    private function drawCentered(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
                                 font as Graphics.FontType, text as Lang.String, color as Lang.Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
