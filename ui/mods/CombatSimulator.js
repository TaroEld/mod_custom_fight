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
    this.mMaxFactions = 4;
    this.mFactionsIdx = 0;

    this.mSettingIDCounters = {};

    this.mActiveFilterBar = null;
    

    this.mData = null;
    this.mSettings = {
        Terrain : "tactical.plains",
        Map : "",
        MusicTrack : "BanditTracks",
        SpawnCompany : true,
        CutDownTrees : false,
        StartEmptyMode : true,
        IsFleeingProhibited : false,
        Fortification : false,
    }

    this.mTopBarButtons = {
        Pause : {
            ID : "Pause",
            Button : null,
            Layout : null,
            Enabled : false,
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
            Enabled : false,
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
            Enabled : true,
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
            Enabled : false,
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
            Enabled : false,
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
    this.mContainer = $('<div class="dialog-screen ui-control display-none opacity-none combatsim"/>');
    _parentDiv.append(this.mContainer);

    // create: dialog container
    var dialogLayout = $('<div class="combatsim-container-layout"/>');
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
    }, 'combatsim-text-button', 4);
    this.mStartButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Main.Start"});
    
    var layout = $('<div class="l-cancel-button"/>');
    footerButtonBar.append(layout);
    this.mNoButton = layout.createTextButton("Cancel", function ()
    {
        self.notifyBackendCancelButtonPressed();
    }, 'combatsim-text-button', 4);
    this.mNoButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Main.Cancel"});

    var layout = $('<div class="l-cancel-button"/>');
    footerButtonBar.append(layout);
    this.mResetButton = layout.createTextButton("Reset", function ()
    {
        self.reset();
    }, 'combatsim-text-button', 4);
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
    this.createFactionDiv("Allies", "faction-0", "page-1");
    this.mFactions["faction-0"].data("alliedToPlayer", true);
    this.createFactionDiv("Faction 2", "faction-1", "page-1");
    this.createFactionDiv("Faction 3", "faction-2", "page-2");
    this.createFactionDiv("Faction 4", "faction-3", "page-2");
    this.switchFaction(0);
}

