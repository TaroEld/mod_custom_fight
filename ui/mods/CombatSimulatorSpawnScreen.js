"use strict";

var CombatSimulatorSpawnScreen = function(_parent)
{
    MSUUIScreen.call(this);
    this.mModID = "mod_combat_simulator"
    this.mID = "CombatSimulatorSpawnScreen";
    this.mContainer = null;
    this.mDialogContainer = null;
    this.mDialogContentContainer = null;

    this.mFactions = {};
    this.mMaxFactions = 4;
    this.mActiveFaction = null;
    this.mFactionsIdx = 0;

    this.mSettingIDCounters = {};
    this.mSettingsBox = null;
    this.mSettings = {
        Champion : false
    }
}

CombatSimulatorSpawnScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(CombatSimulatorSpawnScreen.prototype, 'constructor', {
    value: CombatSimulatorSpawnScreen,
    enumerable: false,
    writable: true
});

CombatSimulatorSpawnScreen.prototype.createDIV = function (_parentDiv)
{
    var self = this;

    // create: containers (init hidden!)
    this.mContainer = $('<div class="dialog-screen ui-control display-none opacity-none combatsim-spawn"/>');
    _parentDiv.append(this.mContainer);
    this.mContainer.drag(function( ev, dd ){
        var clamp = function(num, min, max){
            return Math.min(Math.max(num, min), max);
        }
        
          $( this ).css({
             top: clamp(dd.offsetY, 0, $(document).height()),
             left: clamp(dd.offsetX, 0, $(document).width())
          });
    });

    // create: dialog container
    var dialogLayout = $('<div class="combatsim-spawn-container-layout"/>');
    this.mContainer.append(dialogLayout);
    this.mDialogContainer = dialogLayout.createDialog('Spawn Units', null, null, false);
    this.mDialogContentContainer = this.mDialogContainer.findDialogContentContainer();

    this.mIsVisible = false;
    this.createContentDiv();
};

CombatSimulatorSpawnScreen.prototype.destroyDIV = function ()
{    
    this.mContainer.empty();
    this.mContainer.remove();
    this.mContainer = null;
};

CombatSimulatorSpawnScreen.prototype.createContentDiv = function()
{
    this.mUnitsDiv = $('<div class="spawn-screen-units-div"/>').appendTo(this.mDialogContentContainer);
    this.createUnitsList();
    // this.mBrosDiv = $('<div class="spawn-screen-units-div"/>').appendTo(this.mDialogContentContainer);
    // this.createBrosList();
    this.mSettingsBox = $('<div class="spawn-screen-settings-div"/>').appendTo(this.mDialogContentContainer);
    this.createSettingsContent();
    this.mFactionsBox = $('<div class="spawn-screen-factions-container"/>').appendTo(this.mDialogContentContainer);
    this.createFactionsContent();
}

CombatSimulatorSpawnScreen.prototype.createUnitsList = function()
{
    var self = this;
    this.mUnitsContainer = this.mUnitsDiv.createList(2);
    this.mUnitsScrollContainer = this.mUnitsContainer.findListScrollContainer();
    var filterBar = this.createFilterBar(this.mUnitsScrollContainer);
    this.mUnitsDiv.prepend(filterBar);
    filterBar.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "SpawnScreen.FilterBar"});
    this.mUnitsDiv.hover(function(){
        $(this).data('hover', 1);
    },
    function(){
        $(this).data('hover', 0);
    });
}

CombatSimulatorSpawnScreen.prototype.createSettingsContent = function()
{
    var self = this;
    var checkboxRow = this.addRow(this.mSettingsBox);
    this.mChampionCheck = this.addCheckboxSetting(checkboxRow, "champion-checkbox", "Champion", "uncheck", "Spawn as Champion").checkbox;
    this.mChampionCheck.on('ifChecked ifUnchecked', null, this, function (_event) {
        self.mSettings["Champion"] = $(this).prop("checked");
    });

    var switchFactionRow = this.addRow(this.mSettingsBox, null, true)
    switchFactionRow.append(this.getTextDiv("Faction:", "label"));
    this.mActiveFactionLabel = this.getTextDiv("Allies","label")
        .appendTo(switchFactionRow);
    this.mFactionButtonContainer = $('<div class="combatsim-faction-button-container"/>')
        .appendTo(switchFactionRow);

    var buttonLayout = $('<div class="l-button"/>');
    this.mFactionButtonContainer.append(buttonLayout);
    this.mFactionNextButton = buttonLayout.createImageButton(Path.GFX + "mods/ui/buttons/switch_next_faction.png", function ()
    {
        self.switchFaction();
    }, "", 3);
    buttonLayout.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "SpawnScreen.FactionButton"});
}

