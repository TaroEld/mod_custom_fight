var createDIV = TacticalScreenTopbarOptionsModule.prototype.createDIV;
TacticalScreenTopbarOptionsModule.prototype.createDIV = function(_parentDiv)
{
    var self = this;
    createDIV.call(this, _parentDiv);
    var buttons = Screens.CustomFightScreen.mButtons;
    var idx = -5;
    MSU.iterateObject(buttons, function(key, _button){
        _button.Layout = $('<div class="l-custom-fight-button display-none"/>');
        self.mContainer.append(_button.Layout);
        _button.Layout.css("left", idx + "rem");
        idx = idx - 4;
        var gfx = Path.GFX + _button.Paths["false"];
        _button.Button = _button.Layout.createImageButton(gfx, function ()
        {
            Screens.CustomFightScreen.notifyBackendTopBarButtonPressed(key);
        }, '', 6);
        _button.Button.bindTooltip({ contentType: 'ui-element', elementId: _button.Tooltip});
    })
} 