CombatSimulatorScreen.prototype.createSettingsDiv = function()
{
    var self = this;
    this.mSettingsBox = $('<div class="combatsim-settings-box"/>');
    this.mDialogContentContainer.append(this.mSettingsBox);
    this.addRow(this.mSettingsBox, "settings-header-row").append(this.getTextDiv("Settings", "label", true));

    var switchFactionRow = this.addRow(this.mSettingsBox)
    switchFactionRow.append(this.getTextDiv("Switch faction", "label"));
    this.mFactionButtonContainer =  $('<div class="combatsim-faction-button-container"/>').appendTo(switchFactionRow);
    var buttonLayout = $('<div class="l-button"/>');
    this.mFactionButtonContainer.append(buttonLayout);
    this.mFactionPreviousButton = buttonLayout.createImageButton(Path.GFX + "mods/ui/buttons/switch_previous_faction.png", function ()
    {
        self.switchFaction(0);
    }, "", 3);

    var buttonLayout = $('<div class="l-button"/>');
    this.mFactionButtonContainer.append(buttonLayout);
    this.mFactionNextButton = buttonLayout.createImageButton(Path.GFX + "mods/ui/buttons/switch_next_faction.png", function ()
    {
        self.switchFaction(1);
    }, "", 3);

    var terrainRow = this.addRow(this.mSettingsBox);
    terrainRow.append(this.getTextDiv("Terrain", "label"));
    this.mTerrainButton = terrainRow.createTextButton("tactical.plains", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Terrain','combatsim-generic-popup', 'combatsim-generic-popup-container'), _div, this.mData.AllBaseTerrains, "Terrain")
    }, this), "combatsim-text-button", 4);
    this.mTerrainButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Settings.Terrain", test: "hello, world"});

    var mapRow = this.addRow(this.mSettingsBox);
    mapRow.append(this.getTextDiv("Map", "label")); 
    this.mMapButton = mapRow.createTextButton("", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Map','combatsim-generic-popup', 'combatsim-generic-popup-container'), _div, this.mData.AllLocationTerrains, "Map")
    }, this), "combatsim-text-button", 4);
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
       this.createArrayScrollContainer(this.createPopup('Choose Music Track','combatsim-generic-popup', 'combatsim-generic-popup-container'), _div, this.mData.AllMusicTracks, "MusicTrack")
    }, this), "combatsim-text-button", 4);

    this.mTrackButton.mousedown(function(_event){
        if(_event.which == 3)
        {
            $(this).changeButtonText("");
            self.mSettings.MusicTrack = "";
        }
    });
    this.mTrackButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Settings.Music"});

    var SpawnCompanyRow = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "use-player-checkbox", "SpawnCompany", "check", "Spawn Company");
    this.mSpawnCompanyCheck = SpawnCompanyRow.checkbox;
    this.mSpawnCompanyContainer = SpawnCompanyRow.container
    this.mCutDownTreesCheck = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "cut-down-trees-checkbox", "CutDownTrees", "uncheck", "Chop down trees").checkbox;
    this.mIsFleeingProhibitedCheck = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "fleeing-prohibited-checkbox", "IsFleeingProhibited", "uncheck", "Disallow fleeing").checkbox;
    this.mFortificationCheck = this.addCheckboxSetting(this.addRow(this.mSettingsBox), "fortification-checkbox", "Fortification", "uncheck", "Add fortification").checkbox;

    var copyRow = this.addRow(this.mSettingsBox);
    copyRow.append(this.getTextDiv("Copy Setup", "label")); 
    this.mCopyButton = copyRow.createTextButton("Copy", function(_div){
        self.copyData(self.gatherData());
    }, "combatsim-text-button", 4)
    this.mCopyButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Main.Copy"});

    var pasteRow = this.addRow(this.mSettingsBox);
    pasteRow.append(this.getTextDiv("Paste Setup", "label")); 
    this.mPasteButton = pasteRow.createTextButton("Paste", function(_div){
        self.setFromString(self.pasteData());
    }, "combatsim-text-button", 4)
    this.mPasteButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Main.Paste"});

}
CombatSimulatorScreen.prototype.switchFaction = function(_idx)
{
    var self = this;
    var clamp = function(num, min, max){
        return Math.min(Math.max(num, min), max);
    }
    $(".combatsim-setup-box").css("display", "none");
    if (_idx == 0)
    {
        $(".page-1").css("display", "flex");
        this.mFactionNextButton.attr('disabled', false);
        this.mFactionPreviousButton.attr('disabled', true);
    }
    else 
    {
        $(".page-2").css("display", "flex");
        this.mFactionNextButton.attr('disabled', true);
        this.mFactionPreviousButton.attr('disabled', false);
    }
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

        var name = $('<div class="title-font-normal font-color-subtitle combatsim-entry-label">' + _unit +  '</div>');
        row.append(name);


        var addButtonContainer = $('<div class="combatsim-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Choose", $.proxy(function(_button){
            _div.changeButtonText(_unit)
            this.mSettings[_setting] = _unit;
        }, this), "combatsim-text-button", 4);
        row.append(addButtonContainer);
    }, this))
    this.focusActiveFilterBar();
}

