"use strict";
var CombatSimulator = {
    ModID : "mod_combat_simulator"
}

var CombatSimulatorScreen = function(_parent)
{
    MSUUIScreen.call(this);
    this.mModID = "mod_combat_simulator"
    this.mID = "CombatSimulatorScreen";
    this.mContainer = null;
    this.mDialogContainer = null;
    this.mDialogContentContainer = null;
    this.mNoButton = null;

    this.mSettingsBox = null;
    this.mTerrainButton = null;
    this.mMapButton = null;

    this.mFactions = {};
    this.mFactionNum = 0;
    this.mNextFactionID = 0;
    this.mFactionsIdx = 0;
    

    this.mData = null;
    this.mSettings = {
        Terrain : "tactical.plains",
        Map : "",
        MusicTrack : "BanditTracks",
        SpectatorMode : false,
        CutDownTrees : false,
        StartEmptyMode : true,
        ControlAllies : false,
        IsFleeingProhibited : false,
        Fortification : false,
    }

    this.mTopBarButtons = {
        Pause : {
            ID : "Pause",
            Button : null,
            Layout : null,
            Paths : {
                true : "mods/ui/buttons/pause_on.png",
                false : "mods/ui/buttons/pause_off.png",
            },
            Tooltip : "Tactical.Topbar.Pause"
        }, 
        ManualTurns : {
            ID : "ManualTurns",
            Button : null,
            Layout : null,
            Paths : {
                true : "mods/ui/buttons/direct_control_on.png",
                false : "mods/ui/buttons/direct_control_off.png",
            },
            Tooltip : "Tactical.Topbar.ManualTurns"
        }, 
        FOV : {
            ID : "FOV",
            Button : null,
            Layout : null,
            Paths : {
                true : "mods/ui/buttons/fov_off.png",
                false : "mods/ui/buttons/fov_on.png",
            },
            Tooltip : "Tactical.Topbar.FOV"
        }, 
        UnlockCamera : {
            ID : "UnlockCamera",
            Button : null,
            Layout : null,
            Paths : {
                true : "mods/ui/buttons/camera_on.png",
                false : "mods/ui/buttons/camera_off.png",
            },
            Tooltip : "Tactical.Topbar.UnlockCamera"
        }, 
        FinishFight : {
            ID : "FinishFight",
            Button : null,
            Layout : null,
            Paths : {
                true : 'ui/skin/icon_cross.png',
                false : 'ui/skin/icon_cross.png',
            },
            Tooltip : "Tactical.Topbar.FinishFight"
        }, 
    }
}

CombatSimulatorScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(CombatSimulatorScreen.prototype, 'constructor', {
    value: CombatSimulatorScreen,
    enumerable: false,
    writable: true
});

CombatSimulatorScreen.prototype.createDIV = function (_parentDiv)
{
    var self = this;

    // create: containers (init hidden!)
    this.mContainer = $('<div class="dialog-screen ui-control display-none opacity-none combat-simulator"/>');
    _parentDiv.append(this.mContainer);

    // create: dialog container
    var dialogLayout = $('<div class="combat-simulator-container-layout"/>');
    this.mContainer.append(dialogLayout);
    this.mDialogContainer = dialogLayout.createDialog('Combat Simulator', null, null, false);
    this.mDialogContentContainer = this.mDialogContainer.findDialogContentContainer();


    this.mHeaderContainer = this.mDialogContainer.find("text-container:first");


    // create footer button bar
    var footerButtonBar = $('<div class="l-button-bar"></div>');
    this.mDialogContainer.findDialogFooterContainer().append(footerButtonBar);

    // create: buttons
    var layout = $('<div class="l-ok-button"/>');
    footerButtonBar.append(layout);
    this.mStartButton = layout.createTextButton("Start Battle", function ()
    {
        self.notifyBackendOkButtonPressed();
    }, 'combat-simulator-text-button', 4);
    this.mStartButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Main.Start"});
    
    var layout = $('<div class="l-cancel-button"/>');
    footerButtonBar.append(layout);
    this.mNoButton = layout.createTextButton("Cancel", function ()
    {
        self.notifyBackendCancelButtonPressed();
    }, 'combat-simulator-text-button', 4);
    this.mNoButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Main.Cancel"});

    var layout = $('<div class="l-cancel-button"/>');
    footerButtonBar.append(layout);
    this.mResetButton = layout.createTextButton("Reset", function ()
    {
        self.reset();
    }, 'combat-simulator-text-button', 4);
    this.mResetButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Main.Reset"});

    this.mIsVisible = false;
    this.createContentDiv();
};

