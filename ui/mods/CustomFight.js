/*
 *  @Project:       Battle Brothers
 *  @Company:       Overhype Studios
 *
 *  @Copyright:     (c) Overhype Studios | 2013 - 2020
 * 
 *  @Author:        Overhype Studios
 *  @Date:          31.10.2017
 *  @Description:   World Town Screen JS
 */
"use strict";

var CustomFightScreen = function(_parent)
{
    MSUUIScreen.call(this);
    this.mModID = "mod_custom_fight"
    this.mID = "CustomFightScreen";
    this.mContainer = null;
    this.mDialogContainer = null;
    this.mDialogContentContainer = null;
    this.mNoButton = null;

    this.mSettingsBox = null;
    this.mTerrainButton = null;
    this.mMapButton = null;
    

    this.mData = null;
    this.mSettings = {
        Terrain : "",
        Map : "",
        SpectatorMode : false,
        ChopDownTrees : false,
        StartEmptyMode : false,
        ControlAllies : false,
    }

    this.mButtons = {
        Pause : {
            ID : "Pause",
            Button : null,
            Class : "l-spectator-button",  
            Paths : {
                true : "mods/ui/buttons/pause_on.png",
                false : "mods/ui/buttons/pause_off.png",
            },
            Tooltip : "CustomFight.Tactical.Topbar.Pause"
        }, 
        ManualTurns : {
            ID : "ManualTurns",
            Button : null,
            Class : "l-pause-button",
            Paths : {
                true : "mods/ui/buttons/direct_control_on.png",
                false : "mods/ui/buttons/direct_control_off.png",
            },
            Tooltip : "CustomFight.Tactical.Topbar.ManualTurns"
        }, 
        FOV : {
            ID : "FOV",
            Button : null,
            Class : "l-fov-button",
            Paths : {
                true : "mods/ui/buttons/fov_off.png",
                false : "mods/ui/buttons/fov_on.png",
            },
            Tooltip : "CustomFight.Tactical.Topbar.FOV"
        }, 
        UnlockCamera : {
            ID : "UnlockCamera",
            Button : null,
            Class : "l-camera-button",
            Paths : {
                true : "mods/ui/buttons/camera_on.png",
                false : "mods/ui/buttons/camera_off.png",
            },
            Tooltip : "CustomFight.Tactical.Topbar.UnlockCamera"
        }, 
    }
}

CustomFightScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(CustomFightScreen.prototype, 'constructor', {
    value: CustomFightScreen,
    enumerable: false,
    writable: true
});

CustomFightScreen.prototype.createDIV = function (_parentDiv)
{
    var self = this;

    // create: containers (init hidden!)
    this.mContainer = $('<div class="dialog-screen ui-control dialog-mod display-none opacity-none custom-fight"/>');
    _parentDiv.append(this.mContainer);

    // create: dialog container
    var dialogLayout = $('<div class="custom-fight-container-layout"/>');
    this.mContainer.append(dialogLayout);
    this.mDialogContainer = dialogLayout.createDialog('Custom Fight', null, null, false);
    this.mDialogContentContainer = this.mDialogContainer.findDialogContentContainer();

    // create footer button bar
    var footerButtonBar = $('<div class="l-button-bar"></div>');
    this.mDialogContainer.findDialogFooterContainer().append(footerButtonBar);

    // create: buttons
    var layout = $('<div class="l-ok-button"/>');
    footerButtonBar.append(layout);
    this.mStartButton = layout.createTextButton("Start custom fight", function ()
    {
        self.notifyBackendOkButtonPressed();
    }, 'custom-fight-text-button', 4);
    this.mStartButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Main.Start"});
    
    var layout = $('<div class="l-cancel-button"/>');
    footerButtonBar.append(layout);
    this.mNoButton = layout.createTextButton("Cancel", function ()
    {
        self.notifyBackendCancelButtonPressed();
    }, 'custom-fight-text-button', 4);
    this.mNoButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Main.Cancel"});

    var layout = $('<div class="l-cancel-button"/>');
    footerButtonBar.append(layout);
    this.mResetButton = layout.createTextButton("Reset", function ()
    {
        self.initialiseValues();
    }, 'custom-fight-text-button', 4);
    this.mResetButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Main.Reset"});

    this.mIsVisible = false;
    this.createContentDiv();
};