CombatSimulatorScreen.prototype.createFactionDiv = function(_name, _id, _page)
{
    var self = this;
    var ret = $('<div class="combatsim-setup-box"/>');
    this.mFactions[_id] = ret;
    ret.addClass(_page);

    ret.data("id", _id);
    this.mDialogContentContainer.append(ret);
    var headerRow = this.addRow(ret, "faction-header")
    headerRow.append(this.getTextDiv(_name, "box-title"));

    var controlUnitsCheckbox = this.addCheckboxSetting(headerRow, "ControlUnits" + _id, null, "uncheck", "Control Units");
    controlUnitsCheckbox.container.addClass("control-unit-checkbox");
    ret.data("controlUnitsCheckbox", controlUnitsCheckbox.checkbox);
    controlUnitsCheckbox.checkbox.on('ifChecked ifUnchecked', null, this, function (_event) {
        self.notifyBackendUpdateFactionProperty(_id, "ControlUnits", $(this).prop("checked"))
    });

    var spawnlistBox = $('<div class="spawnlist-box combatsim-bottom-gold-line-thick"/>')
        .append(this.getTextDiv("Spawnlist", "box-subtitle", true))
        .appendTo(ret);

    var spawnlistBoxList = spawnlistBox.createList(2);
    ret.spawnlistScrollContainer = spawnlistBoxList.findListScrollContainer();

    var unitsBox = $('<div class="units-box"/>')
        .append(this.getTextDiv("Units", "box-subtitle", true))
        .appendTo(ret);

    var unitsBoxList = unitsBox.createList(2);
    ret.unitsScrollContainer = unitsBoxList.findListScrollContainer();

    var buttonBar = $('<div class="button-bar-box"/>');
    ret.append(buttonBar);
    ret.buttons = {};

    var layout = $('<div class="combatsim-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addUnitButton = layout.createTextButton("Add Unit", $.proxy(function(_div){
        this.createAddUnitScrollContainer(this.createPopup('Add Unit','combatsim-generic-popup', 'combatsim-generic-popup-container'), ret.unitsScrollContainer);
    }, this), "combatsim-text-button", 4);
    ret.buttons.addUnitButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Add"});

    layout = $('<div class="combatsim-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addSpawnlistButton = layout.createTextButton("Add Spawnlist", $.proxy(function(_div){
        this.createAddSpawnlistScrollContainer(this.createPopup('Add Spawnlist','combatsim-generic-popup', 'combatsim-generic-popup-container'), ret.spawnlistScrollContainer);
    }, this), "combatsim-text-button", 4);
    ret.buttons.addSpawnlistButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Spawnlist.Main.Add"});

    layout = $('<div class="combatsim-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addBroButton = layout.createTextButton("Add Bro", $.proxy(function(_div){
        this.createAddBroScrollContainer(this.createPopup('Add Bro','combatsim-generic-popup', 'combatsim-generic-popup-container'), ret.unitsScrollContainer);
    }, this), "combatsim-text-button", 4);
    ret.buttons.addBroButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Bros.Main.Add"});
}

CombatSimulatorScreen.prototype.createAddUnitScrollContainer = function(_dialog, _side)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));

    MSU.iterateObject(this.mData.AllUnits, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "", true);

        var name = $('<div class="title-font-normal font-color-subtitle combatsim-entry-label">' + _unit.DisplayName +  '</div>');
        row.append(name);

        var addButtonContainer = $('<div class="combatsim-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addUnitToBox(_unit, _side, _key);
            this.focusActiveFilterBar();
        }, self), "combatsim-text-button", 4);
        addButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Add"});

        row.append(addButtonContainer);
    }, this))
    this.focusActiveFilterBar();
}

CombatSimulatorScreen.prototype.addUnitToBox = function(_unit, _side)
{
    var row = this.addRow(_side, "", true);
    row.data("unitID", _unit.Key);
    row.data("unit", _unit);

    var name = $('<div class="title-font-normal font-color-subtitle combatsim-entry-label">' + _unit.DisplayName +  '</div>');
    row.append(name);
    name.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Type"});

    var amountInputLayout = $('<div class="combatsim-short-input-container"/>');
    row.append(amountInputLayout);

    var amountInput = $('<input type="text" class="title-font-normal font-color-subtitle short-input"/>');
    amountInputLayout.append(amountInput);
    amountInput.val(1);
    row.data("amount", amountInput);
    amountInput.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Amount"});

    var destroyButtonLayout = $('<div class="combatsim-delete-button-container"/>');
    row.append(destroyButtonLayout);
    var destroyButton = $('<img class="combatsim-delete-row-button"/>')
        .attr("src", Path.GFX + Asset.BUTTON_DISMISS_CHARACTER)
        .appendTo(destroyButtonLayout);
    destroyButton.click(function()
    {
        row.remove();
    })
    destroyButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Delete"});

    var checkbox = this.addCheckboxSetting(row, "champion-checkbox", null, "uncheck", "Champion");
    checkbox.container.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Champion"})
    row.data("champion", checkbox.checkbox);
    return row;
}

CombatSimulatorScreen.prototype.createAddSpawnlistScrollContainer = function(_dialog, _boxDiv)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(this.mData.AllSpawnlists, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "", true);
        var name = $('<div class="title-font-normal font-color-subtitle combatsim-entry-label">' + _unit.id +  '</div>');
        row.append(name);
        var addButtonContainer = $('<div class="combatsim-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addSpawnlistToBox(_unit, _boxDiv);
            this.focusActiveFilterBar();
        }, self), "combatsim-text-button", 4);
        row.append(addButtonContainer);
    }, this))
    this.focusActiveFilterBar();
}