CombatSimulatorSpawnScreen.prototype.createFactionsContent = function()
{
    var self = this;
    this.createFactionDiv("Allies", "faction-0");
    this.createFactionDiv("Faction 2", "faction-1");
    this.createFactionDiv("Faction 3", "faction-2");
    this.createFactionDiv("Faction 4", "faction-3");
    $(".spawn-screen-factions-div").css("display", "none");
    this.mFactions["faction-0"].css("display", "flex");
    this.mActiveFaction = this.mFactions["faction-0"];
}

CombatSimulatorSpawnScreen.prototype.createFactionDiv = function(_name, _id, _allies)
{
    var self = this;
    var ret = $('<div class="spawn-screen-factions-div"/>').appendTo(this.mFactionsBox);
    ret.data("id", _id);
    ret.data("name", _name);
    this.mFactions[_id] = ret;

    var checkboxRow = this.addRow(ret);
    var controlUnitsCheck = this.addCheckboxSetting(checkboxRow, "control-allies-checkbox" + _id,  "ControlUnits", "uncheck", "Control Units").checkbox;
    controlUnitsCheck.on('ifChecked ifUnchecked', null, this, function (_event) {
        Screens["CombatSimulatorScreen"].notifyBackendUpdateFactionProperty(_id, "ControlUnits", $(this).prop("checked"))
    });
    ret.data("ControlUnitsCheckbox", controlUnitsCheck);
}

CombatSimulatorSpawnScreen.prototype.switchFaction = function()
{
    var self = this;
    this.mFactionsIdx++;
    if (this.mFactionsIdx > 3) this.mFactionsIdx = 0;
    var idx = 0;
    $(".spawn-screen-factions-div").css("display", "none");
    MSU.iterateObject(this.mFactions, function(_id, _faction){
        if (idx == self.mFactionsIdx)
        {
            self.mActiveFaction = _faction;
            self.mActiveFactionLabel.text(_faction.data("name"))
            _faction.css("display", "flex");
        }
        idx++
    })
} 

CombatSimulatorSpawnScreen.prototype.setupFactionSettings = function()
{
    var self = this;
    MSU.iterateObject(this.mData.Factions, function(_id, _faction){
        var div = self.mFactions[_id];
        if(_faction.ControlUnits)
            div.data("ControlUnitsCheckbox").iCheck("check");
        else
            div.data("ControlUnitsCheckbox").iCheck("uncheck");
    })
}


CombatSimulatorSpawnScreen.prototype.fillUnitsList = function()
{
    var self = this;
    this.mUnitsScrollContainer.empty();

   $.each(this.mData.AllUnits, function(_key, _unit){
        var row = $('<div class="row"/>')
            .appendTo(self.mUnitsScrollContainer)
            .data("unit", _unit)
            .data('IsBro', false)
        row.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "SpawnScreen.UnitRow"});
        
        var iconContainer = $('<div class="orientation-div"/>')
            .appendTo(row)
            .append($('<img class="orientation-img" src="' + Path.GFX + 'ui/orientation/' + _unit.Icon + '.png"/>'));
        row.append($('<div class="title-font-normal font-color-brother-name combatsim-entry-label">' + _unit.DisplayName +  '</div>'));   
        self.createDragHandler(row);    
    })

   $.each(this.mData.AllBrothers, function(_key, _unit){
        var row = $('<div class="row"/>')
            .appendTo(self.mUnitsScrollContainer)
            .data("unit", _unit)
            .data('IsBro', true)
        row.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "SpawnScreen.UnitRow"});
        
        var iconContainer = $('<div class="orientation-div"/>')
            .appendTo(row)
            .append($('<img class="orientation-img" src="' + Path.GFX + _unit.Icon + '"/>'));
        row.append($('<div class="title-font-normal font-color-brother-name combatsim-entry-label">' + _unit.DisplayName +  '</div>'));   
        self.createDragHandler(row);    
    })
}