CustomFightScreen.prototype.destroyDIV = function ()
{    
    this.mContainer.empty();
    this.mContainer.remove();
    this.mContainer = null;
};

CustomFightScreen.prototype.createContentDiv = function()
{
    this.createSettingsDiv();
    this.mLeftSideSetupBox = this.createSideDiv("left-side", "Allies");
    this.mRightSideSetupBox = this.createSideDiv("right-side", "Enemies");
}

CustomFightScreen.prototype.createSettingsDiv = function()
{
    var self = this;
    this.mSettingsBox = $('<div class="settings-box"/>');
    this.mDialogContentContainer.append(this.mSettingsBox);
    this.addRow(this.mSettingsBox).append(this.getTextDiv("Settings", "label"));

    var terrainRow = this.addRow(this.mSettingsBox);
    terrainRow.append(this.getTextDiv("Terrain", "label"));
    this.mTerrainButton = terrainRow.createTextButton("", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Terrain','generic-popup', 'generic-popup-container'), _div, this.mData.AllBaseTerrains, "Terrain")
    }, this), "custom-fight-text-button", 4);
    this.mTerrainButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Settings.Terrain"});

    var mapRow = this.addRow(this.mSettingsBox);
    mapRow.append(this.getTextDiv("Map", "label"));
    this.mMapButton = mapRow.createTextButton("", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Map','generic-popup', 'generic-popup-container'), _div, this.mData.AllLocationTerrains, "Map")
    }, this), "custom-fight-text-button", 4);
    this.mMapButton.mousedown(function(_event){
        if(_event.which == 3)
        {
            $(this).changeButtonText("");
            self.mSettings.Map = "";
        }
    });
    this.mMapButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Settings.Map"});

    var addCheckboxSetting = $.proxy(function(_id, _settingKey, _default, _name)
    {
        var checkboxRow = this.addRow(this.mSettingsBox);
        var checkbox = checkboxRow.append($('<input type="checkbox" id="' + _id + '" />')).iCheck({
            checkboxClass: 'icheckbox_flat-orange',
            radioClass: 'iradio_flat-orange',
            increaseArea: '30%'
        });
        checkbox.on('ifChecked ifUnchecked', null, this, function (_event) {
            console.error("toggled " + _settingKey + $(this).prop("checked"))
            self.mSettings[_settingKey] = $(this).prop("checked")
        });
        checkbox.iCheck(_default);
        checkboxRow.append($('<label class="text-font-normal font-color-subtitle bool-checkbox-label" for="' + _id + '">' + _name + '</label>'))
        return checkbox;
    }, this)

    this.mSpectatorModeCheck = addCheckboxSetting("use-player-checkbox", "SpectatorMode", "uncheck", "Spectator Mode")
    this.mChopDownTreesCheck = addCheckboxSetting("chop-down-trees-checkbox", "ChopDownTrees", "uncheck", "Chop down trees");
    this.mControlAlliesCheck = addCheckboxSetting("chop-down-trees-checkbox", "ControlAllies", "uncheck", "Control allies");
}

// creates a generic popup that lists entries in an array
CustomFightScreen.prototype.createArrayScrollContainer = function(_dialog, _div, _array, _setting)
{
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(_array, $.proxy(function(_key, _unit){
        if(_unit == "") return
        var row = this.addRow(scrollContainer);

        var name = $('<div class="title-font-normal font-color-brother-name custom-fight-entry-label">' + _unit +  '</div>');
        row.append(name);


        var addButtonContainer = $('<div class="custom-fight-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Choose", $.proxy(function(_button){
            _div.changeButtonText(_unit)
            this.mSettings[_setting] = _unit;
        }, this), "custom-fight-text-button", 4);
        row.append(addButtonContainer);
    }, this))
}