CombatSimulatorScreen.prototype.destroyDIV = function ()
{    
    this.mContainer.empty();
    this.mContainer.remove();
    this.mContainer = null;
};

CombatSimulatorScreen.prototype.createContentDiv = function()
{
    this.createSettingsDiv();
    this.createFactionDiv("Allies", "faction-0");
    this.mFactions["faction-0"].data("alliedToPlayerCheckbox").iCheck('check');
    this.createFactionDiv("Enemies", "faction-1");
}

CombatSimulatorScreen.prototype.createSettingsDiv = function()
{
    var self = this;
    this.mSettingsBox = $('<div class="settings-box"/>');
    this.mDialogContentContainer.append(this.mSettingsBox);
    this.addRow(this.mSettingsBox).append(this.getTextDiv("Settings", "label"));

    var switchFactionRow = this.addRow(this.mSettingsBox)
    switchFactionRow.append(this.getTextDiv("Switch faction", "label"));
    this.mFactionButtonContainer =  $('<div class="faction-button-container"/>').appendTo(switchFactionRow);
    var buttonLayout = $('<div class="l-button"/>');
    this.mFactionButtonContainer.append(buttonLayout);
    var button = buttonLayout.createImageButton(Path.GFX + "mods/ui/buttons/switch_previous_faction.png", function ()
    {
        self.switchFaction(-1);
    }, "", 3);

    var buttonLayout = $('<div class="l-button"/>');
    this.mFactionButtonContainer.append(buttonLayout);
    var button = buttonLayout.createImageButton(Path.GFX + "mods/ui/buttons/switch_next_faction.png", function ()
    {
        self.switchFaction(1);
    }, "", 3);

    var addFactionRow = this.addRow(this.mSettingsBox)
    addFactionRow.append(this.getTextDiv("Add faction", "label"));
    var layout = $('<div class="combat-simulator-text-button-layout"/>');
    addFactionRow.append(layout);
    var button = layout.createTextButton("", $.proxy(function(_div){
        self.createFactionDiv();
        self.switchFaction(1);
    }, this), "combat-simulator-text-button", 4);


    var terrainRow = this.addRow(this.mSettingsBox);
    terrainRow.append(this.getTextDiv("Terrain", "label"));
    this.mTerrainButton = terrainRow.createTextButton("tactical.plains", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Terrain','generic-popup', 'generic-popup-container'), _div, this.mData.AllBaseTerrains, "Terrain")
    }, this), "combat-simulator-text-button", 4);
    this.mTerrainButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Settings.Terrain", test: "hello, world"});

    var mapRow = this.addRow(this.mSettingsBox);
    mapRow.append(this.getTextDiv("Map", "label"));
    this.mMapButton = mapRow.createTextButton("", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Map','generic-popup', 'generic-popup-container'), _div, this.mData.AllLocationTerrains, "Map")
    }, this), "combat-simulator-text-button", 4);
    this.mMapButton.mousedown(function(_event){
        if(_event.which == 3)
        {
            $(this).changeButtonText("");
            self.mSettings.Map = "";
        }
    });
    this.mMapButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Settings.Map"});

    var trackRow = this.addRow(this.mSettingsBox);
    trackRow.append(this.getTextDiv("Music Track", "label"));
    this.mTrackButton = trackRow.createTextButton("BanditTracks", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Music Track','generic-popup', 'generic-popup-container'), _div, this.mData.AllMusicTracks, "MusicTrack")
    }, this), "combat-simulator-text-button", 4);

    this.mTrackButton.mousedown(function(_event){
        if(_event.which == 3)
        {
            $(this).changeButtonText("");
            self.mSettings.MusicTrack = "";
        }
    });
    this.mTrackButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Settings.Music"});

    this.mSpectatorModeCheck = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "use-player-checkbox", "SpectatorMode", "uncheck", "Spectator Mode")
    this.mCutDownTreesCheck = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "cut-down-trees-checkbox", "CutDownTrees", "uncheck", "Chop down trees");
    this.mControlAlliesCheck = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "control-allies-checkbox", "ControlAllies", "uncheck", "Control allies");
    this.mIsFleeingProhibitedCheck = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "fleeing-prohibited-checkbox", "IsFleeingProhibited", "uncheck", "Disallow fleeing");
    this.mFortificationCheck = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "fortification-checkbox", "Fortification", "uncheck", "Add fortification");

}
CombatSimulatorScreen.prototype.switchFaction = function(_idx)
{
    var self = this;
    var clamp = function(num, min, max){
        return Math.min(Math.max(num, min), max);
    }
    this.mFactionsIdx = clamp(this.mFactionsIdx + _idx, 0, this.mFactionNum-2);
    console.error(this.mFactionsIdx)
    var idx = 0;
    $(".setup-box").css("display", "none");
    MSU.iterateObject(this.mFactions, function(_id, _faction){
        if(idx >= self.mFactionsIdx && idx < self.mFactionsIdx+2) _faction.css("display", "flex");
        idx++
    })
} 
CombatSimulatorScreen.prototype.addCheckboxSetting = function(_div, _id, _settingKey, _default, _name)
{
    var self = this
    var checkboxContainer = $('<div class="checkbox-container"/>');
    _div.append(checkboxContainer)
    var checkbox = $('<input type="checkbox" id="' + _id + '" />').appendTo(checkboxContainer).iCheck({
        checkboxClass: 'icheckbox_flat-orange',
        radioClass: 'iradio_flat-orange',
        increaseArea: '30%'
    });

    if(_settingKey != null)
    {
        checkbox.on('ifChecked ifUnchecked', null, this, function (_event) {
            self.mSettings[_settingKey] = $(this).prop("checked")
        });
    }
    
    var label = $('<label class="text-font-normal font-color-subtitle bool-checkbox-label" for="' + _id + '">' + _name + '</label>');
    checkboxContainer.append(label)
    label.click(function(){
        checkbox.iCheck('toggle');
    })
    checkbox.iCheck(_default);
    if(_settingKey != null) checkboxContainer.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Settings." + _settingKey});
    return checkbox;
}

