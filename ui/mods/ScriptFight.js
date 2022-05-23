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

var ScriptFightScreen = function(_parent)
{
    MSUUIScreen.call(this);
    this.mModID = "mod_script_fight"
    this.mID = "ScriptFightScreen";
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
        UsePlayer : false,
    }
}

ScriptFightScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(ScriptFightScreen.prototype, 'constructor', {
    value: ScriptFightScreen,
    enumerable: false,
    writable: true
});

ScriptFightScreen.prototype.createDIV = function (_parentDiv)
{
    var self = this;

    // create: containers (init hidden!)
    this.mContainer = $('<div class="dialog-screen ui-control dialog-mod display-none opacity-none script-fight"/>');
    _parentDiv.append(this.mContainer);

    // create: dialog container
    var dialogLayout = $('<div class="script-fight-container-layout"/>');
    this.mContainer.append(dialogLayout);
    this.mDialogContainer = dialogLayout.createDialog('Custom Fight', null, null, false);
    this.mDialogContentContainer = this.mDialogContainer.findDialogContentContainer();

    // create footer button bar
    var footerButtonBar = $('<div class="l-button-bar"></div>');
    this.mDialogContainer.findDialogFooterContainer().append(footerButtonBar);

    // create: buttons
    var layout = $('<div class="l-ok-button"/>');
    footerButtonBar.append(layout);
    var button = layout.createTextButton("Start custom fight", function ()
    {
        self.notifyBackendOkButtonPressed();
    }, 'scripted-fight-text-button', 4);
    
    var layout = $('<div class="l-cancel-button"/>');
    footerButtonBar.append(layout);
    this.mNoButton = layout.createTextButton("Cancel", function ()
    {
        self.notifyBackendCancelButtonPressed();
    }, 'scripted-fight-text-button', 4);

    var layout = $('<div class="l-cancel-button"/>');
    footerButtonBar.append(layout);
    this.mResetButton = layout.createTextButton("Reset", function ()
    {
        self.initialiseValues();
    }, 'scripted-fight-text-button', 4);

    this.mIsVisible = false;
    this.createContentDiv();
};

ScriptFightScreen.prototype.destroyDIV = function ()
{    
    this.mContainer.empty();
    this.mContainer.remove();
    this.mContainer = null;
};

ScriptFightScreen.prototype.createContentDiv = function()
{
    this.createSettingsDiv();
    this.mLeftSideSetupBox = this.createSideDiv("left-side");
    this.mRightSideSetupBox = this.createSideDiv("right-side");
}

ScriptFightScreen.prototype.createSettingsDiv = function()
{
    var self = this;
    this.mSettingsBox = $('<div class="settings-box"/>');
    this.mDialogContentContainer.append(this.mSettingsBox);
    this.addRow(this.mSettingsBox).append($('<div class="title-font-normal font-color-brother-name label">Settings</div>'));

    var terrainRow = this.addRow(this.mSettingsBox);
    terrainRow.append($('<div class="title-font-normal font-color-brother-name label">Terrain</div>'));
    this.mTerrainButton = terrainRow.createTextButton("", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Terrain','generic-popup', 'generic-popup-container'), _div, this.mData.AllBaseTerrains, "Terrain")
    }, this), "scripted-fight-text-button", 4);

    var mapRow = this.addRow(this.mSettingsBox);
    mapRow.append($('<div class="title-font-normal font-color-brother-name label">Map</div>'));
    this.mMapButton = mapRow.createTextButton("", $.proxy(function(_div){
       this.createArrayScrollContainer(this.createPopup('Choose Map','generic-popup', 'generic-popup-container'), _div, this.mData.AllLocationTerrains, "Map")
    }, this), "scripted-fight-text-button", 4);
    this.mMapButton.mousedown(function(_event){
        if(_event.which == 3)
        {
            $(this).changeButtonText("");
            self.mSettings.Map = "";
        }
    });

    var checkboxRow = this.addRow(this.mSettingsBox)
    this.mUsePlayerCheck = checkboxRow.append($('<input type="checkbox" id="use-player-checkbox" />')).iCheck({
        checkboxClass: 'icheckbox_flat-orange',
        radioClass: 'iradio_flat-orange',
        increaseArea: '30%'
    });
    this.mUsePlayerCheck.on('ifChecked ifUnchecked', null, this, function (_event) {
        self.mSettings.UsePlayer = $(this).prop("checked")
    });
    this.mUsePlayerCheck.iCheck('uncheck');
    checkboxRow.append($('<label class="text-font-normal font-color-subtitle bool-checkbox-label" for="use-player-checkbox">Use Player</label>'))
}

