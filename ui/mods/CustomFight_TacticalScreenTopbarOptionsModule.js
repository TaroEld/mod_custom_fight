var createDIV = TacticalScreenTopbarOptionsModule.prototype.createDIV;
TacticalScreenTopbarOptionsModule.prototype.createDIV = function(_parentDiv)
{
    var self = this;
    createDIV.call(this, _parentDiv);
    var layout = $('<div class="l-spectator-button"/>');
    this.mContainer.append(layout);
    var state = Screens.CustomFightScreen.mSettings.SpectatorMode;
    var gfx = Path.GFX + Screens.CustomFightScreen.mButtons.ManualTurns.Paths[state.toString()];
    this.mManualTurnsButton = layout.createImageButton(gfx, function ()
    {
        Screens.CustomFightScreen.notifyBackendTopBarButtonPressed("ManualTurns");
    }, '', 6);

    var layout = $('<div class="l-pause-button"/>');
    this.mContainer.append(layout);
    gfx = Path.GFX + Screens.CustomFightScreen.mButtons.Pause.Paths["false"];
    this.mPauseButton = layout.createImageButton(gfx, function ()
    {
        Screens.CustomFightScreen.notifyBackendTopBarButtonPressed("Pause");
    }, '', 6);

    var layout = $('<div class="l-fov-button"/>');
    this.mContainer.append(layout);
    gfx = Path.GFX + Screens.CustomFightScreen.mButtons.FOV.Paths["false"];
    this.mFOVButton = layout.createImageButton(gfx, function ()
    {
        Screens.CustomFightScreen.notifyBackendTopBarButtonPressed("FOV");
    }, '', 6);

    var layout = $('<div class="l-camera-button"/>');
    this.mContainer.append(layout);
    gfx = Path.GFX + Screens.CustomFightScreen.mButtons.UnlockCamera.Paths["false"];
    this.mUnlockCameraButton = layout.createImageButton(gfx, function ()
    {
        Screens.CustomFightScreen.notifyBackendTopBarButtonPressed("UnlockCamera");
    }, '', 6);
} 