// creates a generic popup that lists entries in an array
CombatSimulatorScreen.prototype.createArrayScrollContainer = function(_dialog, _div, _array, _setting)
{
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(_array, $.proxy(function(_key, _unit){
        if(_unit == "") return
        var row = this.addRow(scrollContainer, "", true);

        var name = $('<div class="title-font-normal font-color-brother-name combat-simulator-entry-label">' + _unit +  '</div>');
        row.append(name);


        var addButtonContainer = $('<div class="combat-simulator-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Choose", $.proxy(function(_button){
            _div.changeButtonText(_unit)
            this.mSettings[_setting] = _unit;
        }, this), "combat-simulator-text-button", 4);
        row.append(addButtonContainer);
    }, this))
}

CombatSimulatorScreen.prototype.createFactionDiv = function()
{
    var self = this;
    var ret = $('<div class="setup-box"/>');
    var nextFactionID = this.mNextFactionID++;
    var id = "faction-" + nextFactionID;
    this.mFactionNum++;


    ret.data("id", id);
    ret.data("alliedFactionCheckboxes", {});
    this.mDialogContentContainer.append(ret);
    var headerRow = this.addRow(ret)
    headerRow.append(this.getTextDiv("Faction " + nextFactionID, "box-title"));
    var alliedToPlayerCheckbox = this.addCheckboxSetting(headerRow, "AlliedToPlayer" + id, null, "uncheck", "Allied to player");
    ret.data("alliedToPlayerCheckbox", alliedToPlayerCheckbox);

    var controlUnitsCheckbox = this.addCheckboxSetting(headerRow, "ControlUnits" + id, null, "uncheck", "Control Units");
    ret.data("controlUnitsCheckbox", controlUnitsCheckbox);

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

    var layout = $('<div class="combat-simulator-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addUnitButton = layout.createTextButton("Add Unit", $.proxy(function(_div){
        this.createAddUnitScrollContainer(this.createPopup('Add Unit','generic-popup', 'generic-popup-container'), ret.unitsScrollContainer);
    }, this), "combat-simulator-text-button", 4);
    ret.buttons.addUnitButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Add"});

    layout = $('<div class="combat-simulator-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addSpawnlistButton = layout.createTextButton("Add Spawnlist", $.proxy(function(_div){
        this.createAddSpawnlistScrollContainer(this.createPopup('Add Spawnlist','generic-popup', 'generic-popup-container'), ret.spawnlistScrollContainer);
    }, this), "combat-simulator-text-button", 4);
    ret.buttons.addSpawnlistButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Spawnlist.Main.Add"});


    this.mFactions[id] = ret;
}

CombatSimulatorScreen.prototype.removeFactionDiv = function (_id)
{
    this.mFactions[_id].remove();
    delete this.mFactions[_id];
    this.mFactionNum--;
}

