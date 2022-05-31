"use strict";

var CustomFightSpawnScreen = function(_parent)
{
    MSUUIScreen.call(this);
    this.mModID = "mod_custom_fight"
    this.mID = "CustomFightSpawnScreen";
    this.mContainer = null;
    this.mDialogContainer = null;
    this.mDialogContentContainer = null;

    this.mSettingsBox = null;
    this.mSettings = {
        Ally : false,
        Champion : false
    }
}

CustomFightSpawnScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(CustomFightSpawnScreen.prototype, 'constructor', {
    value: CustomFightSpawnScreen,
    enumerable: false,
    writable: true
});

CustomFightSpawnScreen.prototype.createDIV = function (_parentDiv)
{
    var self = this;

    // create: containers (init hidden!)
    this.mContainer = $('<div class="dialog-screen ui-control display-none opacity-none custom-fight-spawn"/>');
    _parentDiv.append(this.mContainer);

    // create: dialog container
    var dialogLayout = $('<div class="custom-fight-spawn-container-layout"/>');
    this.mContainer.append(dialogLayout);
    this.mDialogContainer = dialogLayout.createDialog('Spawn Units', null, null, false);
    this.mDialogContentContainer = this.mDialogContainer.findDialogContentContainer();

    this.mIsVisible = false;
    this.createContentDiv();
};

CustomFightSpawnScreen.prototype.destroyDIV = function ()
{    
    this.mContainer.empty();
    this.mContainer.remove();
    this.mContainer = null;
};

CustomFightSpawnScreen.prototype.createContentDiv = function()
{
    this.mUnitsDiv = $('<div class="spawn-screen-units-div"/>').appendTo(this.mDialogContentContainer);
    this.createUnitsList();
    this.mSettingsBox = $('<div class="spawn-screen-settings-div"/>').appendTo(this.mDialogContentContainer);
    this.createSettingsContent();
}

CustomFightSpawnScreen.prototype.createUnitsList = function()
{
    var self = this;
    this.mUnitsContainer = this.mUnitsDiv.createList(2);
    this.mUnitsScrollContainer = this.mUnitsContainer.findListScrollContainer();
    this.mUnitsDiv.prepend(this.createFilterBar(this.mUnitsScrollContainer));
}

CustomFightSpawnScreen.prototype.fillUnitsList = function()
{
    MSU.iterateObject(this.mData.AllUnits, $.proxy(function(_key, _unit){
        var row = $('<div class="row"/>').appendTo(this.mUnitsScrollContainer);
        row.data("unit", _unit);
        var iconContainer = $('<div class="orientation-div"/>')
        row.append(iconContainer)
        iconContainer.append($('<img class="orientation-img" src="' + Path.GFX + 'ui/orientation/' + _unit.Icon + '.png"/>'));
        row.append($('<div class="title-font-normal font-color-brother-name custom-fight-entry-label">' + _unit.DisplayName +  '</div>'));   
        this.createDragHandler(row);     
    }, this))
}

CustomFightSpawnScreen.prototype.createDragHandler = function(_row)
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
            imageLayer = imageLayer.clone();
            proxy = imageLayer;
        }
        proxy.appendTo(document.body);
        proxy.data('unit', data);
        proxy.css("position", "absolute")
        proxy.css("z-index", "99999")
        return proxy;
    });

    _row.drag(function(ev, dd)
    {
        $(dd.proxy).css({ top: dd.offsetY, left: dd.offsetX });
    })

    _row.drag("end", function(ev, dd)
    {
        self.notifyBackendSpawnUnit(_row.data('unit'));
        var proxy = $(dd.proxy);
        proxy.remove();
    });
}

CustomFightSpawnScreen.prototype.createSettingsContent = function()
{
    var self = this;
    var addCheckboxSetting = $.proxy(function(_id, _settingKey, _default, _name)
    {
        var checkboxRow = $('<div class="row"/>').appendTo(this.mSettingsBox);
        var checkbox = $('<input type="checkbox" id="' + _id + '" />').appendTo(checkboxRow).iCheck({
            checkboxClass: 'icheckbox_flat-orange',
            radioClass: 'iradio_flat-orange',
            increaseArea: '30%'
        });
        checkbox.on('ifChecked ifUnchecked', null, this, function (_event) {
            self.mSettings[_settingKey] = $(this).prop("checked")
        });
        checkbox.iCheck(_default);
        checkboxRow.append($('<label class="text-font-normal font-color-subtitle bool-checkbox-label" for="' + _id + '">' + _name + '</label>'))
        return checkbox;
    }, this)

    this.mAllyCheck = addCheckboxSetting("ally-checkbox", "Ally", "uncheck", "Set to Ally")
    this.mChampionCheck = addCheckboxSetting("champion-checkbox", "Champion", "uncheck", "Spawn as Champion");
}


CustomFightSpawnScreen.prototype.createFilterBar = function(_scrollContainer)
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

CustomFightSpawnScreen.prototype.getTextDiv = function(_text, _classes)
{
    var row = $('<div class="title-font-normal font-color-brother-name custom-fight-entry-label"></div>')
    row.html(_text);
    if(_classes != undefined && _classes != null) row.addClass(_classes);
    return row;
}

CustomFightSpawnScreen.prototype.setData = function (_data)
{    
    console.error("setData")
    this.mData = _data;
    this.fillUnitsList();
};

CustomFightSpawnScreen.prototype.notifyBackendOkButtonPressed = function ()
{
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'onOkButtonPressed', this.gatherData());
    }
};

CustomFightSpawnScreen.prototype.notifyBackendSpawnUnit = function (_data)
{
    var ret = {
        Unit : _data,
        Settings : this.mSettings
    }
    if (this.mSQHandle !== null)
    {
        SQ.call(this.mSQHandle, 'spawnUnit', ret);
    }
};


registerScreen("CustomFightSpawnScreen", new CustomFightSpawnScreen());

