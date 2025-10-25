classdef AbstractContainer < controllib.ui.internal.dialog.AbstractUI & controllib.ui.internal.dialog.MixedInContainer
    % Super class that wraps a "ui container" that represents UI component.
    % "ui container" must be a class in the "matlab.ui.container" package.
    %
    % Properties:
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInContainer.IsWidgetValid">IsWidgetValid</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInContainer.Name">Name</a>
    %
    % Methods:
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInContainer.getWidget">getWidget</a>
    %
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInContainer.createContainer">createContainer (protected)</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractUI.cleanupUI">cleanupUI (protected)</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractUI.connectUI">connectUI (protected)</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractUI.updateUI">updateUI</a>
    %
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDataListeners.registerDataListeners">registerDataListeners</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDataListeners.unregisterDataListeners">unregisterDataListeners</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDataListeners.enableDataListeners">enableDataListeners</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDataListeners.disableDataListeners">disableDataListeners</a>    
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInUIListeners.registerUIListeners">registerUIListeners</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInUIListeners.unregisterUIListeners">unregisterUIListeners</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInUIListeners.enableUIListeners">enableUIListeners</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInUIListeners.disableUIListeners">disableUIListeners</a>    
    %
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInContainer.qeGetDialog">qeGetDialog</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractUI.qeGetWidgets">qeGetWidgets (need overload)</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInContainer.qeIsDialogValid">qeIsDialogValid</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInContainer.qeShow">qeShow</a>
    %
    % Events:
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInContainer.PackDialog">PackDialog</a>    
    %
    % See also controllib.ui.internal.dialog.AbstractContainer
    
    % Author(s): Rong Chen
    % Copyright 2019 The MathWorks, Inc.
end