CombatSimulatorScreen.prototype.addSpawnlistToBox = function(_unit, _boxDiv)
{
    var row = this.addRow(_boxDiv, "", true);
    row.data("unitID", _unit.id);
    row.data("unit", _unit);

    var name = this.getTextDiv(_unit.id);
    row.append(name);
    name.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Spawnlist.Main.Type"});

    var amountInputLayout = $('<div class="combatsim-short-input-container"/>');
    row.append(amountInputLayout);
    var amountInput = $('<input type="text" class="title-font-normal font-color-subtitle short-input"/>');
    amountInputLayout.append(amountInput);
    amountInput.val(100);
    row.data("amount", amountInput);
    amountInput.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Spawnlist.Main.Resources"});

    var destroyButtonLayout = $('<div class="combatsim-delete-button-container"/>');
    row.append(destroyButtonLayout);
    var destroyButton = $('<img class="combatsim-delete-row-button"/>')
        .attr("src", Path.GFX + Asset.BUTTON_DISMISS_CHARACTER)
        .appendTo(destroyButtonLayout);
    destroyButton.click(function()
    {
        row.remove();
    })
    destroyButton.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Spawnlist.Main.Delete"});
    return row;
}

CombatSimulatorScreen.prototype.createAddBroScrollContainer = function(_dialog, _boxDiv)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(this.mData.AllBrothers, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "", true);
        var name = $('<div class="title-font-normal font-color-subtitle combatsim-entry-label">' + _unit.DisplayName +  '</div>')
            .appendTo(row);
        var addButtonContainer = $('<div class="combatsim-text-button-layout"/>')
            .appendTo(row);
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addBroToBox(_unit, _boxDiv);
            this.focusActiveFilterBar();
        }, self), "combatsim-text-button", 4);
        
    }, this))
    this.focusActiveFilterBar();
}

CombatSimulatorScreen.prototype.addBroToBox = function(_unit, _boxDiv)
{
    var self = this;
    var row = this.addRow(_boxDiv, "", true)
        .data("unitID", _unit.ID)
        .data("unit", _unit)
        .data("isBro", true)

    var name = $('<div class="title-font-normal font-color-subtitle combatsim-entry-label">' + _unit.DisplayName +  '</div>')
        .appendTo(row)
        .bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Bros.Main.Type"});

    var amountInputLayout = $('<div class="combatsim-short-input-container"/>')
        .appendTo(row);

    var amountInput = $('<input type="text" class="title-font-normal font-color-subtitle short-input"/>')
        .appendTo(amountInputLayout)
        .val(1);
    amountInput.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Amount"});
    row.data("amount", amountInput);
   
    var destroyButtonLayout = $('<div class="combatsim-delete-button-container"/>')
        .appendTo(row);

    var destroyButton = $('<img class="combatsim-delete-row-button"/>')
        .appendTo(destroyButtonLayout)
        .attr("src", Path.GFX + Asset.BUTTON_DISMISS_CHARACTER)
        .click(function()
        {
            row.remove();
        })
        .bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Units.Main.Delete"})
    return row;
}

CombatSimulatorScreen.prototype.setData = function (_data)
{    
    this.mData = _data;
    this.resetBros();
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

    this.mSpawnCompanyCheck.iCheck('check');
    this.mCutDownTreesCheck.iCheck('uncheck');
    this.mIsFleeingProhibitedCheck.iCheck('uncheck');
    this.mFortificationCheck.iCheck('uncheck');
}

CombatSimulatorScreen.prototype.reset = function()
{
    var self = this;
    this.initialiseValues();
    MSU.iterateObject(this.mFactions, function(_id, _faction){
        _faction.spawnlistScrollContainer.empty();
        _faction.unitsScrollContainer.empty();
    })
}

CombatSimulatorScreen.prototype.resetBros = function()
{
    var self = this;
    var broIDs = [];
    $.each(this.mData.AllBrothers, function(_idx, _bro){
        broIDs.push(_bro.ID)
    })
    var findID = function(_id)
    {
        var hasID = false;
        $.each(broIDs, function(_idx, _value){
            if (_value === _id)
                hasID = true;
        })
        return hasID;
    }
    MSU.iterateObject(this.mFactions, function(_id, _faction){
        var unitRows = _faction.unitsScrollContainer.find(".combatsim-row")
        unitRows.each(function(_idx){
            var unitID = $(this).data("unitID");
            if ($(this).data("isBro") === true && !findID($(this).data("unitID")))
                $(this).remove();
        })
    })
}

