classdef AbstractDialog < controllib.ui.internal.dialog.AbstractUI & controllib.ui.internal.dialog.MixedInDialog
    % Super class that wraps a "uifigure" that behaves like a dialog.
    %
    % Properties:
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.CloseMode">CloseMode</a>    
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.IsVisible">IsVisible</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.IsWidgetValid">IsWidgetValid</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.Name">Name</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.Title">Title</a>    
    %
    % Methods:
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.close">close</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.getWidget">getWidget</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.hide">hide</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.pack">pack</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.show">show</a>
    %
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.buildUI">buildUI (protected)</a>
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
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.qeAddPackDialogListener">qeAddPackDialogListener</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractUI.qeGetWidgets">qeGetWidgets (need overload)</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.qeAddPackDialogListener">qePack</a>
    %
    % Events:
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInDialog.CloseEvent">CloseEvent</a>    
    %
    % See also controllib.ui.internal.dialog.AbstractContainer

    % Author(s): Rong Chen
    % Copyright 2019 The MathWorks, Inc.
end