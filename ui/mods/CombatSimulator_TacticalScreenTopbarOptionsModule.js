var createDIV = TacticalScreenTopbarOptionsModule.prototype.createDIV;
TacticalScreenTopbarOptionsModule.prototype.createDIV = function(_parentDiv)
{
    var self = this;
    createDIV.call(this, _parentDiv);
    var buttons = Screens.CombatSimulatorScreen.mTopBarButtons;
    var idx = -5;
    MSU.iterateObject(buttons, function(key, _button){
        _button.Layout = $('<div class="l-combatsim-button display-none"/>');
        self.mContainer.append(_button.Layout);
        _button.Layout.css("left", idx + "rem");
        idx = idx - 4;
        var gfx = Path.GFX + _button.Paths[_button.Enabled.toString()];
        _button.Button = _button.Layout.createImageButton(gfx, function ()
        {
            Screens.CombatSimulatorScreen.notifyBackendTopBarButtonPressed(key);
        }, '', 6);
        _button.Button.bindTooltip({ contentType: 'msu-generic', modId: CombatSimulator.ModID, elementId: _button.Tooltip});
    })
} 
