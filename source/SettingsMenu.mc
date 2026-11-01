import Toybox.Lang;
import Toybox.WatchUi;

// Return this menu directly from getSettingsView: one Back exits customization.
class FaceSettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Rez.Strings.CustomizeTitle});
        var names = [Rez.Strings.LeftFieldLabel, Rez.Strings.CenterFieldLabel, Rez.Strings.RightFieldLabel];
        for (var slot = 0; slot < FaceLayout.FIELD_COUNT; slot += 1) {
            addItem(new WatchUi.MenuItem(names[slot], MetricFields.label(MetricFields.get(slot)), slot, null));
        }
        addItem(new WatchUi.MenuItem(Rez.Strings.AccentColorLabel,
            FaceColors.label(FaceColors.get()), "accent", null));
        addItem(new WatchUi.ToggleMenuItem(Rez.Strings.SimpleViewLabel,
            {:enabled => Rez.Strings.EnabledLabel, :disabled => Rez.Strings.DisabledLabel},
            FaceOptions.KEY, FaceOptions.simpleView(), null));
        addItem(new WatchUi.ToggleMenuItem(Rez.Strings.LightBackgroundLabel,
            {:enabled => Rez.Strings.EnabledLabel, :disabled => Rez.Strings.DisabledLabel},
            FaceOptions.LIGHT_BACKGROUND_KEY, FaceOptions.lightBackground(), null));
    }
}

class FaceSettingsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() { Menu2InputDelegate.initialize(); }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item instanceof WatchUi.ToggleMenuItem && item.getId().equals(FaceOptions.KEY)) {
            FaceOptions.saveSimpleView(item.isEnabled());
            return;
        }
        if (item instanceof WatchUi.ToggleMenuItem && item.getId().equals(FaceOptions.LIGHT_BACKGROUND_KEY)) {
            FaceOptions.saveLightBackground(item.isEnabled());
            return;
        }
        var accent = item.getId().equals("accent");
        var slot = accent ? null : item.getId() as Lang.Number;
        var options = accent ? FaceColors.choices() : MetricFields.choices();
        var current = accent ? FaceColors.get() : MetricFields.get(slot as Lang.Number);
        var menu = new WatchUi.Menu2({:title => item.getLabel()});
        var selected = 0;
        for (var i = 0; i < options.size(); i += 1) {
            var value = options[i];
            var label = accent ? FaceColors.label(value as Lang.Number) : MetricFields.label(value as Lang.String);
            menu.addItem(new WatchUi.MenuItem(label, null, value, null));
            if (value.equals(current)) { selected = i; }
        }
        menu.setFocus(selected);
        WatchUi.pushView(menu, new SettingChoiceDelegate(slot, item), WatchUi.SLIDE_LEFT);
    }
}

class SettingChoiceDelegate extends WatchUi.Menu2InputDelegate {
    private var _slot as Lang.Number or Null;
    private var _parentItem as WatchUi.MenuItem;

    function initialize(slot as Lang.Number or Null, parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _slot = slot;
        _parentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var saved = _slot == null ? FaceColors.save(item.getId() as Lang.Number)
            : MetricFields.save(_slot as Lang.Number, item.getId() as Lang.String);
        if (saved) {
            _parentItem.setSubLabel(item.getLabel());
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
