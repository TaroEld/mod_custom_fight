var createDIV = TacticalScreenTopbarOptionsModule.prototype.createDIV;
TacticalScreenTopbarOptionsModule.prototype.createDIV = function(_parentDiv)
{
    var self = this;
    createDIV.call(this, _parentDiv);
    var buttons = Screens.CustomFightScreen.mButtons;
    MSU.iterateObject(buttons, function(key, _button){
        var layout = $('<div/>');
        layout.addClass(_button.Class)
        self.mContainer.append(layout);
        var gfx = Path.GFX + _button.Paths["false"];
        _button.Button = layout.createImageButton(gfx, function ()
        {
            Screens.CustomFightScreen.notifyBackendTopBarButtonPressed(key);
        }, '', 6);
        _button.Button.bindTooltip({ contentType: 'ui-element', elementId: _button.Tooltip});
    })
} 
