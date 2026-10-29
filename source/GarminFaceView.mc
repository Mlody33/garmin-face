import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class GarminFaceView extends WatchUi.WatchFace {
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
    private var _clockAnalog as Lang.Boolean = false;
    private var _pointerSecond as Lang.Number = -1;

    function initialize() {
        WatchFace.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var settings = System.getDeviceSettings();
        var dateKey = date.year * 10000 + date.month * 100 + date.day;
        if (_dateKey != dateKey || _dateLanguage != settings.systemLanguage) {
            var names = Gregorian.info(now, Time.FORMAT_MEDIUM);
            _dateText = (names.day_of_week as Lang.String) + ", "
                + date.day.format("%d") + " " + (names.month as Lang.String);
            _dateKey = dateKey;
            _dateLanguage = settings.systemLanguage;
        }
        dc.setColor(FaceColors.secondary(), FaceColors.background());
        dc.clear();
        var simple = FaceOptions.simpleView();
        if (!simple) {
            SunArc.draw(dc, date.hour * 3600 + date.min * 60 + date.sec);
        }
        WeatherRow.draw(dc, dc.getWidth() / 2, FaceLayout.DATE_Y, _dateText);
        drawStatus(dc, settings);
        var clock = System.getClockTime();
        drawClock(dc, clock);

        var slots = MetricFields.visibleSlots();
        var activity = ActivityMonitor.getInfo();
        for (var index = 0; index < slots.size(); index += 1) {
            var metric = MetricFields.get(slots[index]);
            var x = FaceLayout.fieldX(index, slots.size());
            dc.setColor(FaceColors.secondary(), FaceColors.background());
            DataIcons.drawMetricIcon(dc, x, FaceLayout.FIELD_ICON_Y, metric);
            drawCentered(dc, x, FaceLayout.FIELD_VALUE_Y, FaceFonts.text(),
                MetricFields.formatValue(metric, MetricFields.value(metric, activity)), FaceColors.secondary());
        }
        var stepProgress = null;
        if (activity.steps != null && activity.stepGoal != null && activity.stepGoal > 0) {
            stepProgress = activity.steps.toFloat() / activity.stepGoal;
        }
        ProgressArc.draw(dc, 234, Graphics.ARC_COUNTER_CLOCKWISE, stepProgress);
        // Always draw the analog marker last, above arcs and all other content.
        _pointerSecond = -1;
        if (FaceOptions.analogSeconds()) { drawPointer(dc, clock.sec); }
    }

    private function drawStatus(dc as Graphics.Dc, settings as System.DeviceSettings) as Void {
        var x = dc.getWidth() / 2;
        var alarm = settings.alarmCount > 0;
        var disconnected = !settings.phoneConnected;
        dc.setColor(FaceColors.secondary(), FaceColors.background());
        if (alarm) { DataIcons.drawAlarm(dc, disconnected ? x - 13 : x, FaceLayout.STATUS_Y); }
        if (disconnected) { DataIcons.drawPhoneDisconnected(dc, alarm ? x + 13 : x, FaceLayout.STATUS_Y); }
    }

    private function drawClock(dc as Graphics.Dc, clock as System.ClockTime) as Void {
        var analog = FaceOptions.analogSeconds();
        if (_secondsWidth == 0) {
            _secondsWidth = dc.getTextWidthInPixels("00", FaceFonts.seconds()) + 2;
            _secondsHeight = dc.getFontHeight(FaceFonts.seconds()) + 4;
        }
        if (_hour != clock.hour || _minute != clock.min || _clockAnalog != analog) {
            _clockAnalog = analog;
            _hour = clock.hour;
            _minute = clock.min;
            _timeText = _hour.format("%02d") + " " + _minute.format("%02d");
            _timeFont = Graphics.FONT_NUMBER_THAI_HOT;
            var width = dc.getTextWidthInPixels(_timeText, _timeFont);
            var secondsWidth = analog ? 0 : _secondsWidth - 2;
            var gap = analog ? 0 : 5;
            if (width + gap + secondsWidth > 236) {
                _timeFont = Graphics.FONT_NUMBER_HOT;
                width = dc.getTextWidthInPixels(_timeText, _timeFont);
            }
            var left = (dc.getWidth() - width - gap - secondsWidth) / 2;
            _timeX = left + width / 2;
            _secondsX = left + width + 5;
            _secondsY = dc.getHeight() / 2 + (_timeFont == Graphics.FONT_NUMBER_THAI_HOT ? 21 : 17);
            _secondsTop = _secondsY - _secondsHeight / 2;
        }
        drawCentered(dc, _timeX, dc.getHeight() / 2, _timeFont, _timeText, FaceColors.getDisplayColor());
        if (!analog) { drawSeconds(dc, clock.sec); }
    }

    function onPartialUpdate(dc as Graphics.Dc) as Void {
        if (_secondsWidth == 0) { return; }
        var second = System.getClockTime().sec;
        if (FaceOptions.analogSeconds()) { drawPointer(dc, second); }
        else { drawSeconds(dc, second); }
    }

    private function drawPointer(dc as Graphics.Dc, second as Lang.Number) as Void {
        if (_pointerSecond == second) { return; }
        AnalogSeconds.draw(dc, second, _pointerSecond);
        _pointerSecond = second;
    }

    private function drawSeconds(dc as Graphics.Dc, seconds as Lang.Number) as Void {
        // Keep partial refresh inside the original small rectangle and power budget.
        dc.setClip(_secondsX - 1, _secondsTop, _secondsWidth, _secondsHeight);
        dc.setColor(FaceColors.background(), FaceColors.background());
        dc.fillRectangle(_secondsX - 1, _secondsTop, _secondsWidth, _secondsHeight);
        dc.setColor(FaceColors.secondary(), FaceColors.background());
        dc.drawText(_secondsX, _secondsY, FaceFonts.seconds(), seconds.format("%02d"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.clearClip();
    }

    private function drawCentered(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
                                 font as Graphics.FontType, text as Lang.String, color as Lang.Number) as Void {
        // Transparent font bounds prevent the large clock from erasing the date.
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