CombatSimulatorScreen.prototype.createAddUnitScrollContainer = function(_dialog, _side)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));

    MSU.iterateObject(this.mData.AllUnits, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "", true);

        var name = $('<div class="title-font-normal font-color-brother-name combat-simulator-entry-label">' + _unit.DisplayName +  '</div>');
        row.append(name);

        var addButtonContainer = $('<div class="combat-simulator-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addUnitToBox(_unit, _side, _key);
        }, self), "combat-simulator-text-button", 4);
        addButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Add"});

        row.append(addButtonContainer);
    }, this))
}

CombatSimulatorScreen.prototype.addUnitToBox = function(_unit, _side, _key)
{
    var row = this.addRow(_side, "", true);
    row.data("unitID", _key);
    row.data("unit", _unit);

    var name = $('<div class="title-font-normal font-color-brother-name combat-simulator-entry-label">' + _unit.DisplayName +  '</div>');
    row.append(name);
    name.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Type"});

    var amountInputLayout = $('<div class="short-input-container"/>');
    row.append(amountInputLayout);
    var amountInput = $('<input type="text" class="title-font-normal font-color-brother-name short-input"/>');
    amountInputLayout.append(amountInput);
    amountInput.val(1);
    row.data("amount", amountInput);
    amountInput.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Amount"});

    var checkbox = this.addCheckboxSetting(row, "champion-checkbox", null, "uncheck", "Champion")
    checkbox.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Champion"})
    row.data("champion", checkbox);

    var destroyButtonLayout = $('<div class="delete-button-container"/>');
    row.append(destroyButtonLayout);
    var destroyButton = destroyButtonLayout.createTextButton("Delete", function()
    {
        row.remove();
    }, '', 2);
    destroyButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Delete"});
}

CombatSimulatorScreen.prototype.createAddSpawnlistScrollContainer = function(_dialog, _boxDiv)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(this.mData.AllSpawnlists, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "", true);
        var name = $('<div class="title-font-normal font-color-brother-name combat-simulator-entry-label">' + _unit.id +  '</div>');
        row.append(name);
        var addButtonContainer = $('<div class="combat-simulator-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addSpawnlistToBox(_unit, _boxDiv);
        }, self), "combat-simulator-text-button", 4);
        row.append(addButtonContainer);
    }, this))
}

CombatSimulatorScreen.prototype.addSpawnlistToBox = function(_unit, _boxDiv)
{
    var row = this.addRow(_boxDiv, "", true);
    row.data("unitID", _unit.id);
    row.data("unit", _unit);

    var name = this.getTextDiv(_unit.id);
    row.append(name);
    name.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Spawnlist.Main.Type"});

    var amountInputLayout = $('<div class="short-input-container"/>');
    row.append(amountInputLayout);
    var amountInput = $('<input type="text" class="title-font-normal font-color-brother-name short-input"/>');
    amountInputLayout.append(amountInput);
    amountInput.val(100);
    row.data("amount", amountInput);
    amountInput.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Spawnlist.Main.Resources"});

    var destroyButtonLayout = $('<div class="delete-button-container"/>');
    row.append(destroyButtonLayout);
    var destroyButton = destroyButtonLayout.createTextButton("Delete", function()
    {
        row.remove();
    }, '', 2);
    destroyButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Spawnlist.Main.Delete"});
}

CombatSimulatorScreen.prototype.createPopup = function(_name, _popupClass, _popupDialogContentClass)
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

CombatSimulatorScreen.prototype.createFilterBar = function(_scrollContainer)
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
            var label = $(this).find(".combat-simulator-entry-label");
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

CombatSimulatorScreen.prototype.addRow = function(_div, _classes, _divider)
{
    var row = $('<div class="combat-simulator-row"/>');
    _div.append(row);
    if (_classes != undefined)
    {
        row.addClass(_classes);
    }
    if(_divider === true)
    {
        row.addClass("bottom-gold-line");
    }
    return row;
}

CombatSimulatorScreen.prototype.getTextDiv = function(_text, _classes)
{
    var row = $('<div class="title-font-normal font-color-brother-name combat-simulator-entry-label"></div>')
    row.html(_text);
    if(_classes != undefined && _classes != null) row.addClass(_classes);
    return row;
}

CombatSimulatorScreen.prototype.setData = function (_data)
{    
    this.mData = _data;
    // this.testThings()
};

CombatSimulatorScreen.prototype.initialiseValues = function ()
{  
    this.mTerrainButton.changeButtonText(this.mData.AllBaseTerrains[1]);
    this.mSettings.Terrain = this.mData.AllBaseTerrains[1];

    this.mTrackButton.changeButtonText(this.mData.AllMusicTracks[0]);
    this.mSettings.MusicTrack = this.mData.AllMusicTracks[0];

    this.mMapButton.changeButtonText("");
    this.mSettings.Map = "";

    this.mSpectatorModeCheck.iCheck('uncheck');
    this.mCutDownTreesCheck.iCheck('uncheck');
    this.mControlAlliesCheck.iCheck('uncheck');
    this.mIsFleeingProhibitedCheck.iCheck('uncheck');
    this.mFortificationCheck.iCheck('uncheck');
}