CustomFightScreen.prototype.createSideDiv = function(_side, _name)
{
    var self = this;
    var ret = $('<div class="setup-box"/>');
    this.mDialogContentContainer.append(ret);
    ret.addClass(_side);
    this.addRow(ret).append(this.getTextDiv(_name, "box-title"));

    var spawnlistBox = $('<div class="spawnlist-box"/>');
    ret.append(spawnlistBox);
    this.addRow(spawnlistBox).append(this.getTextDiv("Spawnlist", "box-subtitle"));
    
    var listHeader = this.addRow(spawnlistBox, "unit-box-list-headers")
    listHeader.append(this.getTextDiv("Type"))
    listHeader.append(this.getTextDiv("Resources", "short-input-container"))

    var spawnlistBoxList = spawnlistBox.createList(2);
    ret.spawnlistScrollContainer = spawnlistBoxList.findListScrollContainer();

    var unitsBox = $('<div class="units-box"/>');
    unitsBox.append(this.getTextDiv("Units", "box-subtitle"))
    ret.append(unitsBox);
    var listHeader = this.addRow(unitsBox)
    listHeader.append(this.getTextDiv("Type"))
    listHeader.append(this.getTextDiv("Amount", "short-input-container"))
    listHeader.append(this.getTextDiv("Champion"))

    var unitsBoxList = unitsBox.createList(2);
    ret.unitsScrollContainer = unitsBoxList.findListScrollContainer();

    var buttonBar = $('<div class="button-bar-box"/>');
    ret.append(buttonBar);
    ret.buttons = {};

    var layout = $('<div class="custom-fight-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addUnitButton = layout.createTextButton("Add Unit", $.proxy(function(_div){
        this.createAddUnitScrollContainer(this.createPopup('Add Unit','generic-popup', 'generic-popup-container'), ret.unitsScrollContainer);
    }, this), "custom-fight-text-button", 4);
    ret.buttons.addUnitButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Units.Main.Add"});

    layout = $('<div class="custom-fight-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addSpawnlistButton = layout.createTextButton("Add Spawnlist", $.proxy(function(_div){
        this.createAddSpawnlistScrollContainer(this.createPopup('Add Spawnlist','generic-popup', 'generic-popup-container'), ret.spawnlistScrollContainer);
    }, this), "custom-fight-text-button", 4);
    ret.buttons.addSpawnlistButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Spawnlist.Main.Add"});
    return ret;
}

CustomFightScreen.prototype.createAddUnitScrollContainer = function(_dialog, _side)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));

    MSU.iterateObject(this.mData.AllUnits, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "unit-row");

        var name = $('<div class="title-font-normal font-color-brother-name custom-fight-entry-label">' + _unit.Name +  '</div>');
        row.append(name);

        var addButtonContainer = $('<div class="custom-fight-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addUnitToBox(_unit, _side, _key);
        }, self), "custom-fight-text-button", 4);
        addButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Units.Main.Add"});

        row.append(addButtonContainer);
    }, this))
}

CustomFightScreen.prototype.addUnitToBox = function(_unit, _side, _key)
{
    var row = this.addRow(_side);
    row.data("unitID", _key);
    row.data("unit", _unit);

    var name = $('<div class="title-font-normal font-color-brother-name custom-fight-entry-label">' + _unit.Name +  '</div>');
    row.append(name);
    name.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Units.Main.Type"});

    var amountInputLayout = $('<div class="short-input-container"/>');
    row.append(amountInputLayout);
    var amountInput = $('<input type="text" class="title-font-normal font-color-brother-name short-input"/>');
    amountInputLayout.append(amountInput);
    amountInput.val(1);
    row.data("amount", amountInput);
    amountInput.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Units.Main.Amount"});

    var checkbox = row.append($('<input type="checkbox" id="champion-checkbox"/>')).iCheck({
        checkboxClass: 'icheckbox_flat-orange',
        radioClass: 'iradio_flat-orange',
        increaseArea: '30%'
    });
    row.data("champion", checkbox);
    var label = row.append($('<label class="text-font-normal font-color-subtitle bool-checkbox-label" for="bool-checkbox-label">Champion</label>'))


    var destroyButtonLayout = $('<div class="delete-button-container"/>');
    row.append(destroyButtonLayout);
    var destroyButton = destroyButtonLayout.createTextButton("Delete", function()
    {
        row.remove();
    }, '', 2);
    destroyButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Units.Main.Delete"});
}