CombatSimulatorScreen.prototype.gatherData = function()
{
    var self = this;
    var ret = {
        Settings : this.mSettings,
        Factions : {}
    };

    MSU.iterateObject(this.mFactions, function(_id, _faction){
        self.getFactionData(ret, _faction);
    })
    this.copyData(ret);
    return ret;
}

CombatSimulatorScreen.prototype.setFromString = function(_string)
{
    var self = this;
    this.reset();
    var data = JSON.parse(_string);
    var setCheckboxFromBool = function(_checkbox, _bool)
    {
        if (_bool === true)
            _checkbox.iCheck("check")
        else _checkbox.iCheck("uncheck")
    }
    this.mSettings.Terrain = data.Settings.Terrain;
    this.mSettings.Map = data.Settings.Map;
    this.mSettings.MusicTrack = data.Settings.MusicTrack;
    this.mTerrainButton.changeButtonText(this.mSettings.Terrain);
    this.mMapButton.changeButtonText(this.mSettings.Map);
    this.mTrackButton.changeButtonText(this.mSettings.MusicTrack);
    setCheckboxFromBool(this.mSpawnCompanyCheck, data.Settings.SpawnCompany);
    setCheckboxFromBool(this.mCutDownTreesCheck, data.Settings.CutDownTrees);
    setCheckboxFromBool(this.mIsFleeingProhibitedCheck, data.Settings.IsFleeingProhibited);
    setCheckboxFromBool(this.mFortificationCheck, data.Settings.Fortification);
    $.each(data.Factions, function(_factionKey, _faction)
    {
        var factionDiv = self.mFactions[_faction.ID];
        var spawnlistDiv = factionDiv.spawnlistScrollContainer;
        var unitsDiv = factionDiv.unitsScrollContainer;
        if (_faction.ControlUnits)
            factionDiv.data("controlUnitsCheckbox").iCheck('check')

        $.each(_faction.Spawnlists, function(_idx, _entry){
            var spawnlist = self.mData.AllSpawnlists[_entry.ID];
            if (spawnlist != null)
            {
                var row = self.addSpawnlistToBox(spawnlist, spawnlistDiv);
                row.data("amount").val(_entry.Resources)
            }
        })
        $.each(_faction.Units, function(_idx, _entry){
            var unit = self.mData.AllUnits[_entry.Type];
            if (unit != null)
            {
                var row = self.addUnitToBox(unit, unitsDiv);
                row.data("amount").val(_entry.Num)
            }
        })
        $.each(_faction.Bros, function(_idx, _entry){
            var bro = self.mData.AllBrothers[_entry.ID];
            if (bro != null)
            {
                var row = self.addBroToBox(bro, unitsDiv);
                row.data("amount").val(_entry.Num)
            }
        })
    })
}

CombatSimulatorScreen.prototype.getFactionData = function(_ret, _div)
{
    var ret = {
        ID : _div.data("id"),
        Spawnlists : [],
        Units : [],
        Bros : [],
        ControlUnits : false,
    }
    var spawnlistRows = _div.spawnlistScrollContainer.find(".combatsim-row")
    spawnlistRows.each(function(_idx){
        ret.Spawnlists.push({
            ID : $(this).data("unitID"),
            Resources : $(this).data("amount").val()
        })
    })

    var unitRows = _div.unitsScrollContainer.find(".combatsim-row")
    unitRows.each(function(_idx){
        if ($(this).data("isBro") === true)
        {
            ret.Bros.push({
                ID : $(this).data("unitID"),
                Num : $(this).data("amount").val(),
            })
        }
        else
        {
            ret.Units.push({
                Type : $(this).data("unitID"),
                Num : $(this).data("amount").val(),
                Champion : $(this).data("champion").prop("checked")
            })
        }
    })

    if (_div.data("controlUnitsCheckbox").prop("checked"))
        ret.ControlUnits = true;    

    _ret.Factions[_div.data("id")] = ret;
}

CombatSimulatorScreen.prototype.getIDCounter = function(_id)
{
    if (!(_id in this.mSettingIDCounters))
        this.mSettingIDCounters[_id] = -1;
    return  (_id + ++this.mSettingIDCounters[_id]);
}