CombatSimulatorScreen.prototype.reset = function()
{
    var self = this;
    this.initialiseValues();
    this.mFactions["faction-0"].spawnlistScrollContainer.empty();
    this.mFactions["faction-1"].spawnlistScrollContainer.empty();
    this.mFactions["faction-0"].unitsScrollContainer.empty();
    this.mFactions["faction-1"].unitsScrollContainer.empty();

    MSU.iterateObject(this.mFactions, function(_id, _div)
    {
        if (_id != "faction-0" && _id != "faction-1")
        {
            self.removeFactionDiv(_id);
        }
    })
}

CombatSimulatorScreen.prototype.testThings = function ()
{  
    var randomProperty = function (obj) {
        var keys = Object.keys(obj);
        return obj[keys[ keys.length * Math.random() << 0]];
    };
    this.addSpawnlistToBox(randomProperty(this.mData.AllSpawnlists), this.mFactions["faction-0"].spawnlistScrollContainer)
    this.addSpawnlistToBox(randomProperty(this.mData.AllSpawnlists), this.mFactions["faction-1"].spawnlistScrollContainer)
}

CombatSimulatorScreen.prototype.gatherData = function()
{
    var self = this;
    var ret = {
        Settings : this.mSettings,
        Factions : []
    };

    MSU.iterateObject(this.mFactions, function(_id, _faction){
        self.getFactionData(ret, _faction);
    })
    // this.checkStartEmptyMode(ret);
    console.error(JSON.stringify(ret))
    return ret;
}

CombatSimulatorScreen.prototype.getFactionData = function(_ret, _div)
{
    console.error("getFactionData")
    var ret = {
        Spawnlists : [],
        Units : [],
        Settings : {
            AlliedFactions : [],
            AlliedToPlayer : false,
            ControlUnits : false,
        },
    }
    var spawnlistRows = _div.spawnlistScrollContainer.find(".row")
    spawnlistRows.each(function(_idx){
        ret.Spawnlists.push({
            ID : $(this).data("unitID"),
            Resources : $(this).data("amount").val()
        })
    })

    var unitRows = _div.unitsScrollContainer.find(".row")
    unitRows.each(function(_idx){
        ret.Units.push({
            Type : $(this).data("unitID"),
            Num : $(this).data("amount").val(),
            Champion : $(this).data("champion").prop("checked")
        })
    })

    if (_div.data("alliedToPlayerCheckbox").prop("checked"))
        ret.Settings.AlliedToPlayer = true;

    if (_div.data("controlUnitsCheckbox").prop("checked"))
        ret.Settings.ControlUnits = true;
    

    _ret.Factions.push(ret)
    // ret.unitsScrollContainer
    // row.amount
}

CombatSimulatorScreen.prototype.checkStartEmptyMode = function(_ret)
{
    _ret.Settings.StartEmptyMode = true;
    MSU.iterateObject(_ret.mFactions, function(_id, _faction){
        if (_faction.Spawnlists.length != 0 || _faction.Units.length != 0)
        {
            _ret.Settings.StartEmptyMode = false;
        }
    })
}

CombatSimulatorScreen.prototype.notifyBackendTopBarButtonPressed = function (_buttonType)
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onTopBarButtonPressed', _buttonType);
    }
};

CombatSimulatorScreen.prototype.setTopBarButtonState = function (_data)
{
    var button = this.mTopBarButtons[_data[0]];
    button.Button.changeButtonImage(Path.GFX + button.Paths[_data[1].toString()]);
    // if the button was clicked, refresh tooltip
    if(_data[2]) button.Button.trigger('update-tooltip' + TooltipModuleIdentifier.KeyEvent.Namespace)
};

CombatSimulatorScreen.prototype.setTopBarButtonsDisplay = function (_bool)
{
    MSU.iterateObject(this.mTopBarButtons, function(_key, _button){
        MSU.toggleDisplay(_button.Layout, _bool);
    })
};

CombatSimulatorScreen.prototype.notifyBackendOkButtonPressed = function ()
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onOkButtonPressed', this.gatherData());
    }
};

CombatSimulatorScreen.prototype.notifyBackendCancelButtonPressed = function ()
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onCancelButtonPressed');
    }
};

registerScreen("CombatSimulatorScreen", new CombatSimulatorScreen());