CustomFightScreen.prototype.createAddSpawnlistScrollContainer = function(_dialog, _boxDiv)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(this.mData.AllSpawnlists, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "unit-row");
        var name = $('<div class="title-font-normal font-color-brother-name custom-fight-entry-label">' + _unit.id +  '</div>');
        row.append(name);
        var addButtonContainer = $('<div class="custom-fight-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addSpawnlistToBox(_unit, _boxDiv);
        }, self), "custom-fight-text-button", 4);
        row.append(addButtonContainer);
    }, this))
}

CustomFightScreen.prototype.addSpawnlistToBox = function(_unit, _boxDiv)
{
    var row = this.addRow(_boxDiv);
    row.data("unitID", _unit.id);
    row.data("unit", _unit);

    var name = this.getTextDiv(_unit.id);
    row.append(name);
    name.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Spawnlist.Main.Type"});

    var amountInputLayout = $('<div class="short-input-container"/>');
    row.append(amountInputLayout);
    var amountInput = $('<input type="text" class="title-font-normal font-color-brother-name short-input"/>');
    amountInputLayout.append(amountInput);
    amountInput.val(100);
    row.data("amount", amountInput);
    amountInput.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Spawnlist.Main.Resources"});

    var destroyButtonLayout = $('<div class="delete-button-container"/>');
    row.append(destroyButtonLayout);
    var destroyButton = destroyButtonLayout.createTextButton("Delete", function()
    {
        row.remove();
    }, '', 2);
    destroyButton.bindTooltip({ contentType: 'ui-element', elementId: "CustomFight.Screen.Spawnlist.Main.Delete"});
}

CustomFightScreen.prototype.createPopup = function(_name, _popupClass, _popupDialogContentClass)
{
    var self = this;
    this.popup = this.mContainer.createPopupDialog(_name, "", null, _popupClass);
    this.setPopupDialog(this.popup);
    var result = this.popup.addPopupDialogContent($('<div class="' + _popupDialogContentClass + '"/>'));
    this.popup.addPopupDialogButton('OK', 'l-ok-keybind-button', $.proxy(function(_dialog)
    {
        this.destroyPopupDialog();
    }, this));
    return result;
}

CustomFightScreen.prototype.createFilterBar = function(_scrollContainer)
{
    var row = $('<div class="row filter-bar"/>');
    var name = this.getTextDiv("Filter");
    row.append(name);
    var filterLayout = $('<div class="short-input-container"/>');
    row.append(filterLayout);
    var filterInput = $('<input type="text" class="title-font-normal font-color-brother-name short-input"/>');
    filterLayout.append(filterInput);
    filterInput.on("keyup", function(_event){
        var currentInput = $(this).val();
        var rows = _scrollContainer.find(".row");
        rows.each(function(_idx){
            var label = $(this).find(".custom-fight-entry-label");
            if (label.length == 0) return;
            var labelText = $(label[0]).html();
            if (labelText.toLowerCase().search(currentInput.toLowerCase()) == -1)
            {
                $(this).css("display", "none")
            }
            else
            {
                $(this).css("display", "flex")
            }
        })
    })
    return row;
}

CustomFightScreen.prototype.addRow = function(_div, _classes)
{
    var row = $('<div class="row"/>');
    _div.append(row);
    if (_classes != undefined)
    {
        row.addClass(_classes);
    }
    return row;
}

CustomFightScreen.prototype.getTextDiv = function(_text, _classes)
{
    var row = $('<div class="title-font-normal font-color-brother-name custom-fight-entry-label"></div>')
    row.html(_text);
    if(_classes != undefined && _classes != null) row.addClass(_classes);
    return row;
}