CombatSimulatorSpawnScreen.prototype.createDragHandler = function(_row)
{
    var self = this;
    var screen = $('.tactical-screen');
    _row.drag("start", function(ev, dd)
    {
        var data = $(this).data('unit');
        // build proxy
        var proxy = null;
        var imageLayer = $(this).find('.orientation-div:first');
        if (imageLayer.length > 0)
        {
            proxy = imageLayer.clone();
        }
        else
        {
            proxy = $(this).find('.combatsim-entry-label:first').clone();
        }
        proxy.appendTo(screen);
        proxy.data('unit', data);
        proxy.css("position", "absolute")
        proxy.css("z-index", "99999")
        return proxy;
    }, { distance: _row.width()});

    _row.drag(function(ev, dd)
    {
        $(dd.proxy).css({ top: dd.offsetY, left: dd.offsetX -10});
    })

    _row.drag("end", function(ev, dd)
    {
        if (self.mUnitsDiv.data("hover") == 0) self.notifyBackendSpawnUnit(_row.data('unit'), _row.data('IsBro'), self.mActiveFaction.data("id"));
        var proxy = $(dd.proxy);
        proxy.remove();
    });
}

CombatSimulatorSpawnScreen.prototype.getIDCounter = function(_id)
{
    if (!(_id in this.mSettingIDCounters))
        this.mSettingIDCounters[_id] = -1;
    return  (_id + ++this.mSettingIDCounters[_id]);
}

CombatSimulatorSpawnScreen.prototype.addCheckboxSetting = function(_div, _id, _settingKey, _default, _name)
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

    var label = $('<label class="bool-checkbox-label" for="' + id + '">' + _name + '</label>');
    checkboxContainer.append(label)
    label.click(function(){
        if (!checkbox.attr("disabled"))
            checkbox.iCheck('toggle');
    })
    checkbox.iCheck(_default);
    if(_settingKey != null) checkboxContainer.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: "SpawnScreen.Settings." + _settingKey});
    return {
        container : checkboxContainer,
        checkbox : checkbox
    }
}

CombatSimulatorSpawnScreen.prototype.addRow = function(_div, _classes, _divider)
{
    var row = $('<div class="combatsim-row"/>');
    _div.append(row);
    if (_classes != undefined && _classes != null)
    {
        row.addClass(_classes);
    }
    if(_divider === true)
    {
        row.addClass("combatsim-bottom-gold-line");
    }
    return row;
}

CombatSimulatorSpawnScreen.prototype.createFilterBar = function(_scrollContainer)
{
    var row = $('<div class="combatsim-filter-bar"/>');
    var filterLayout = $('<div class="combatsim-filter-input-container"/>')
        .appendTo(row);
    var filterInput = $('<input type="text" class="title-font-normal font-color-brother-name"/>')
        .appendTo(filterLayout)
        .on("keyup", function(_event){
            var currentInput = $(this).val();
            var rows = _scrollContainer.find(".row");
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
    return row;
}

CombatSimulatorSpawnScreen.prototype.getTextDiv = function(_text, _classes)
{
    var row = $('<div class="title-font-normal font-color-brother-name combatsim-entry-label"></div>')
    row.html(_text);
    if(_classes != undefined && _classes != null) row.addClass(_classes);
    return row;
}

CombatSimulatorSpawnScreen.prototype.setData = function (_data)
{    
    this.mData = _data;
    this.fillUnitsList();
    this.setupFactionSettings();
};

CombatSimulatorSpawnScreen.prototype.notifyBackendOkButtonPressed = function ()
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onOkButtonPressed', this.gatherData());
    }
};

CombatSimulatorSpawnScreen.prototype.notifyBackendSpawnUnit = function (_unit, _isBro, _factionID)
{
    var ret = {
        Unit : _unit,
        IsBro : _isBro,
        Faction : _factionID,
        Settings : this.mSettings
    }
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'spawnUnit', ret);
    }
};


registerScreen("CombatSimulatorSpawnScreen", new CombatSimulatorSpawnScreen());

