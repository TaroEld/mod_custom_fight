var createDIV = TacticalScreenTopbarOptionsModule.prototype.createDIV;
TacticalScreenTopbarOptionsModule.prototype.createDIV = function(_parentDiv)
{
    var self = this;
    createDIV.call(this, _parentDiv);
    var buttons = Screens.CustomFightScreen.mButtons;
    var idx = -5;
    MSU.iterateObject(buttons, function(key, _button){
        var layout = $('<div class="l-custom-fight-button"/>');
        self.mContainer.append(layout);
        layout.css("left", idx + "rem");
        idx = idx - 4;
        var gfx = Path.GFX + _button.Paths["false"];
        _button.Button = layout.createImageButton(gfx, function ()
        {
            Screens.CustomFightScreen.notifyBackendTopBarButtonPressed(key);
        }, '', 6);
        _button.Button.bindTooltip({ contentType: 'ui-element', elementId: _button.Tooltip});
    })
} 