// creates a generic popup that lists entries in an array
ScriptFightScreen.prototype.createArrayScrollContainer = function(_dialog, _div, _array, _setting)
{
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(_array, $.proxy(function(_key, _unit){
        if(_unit == "") return
        var row = this.addRow(scrollContainer);

        var name = $('<div class="title-font-normal font-color-brother-name script-entry-label">' + _unit +  '</div>');
        row.append(name);


        var addButtonContainer = $('<div class="scripted-fight-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Choose", $.proxy(function(_button){
            _div.changeButtonText(_unit)
            this.mSettings[_setting] = _unit;
        }, this), "scripted-fight-text-button", 4);
        row.append(addButtonContainer);
    }, this))
}

ScriptFightScreen.prototype.createSideDiv = function(_side)
{
    var self = this;
    var ret = $('<div class="setup-box"/>');
    this.mDialogContentContainer.append(ret);
    ret.addClass(_side);
    var spawnlistBox = $('<div class="spawnlist-box"/>');
    spawnlistBox.append($('<div class="title-font-normal font-color-brother-name box-subtitle"> Spawnlist </div>'))
    ret.append(spawnlistBox);
    var spawnlistBoxList = spawnlistBox.createList(2);
    ret.spawnlistScrollContainer = spawnlistBoxList.findListScrollContainer();

    var unitsBox = $('<div class="units-box"/>');
    unitsBox.append($('<div class="title-font-normal font-color-brother-name box-subtitle"> Units </div>'))
    ret.append(unitsBox);
    var unitsBoxList = unitsBox.createList(2);
    ret.unitsScrollContainer = unitsBoxList.findListScrollContainer();

    var buttonBar = $('<div class="button-bar-box"/>');
    ret.append(buttonBar);
    ret.buttons = {};

    var layout = $('<div class="scripted-fight-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addUnitButton = layout.createTextButton("Add Unit", $.proxy(function(_div){
        this.createAddUnitScrollContainer(this.createPopup('Add Unit','generic-popup', 'generic-popup-container'), ret.unitsScrollContainer);
    }, this), "scripted-fight-text-button", 4);

    layout = $('<div class="scripted-fight-text-button-layout"/>');
    buttonBar.append(layout);
    ret.buttons.addSpawnlistButton = layout.createTextButton("Add Spawnlist", $.proxy(function(_div){
        this.createAddSpawnlistScrollContainer(this.createPopup('Add Spawnlist','generic-popup', 'generic-popup-container'), ret.spawnlistScrollContainer);
    }, this), "scripted-fight-text-button", 4);
    return ret;
}

ScriptFightScreen.prototype.createAddUnitScrollContainer = function(_dialog, _side)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(this.mData.AllUnits, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "unit-row");
        row.unit = _unit;

        var name = $('<div class="title-font-normal font-color-brother-name script-entry-label">' + _unit.Name +  '</div>');
        row.append(name);

        var addButtonContainer = $('<div class="scripted-fight-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addUnitToBox(_unit, _side, _key);
        }, self), "scripted-fight-text-button", 4);
        row.append(addButtonContainer);
    }, this))
}

ScriptFightScreen.prototype.addUnitToBox = function(_unit, _side, _key)
{
    var row = this.addRow(_side);
    row.data("unitID", _key);
    row.data("unit", _unit);

    var name = $('<div class="title-font-normal font-color-brother-name script-entry-label">' + _unit.Name +  '</div>');
    row.append(name);

    var amountInputLayout = $('<div class="string-input-container"/>');
    row.append(amountInputLayout);
    var amountInput = $('<input type="text" class="title-font-normal font-color-brother-name string-input"/>');
    amountInputLayout.append(amountInput);
    amountInput.val(1);
    row.amount = amountInput;

    var destroyButtonLayout = $('<div class="keybind-delete-button-container"/>');
    row.append(destroyButtonLayout);
    var destroyButton = destroyButtonLayout.createTextButton("Delete", function()
    {
        row.remove();
    }, 'delete-keybind-button', 2);
}

ScriptFightScreen.prototype.createAddSpawnlistScrollContainer = function(_dialog, _side)
{
    var self = this;
    this.mPopupListContainer = _dialog.createList(2);
    var scrollContainer = this.mPopupListContainer.findListScrollContainer();
    _dialog.prepend(this.createFilterBar(scrollContainer));
    MSU.iterateObject(this.mData.AllSpawnlists, $.proxy(function(_key, _unit){
        var row = this.addRow(scrollContainer, "unit-row");
        row.unit = _unit;

        var name = $('<div class="title-font-normal font-color-brother-name script-entry-label">' + _unit.id +  '</div>');
        row.append(name);

        var addButtonContainer = $('<div class="scripted-fight-text-button-layout"/>');
        var addButton = addButtonContainer.createTextButton("Add", $.proxy(function(_button){
            this.addSpawnlistToBox(_unit, _side);
        }, self), "scripted-fight-text-button", 4);
        row.append(addButtonContainer);
    }, this))
}