CustomFightScreen.prototype.setData = function (_data)
{    
    this.mData = _data;
    this.initialiseValues();
};

CustomFightScreen.prototype.initialiseValues = function (_data)
{  
    this.mTerrainButton.changeButtonText(this.mData.AllBaseTerrains[1]);
    this.mSettings.Terrain = this.mData.AllBaseTerrains[1];

    this.mMapButton.changeButtonText("");
    this.mSettings.Map = "";

    this.mSpectatorModeCheck.iCheck('uncheck');
    this.mSettings.SpectatorMode = false;

    this.mChopDownTreesCheck.iCheck('uncheck');
    this.mSettings.ChopDownTrees = false;

    this.mLeftSideSetupBox.spawnlistScrollContainer.empty();
    this.mRightSideSetupBox.spawnlistScrollContainer.empty();
    this.mLeftSideSetupBox.unitsScrollContainer.empty();
    this.mRightSideSetupBox.unitsScrollContainer.empty();

    this.testThings()
};

CustomFightScreen.prototype.testThings = function ()
{  
    var randomProperty = function (obj) {
        var keys = Object.keys(obj);
        return obj[keys[ keys.length * Math.random() << 0]];
    };
    this.addSpawnlistToBox(randomProperty(this.mData.AllSpawnlists), this.mRightSideSetupBox.spawnlistScrollContainer)
    this.addSpawnlistToBox(randomProperty(this.mData.AllSpawnlists), this.mLeftSideSetupBox.spawnlistScrollContainer)
}

CustomFightScreen.prototype.gatherData = function()
{
    var ret = {
        Settings : this.mSettings,
        Player : {
            Spawnlists : [],
            Units : [],
        },
        Enemy : {
            Spawnlists : [],
            Units : [],
        },
    };
    this.gatherUnits(ret.Player, this.mLeftSideSetupBox);
    this.gatherUnits(ret.Enemy, this.mRightSideSetupBox);
    this.checkStartEmptyMode(ret);

    return ret;
}

CustomFightScreen.prototype.gatherUnits = function(_ret, _div)
{
    var spawnlistRows = _div.spawnlistScrollContainer.find(".row")
    spawnlistRows.each(function(_idx){
        _ret.Spawnlists.push({
            ID : $(this).data("unitID"),
            Resources : $(this).data("amount").val()
        })
    })

    var unitRows = _div.unitsScrollContainer.find(".row")
    unitRows.each(function(_idx){
        _ret.Units.push({
            Type : $(this).data("unitID"),
            Num : $(this).data("amount").val(),
            Champion : $(this).data("champion").prop("checked")
        })
    })
    // ret.unitsScrollContainer
    // row.amount
}

CustomFightScreen.prototype.checkStartEmptyMode = function(_ret)
{
    if (_ret.Player.Spawnlists.length == 0 && _ret.Player.Units.length == 0 && _ret.Enemy.Spawnlists.length == 0 && _ret.Enemy.Units.length == 0)
    {
        _ret.Settings.StartEmptyMode = true;
    }
}

CustomFightScreen.prototype.notifyBackendTopBarButtonPressed = function (_buttonType)
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onTopBarButtonPressed', _buttonType);
    }
};

CustomFightScreen.prototype.setTopBarButtonState = function (_data)
{
    var button = this.mButtons[_data[0]];
    button.Button.changeButtonImage(Path.GFX + button.Paths[_data[1].toString()]);
    // if the button was clicked, refresh tooltip
    if(_data[2]) button.Button.trigger('update-tooltip' + TooltipModuleIdentifier.KeyEvent.Namespace)
};

CustomFightScreen.prototype.notifyBackendOkButtonPressed = function ()
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onOkButtonPressed', this.gatherData());
    }
};

CustomFightScreen.prototype.notifyBackendCancelButtonPressed = function ()
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onCancelButtonPressed');
    }
};

registerScreen("CustomFightScreen", new CustomFightScreen());

