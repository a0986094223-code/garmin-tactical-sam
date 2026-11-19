using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.ActivityMonitor as ActMon;
using Toybox.SensorHistory as SensorHist;
using Toybox.Weather as Weather;
using Toybox.Math as Math;

class TacticalSAMView extends Ui.WatchFace {
    private var _isAwake = true;
    private var _terrainIdx = 0;
    private var _lastHour = -1;
    private var _enemyX = 240;
    private var _enemyY = 148;
    private var _crashing = false;
    private var _crashVy = 0;
    private var _missileX = -1;
    private var _missileY = -1;
    private var _kills = 0;

    function initialize() {
        WatchFace.initialize();
        _terrainIdx = Math.rand() % 4;
    }

    function onEnterSleep() {
        _isAwake = false;
        Ui.requestUpdate();
    }

    function onExitSleep() {
        _isAwake = true;
        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var divY = 114;
        var gndY = 218;

        var clockTime = Sys.getClockTime();
        var hr = clockTime.hour;
        var min = clockTime.min;
        var sec = clockTime.sec;

        if (_lastHour != hr) {
            _lastHour = hr;
            _terrainIdx = (Math.rand() % 4);
        }

        var timeStr = hr.format("%02d") + ":" + min.format("%02d");
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateStr = info.month.format("%02d") + "/" + info.day.format("%02d");
        var bat = Sys.getSystemStats().battery.toNumber();

        var actInfo = ActMon.getInfo();
        var steps = (actInfo != null && actInfo.steps != null) ? actInfo.steps : 0;
        var spo2 = 98;
        if (Toybox has :SensorHistory && SensorHist has :getOxygenSaturationHistory) {
            var oxIter = SensorHist.getOxygenSaturationHistory({ :period => 1 });
            var sample = oxIter.next();
            if (sample != null && sample.data != null) {
                spo2 = sample.data.toNumber();
            }
        }

        var weatherStr = "24C";
        if (Toybox has :Weather) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.temperature != null) {
                weatherStr = cond.temperature.format("%d") + "C";
            }
        }

        if (!_isAwake) {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
            dc.clear();
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, 54, Gfx.FONT_NUMBER_THAI_HOT, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, 108, Gfx.FONT_XTINY, dateStr + "  " + weatherStr + "  " + bat + "%", Gfx.TEXT_JUSTIFY_CENTER);
            dc.fillRectangle(24, 132, w - 48, 2);
            dc.drawText(cx - 52, 232, Gfx.FONT_XTINY, steps.toString(), Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx + 52, 232, Gfx.FONT_XTINY, "O2 " + spo2 + "%", Gfx.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.setColor(0x0055AA, 0x0055AA);
        dc.fillRectangle(0, 0, w, divY);

        var skyColor = (hr >= 6 && hr < 15) ? 0x00AAFF : ((hr >= 15 && hr < 18) ? 0xFF5500 : 0x000055);
        dc.setColor(skyColor, skyColor);
        dc.fillRectangle(0, divY, w, gndY - divY);

        if (_terrainIdx == 0) {
            dc.setColor(0x555555, 0x555555);
            dc.fillRectangle(45, gndY - 26, 16, 26);
            dc.fillRectangle(125, gndY - 34, 20, 34);
            dc.fillRectangle(185, gndY - 28, 18, 28);
            dc.fillRectangle(215, gndY - 22, 15, 22);
            dc.setColor(0x000000, 0x000000);
            dc.fillRectangle(0, gndY, w, h - gndY);
        } else if (_terrainIdx == 1) {
            dc.setColor(0x005555, 0x005555);
            dc.fillPolygon([[20, gndY], [80, gndY - 32], [140, gndY]]);
            dc.fillPolygon([[130, gndY], [195, gndY - 38], [260, gndY]]);
            dc.setColor(0x000000, 0x000000);
            dc.fillRectangle(0, gndY, w, h - gndY);
        } else if (_terrainIdx == 2) {
            dc.setColor(0x0055AA, 0x0055AA);
            dc.fillRectangle(0, gndY - 8, w, h - (gndY - 8));
        } else {
            dc.setColor(0xFFAA00, 0xFFAA00);
            dc.fillPolygon([[20, gndY], [110, gndY - 16], [210, gndY - 14], [260, gndY]]);
            dc.setColor(0xAA5500, 0xAA5500);
            dc.fillRectangle(0, gndY, w, h - gndY);
        }

        dc.setColor(0x00FF00, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx + 52, 18, Gfx.FONT_SMALL, bat + "%", Gfx.TEXT_JUSTIFY_CENTER);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, 38, Gfx.FONT_NUMBER_HOT, timeStr + ":" + sec.format("%02d"), Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx - 56, 86, Gfx.FONT_XTINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx + 56, 86, Gfx.FONT_XTINY, weatherStr + " 擊落" + _kills, Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        dc.fillRectangle(0, divY, w, 2);

        var tx = 78;
        dc.setColor(0x555555, 0x555555);
        dc.fillPolygon([[tx - 16, gndY], [tx - 6, gndY - 8], [tx + 6, gndY - 8], [tx + 16, gndY]]);
        dc.fillRectangle(tx - 3, gndY - 17, 6, 9);
        dc.setColor(0xAA5500, 0xAA5500);
        dc.fillRectangle(tx - 10, gndY - 28, 22, 13);
        dc.setColor(0xFFAA00, 0xFFAA00);
        dc.fillRectangle(tx + 5, gndY - 28, 4, 13);

        if (_crashing) {
            _enemyX -= 4;
            _crashVy += 3;
            _enemyY += _crashVy;
            dc.setColor(0x555555, 0x555555);
            dc.fillCircle(_enemyX + 6, _enemyY - 4, 3);
            dc.setColor(0xFF5500, 0xFF5500);
            dc.fillPolygon([[_enemyX - 9, _enemyY + 3], [_enemyX + 7, _enemyY - 4], [_enemyX + 7, _enemyY + 5]]);
            if (_enemyY >= gndY - 2) {
                _crashing = false;
                _enemyX = w - 24;
                _enemyY = divY + 26 + (Math.rand() % 44);
            }
        } else {
            _enemyX -= 6;
            if (_enemyX < 28) { _enemyX = w - 24; }
            dc.setColor(0x005500, 0x005500);
            dc.fillPolygon([[_enemyX - 10, _enemyY], [_enemyX + 8, _enemyY - 4], [_enemyX + 8, _enemyY + 4]]);
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
            dc.fillCircle(_enemyX + 2, _enemyY, 2);

            if (_missileX < 0 && _enemyX < w - 45) {
                _missileX = tx + 14;
                _missileY = gndY - 22;
            }
        }

        if (_missileX >= 0) {
            _missileX += 14;
            _missileY -= 7;
            dc.setColor(0xFFAA00, 0xFFAA00);
            dc.fillCircle(_missileX, _missileY, 2);
            if (!_crashing && (_missileX - _enemyX).abs() < 14 && (_missileY - _enemyY).abs() < 14) {
                _kills += 1;
                _crashing = true;
                _crashVy = 2;
                _missileX = -1;
            } else if (_missileX > w || _missileY < divY) {
                _missileX = -1;
            }
        }

        var radarY = 244;
        dc.setColor(0x00AAFF, Gfx.COLOR_TRANSPARENT);
        dc.drawCircle(cx, radarY, 15);
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
        dc.fillCircle(cx + 5, radarY - 3, 2);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx - 54, radarY - 8, Gfx.FONT_XTINY, steps.toString(), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx + 54, radarY - 8, Gfx.FONT_XTINY, "O2 " + spo2 + "%", Gfx.TEXT_JUSTIFY_CENTER);
    }
}