ScriptFightScreen.prototype.addSpawnlistToBox = function(_unit, _side)
{
    var row = this.addRow(_side);
    row.data("unitID", _unit.id);
    row.data("unit", _unit);

    var name = $('<div class="title-font-normal font-color-brother-name script-entry-label">' + _unit.id +  '</div>');
    row.append(name);

    var amountInputLayout = $('<div class="string-input-container"/>');
    row.append(amountInputLayout);
    var amountInput = $('<input type="text" class="title-font-normal font-color-brother-name string-input"/>');
    amountInputLayout.append(amountInput);
    amountInput.val(100);

    var destroyButtonLayout = $('<div class="keybind-delete-button-container"/>');
    row.append(destroyButtonLayout);
    var destroyButton = destroyButtonLayout.createTextButton("Delete", function()
    {
        row.remove();
    }, 'delete-keybind-button', 2);
}

ScriptFightScreen.prototype.createPopup = function(_name, _popupClass, _popupDialogContentClass)
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

ScriptFightScreen.prototype.createFilterBar = function(_scrollContainer)
{
    var row = $('<div class="row filter-bar"/>');
    var name = $('<div class="title-font-normal font-color-brother-name script-entry-label">Filter</div>');
    row.append(name);
    var filterLayout = $('<div class="string-input-container"/>');
    row.append(filterLayout);
    var filterInput = $('<input type="text" class="title-font-normal font-color-brother-name string-input"/>');
    filterLayout.append(filterInput);
    filterInput.on("keyup", function(_event){
        var currentInput = $(this).val();
        var rows = _scrollContainer.find(".row");
        rows.each(function(_idx){
            var label = $(this).find(".script-entry-label");
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

ScriptFightScreen.prototype.addRow = function(_div, _classes)
{
    var row = $('<div class="row"/>');
    _div.append(row);
    if (_classes != undefined)
    {
        row.addClass(_classes);
    }
    return row;
}

ScriptFightScreen.prototype.setData = function (_data)
{    
    this.mData = _data;
    this.initialiseValues();
};

ScriptFightScreen.prototype.initialiseValues = function (_data)
{  
    this.mTerrainButton.changeButtonText(this.mData.AllBaseTerrains[1]);
    this.mSettings.Terrain = this.mData.AllBaseTerrains[1];

    this.mMapButton.changeButtonText("");
    this.mSettings.Map = "";

    this.mUsePlayerCheck.iCheck('uncheck');
    this.mSettings.UsePlayer = false;

    this.mLeftSideSetupBox.spawnlistScrollContainer.empty();
    this.mRightSideSetupBox.spawnlistScrollContainer.empty();
    this.mLeftSideSetupBox.unitsScrollContainer.empty();
    this.mRightSideSetupBox.unitsScrollContainer.empty();
    // this.mMapButton.html(this.mData.AllBaseTerrains[1]);
};

ScriptFightScreen.prototype.gatherData = function()
{
    var ret = {
        Settings : this.mSettings,
        Player : {},
        Enemy : {},
    };
    this.gatherUnits(ret.Player, this.mLeftSideSetupBox);
    this.gatherUnits(ret.Enemy, this.mRightSideSetupBox);
    // var ret = {
    //     Settings : {
    //         Terrain = "",
    //         Map = "",
    //         UsePlayer = false,
    //     },
    //     Player : {
    //         Spawnlists : [
    //             {
    //                 ID : "",
    //                 Resources : 0
    //             }
    //         ],
    //         Units : [
    //             {
    //                 ID : "",
    //                 Amount : 0,
    //                 Champion : false,
    //             }
    //         ]
    //     },
    //     Enemy : {

    //     }
    // };
    return ret;
}

ScriptFightScreen.prototype.gatherUnits = function(_ret, _div)
{
    _ret.Spawnlists = [];
    _ret.Units = [];
    var spawnlistRows = _div.spawnlistScrollContainer.find(".row")
    spawnlistRows.each(function(_idx){
        _ret.Spawnlists.push({
            ID : $(this).data("unitID"),
            Resources : $(this).find("input").val()
        })
    })

    var unitRows = _div.unitsScrollContainer.find(".row")
    unitRows.each(function(_idx){
        _ret.Units.push({
            Type : $(this).data("unitID"),
            Num : $(this).find("input").val()
        })
    })
    // ret.unitsScrollContainer
    // row.amount
}

ScriptFightScreen.prototype.notifyBackendOkButtonPressed = function ()
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onOkButtonPressed', this.gatherData());
    }
};

ScriptFightScreen.prototype.notifyBackendCancelButtonPressed = function ()
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onCancelButtonPressed');
    }
};

registerScreen("ScriptFightScreen", new ScriptFightScreen());