CombatSimulatorScreen.prototype.addCheckboxSetting = function(_div, _id, _settingKey, _default, _name)
{
    var self = this
    var checkboxContainer = $('<div class="combatsim-checkbox-container"/>')
        .appendTo(_div);
    var id = this.getIDCounter(_id);
    var checkbox = $('<input class="combatsim-checkbox" type="checkbox" id="' + id + '" />').appendTo(checkboxContainer).iCheck({
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
    
    var label = $('<label class="bool-checkbox-label" for="' + id + '">' + _name + '</label>');
    checkboxContainer.append(label)
    label.click(function(){
        if (!checkbox.attr("disabled"))
            checkbox.iCheck('toggle');
    })
    checkbox.iCheck(_default);
    if(_settingKey != null) checkboxContainer.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "Screen.Settings." + _settingKey});
    return {
        container : checkboxContainer,
        checkbox : checkbox
    }
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
    var row = $('<div class="combatsim-filter-bar"/>');
    var name = this.getTextDiv("Filter")
        .appendTo(row);
    var filterLayout = $('<div class="combatsim-filter-input-container"/>')
        .appendTo(row);
    var filterInput = $('<input type="text" class="title-font-normal font-color-brother-name"/>')
        .appendTo(filterLayout)
        .on("keyup", function(_event){
            var currentInput = $(this).val();
            var rows = _scrollContainer.find(".combatsim-row");
            rows.each(function(_idx){
                var label = $(this).find(".combatsim-entry-label");
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
    this.mActiveFilterBar = filterInput;
    return row;
}

CombatSimulatorScreen.prototype.focusActiveFilterBar = function()
{
    if (this.mActiveFilterBar === undefined || this.mActiveFilterBar === null || this.mActiveFilterBar.length === 0)
        return;
    this.mActiveFilterBar.focus();
    this.mActiveFilterBar.select()
}

CombatSimulatorScreen.prototype.addRow = function(_div, _classes, _divider)
{
    var row = $('<div class="combatsim-row"/>');
    _div.append(row);
    if (_classes != undefined)
    {
        row.addClass(_classes);
    }
    if(_divider === true)
    {
        row.addClass("combatsim-bottom-gold-line");
    }
    return row;
}

CombatSimulatorScreen.prototype.getTextDiv = function(_text, _classes, _isTitle)
{
    _classes = _classes || "";
    var row = $('<div class="title-font-normal font-color-subtitle combatsim-entry-label"></div>')
        .html(_text)
        .addClass(_classes)
    if (_isTitle === true)
        row.removeClass("font-color-subtitle").addClass("font-color-brother-name")
    return row;
}

CombatSimulatorScreen.prototype.notifyBackendUpdateFactionProperty = function (_id, _property, _value)
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'updateFactionProperty', [_id, _property, _value]);
    }
};

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
    button.Enabled = _data[1];
    if (button.Button !== null)
    {
        button.Button.changeButtonImage(Path.GFX + button.Paths[_data[1].toString()]);
        button.Button.trigger('update-tooltip' + TooltipModuleIdentifier.KeyEvent.Namespace) 
    }
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

CombatSimulatorScreen.prototype.copyData = function(_obj)
{
    var str = JSON.stringify(_obj);
    var input = $('<input type="text"/>').appendTo($(".combatsim-container-layout"));
    input.val(str);
    input.select();
    input.focus();
    document.execCommand('copy');
    input.remove();
}

CombatSimulatorScreen.prototype.pasteData = function()
{
    var input = $('<input type="text"/>').appendTo($(".combatsim-container-layout"));
    input.select();
    input.focus();
    document.execCommand('paste');
    var ret = input.val();
    input.remove();
    return ret;
}

CombatSimulatorScreen.prototype.testThings = function ()
{  
    var randomProperty = function (obj) {
        var keys = Object.keys(obj);
        return obj[keys[ keys.length * Math.random() << 0]];
    };
    // this.addSpawnlistToBox(randomProperty(this.mData.AllSpawnlists), this.mFactions["faction-0"].spawnlistScrollContainer)
    // this.addSpawnlistToBox(randomProperty(this.mData.AllSpawnlists), this.mFactions["faction-1"].spawnlistScrollContainer)
    this.addBroToBox(randomProperty(this.mData.AllBrothers), this.mFactions["faction-0"].unitsScrollContainer)
    this.addBroToBox(randomProperty(this.mData.AllBrothers), this.mFactions["faction-1"].unitsScrollContainer)
}

registerScreen("CombatSimulatorScreen", new CombatSimulatorScreen());

