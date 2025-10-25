function disableLegacyPadding(graphicsHandle)
%DISABLELEGACYPADDING turns off legacy panel padding
%
%   All panels created in a uifigure use default padding.
%   All panels created in a figure use legacy padding to ease the
%   transition to the new MATLAB desktop
%
%   Use this method to move to the default padding which is slightly looser
%   than the legacy padding
%
%   graphicsHandle - must be either a panel or figure handle
%   Example:
%    disableLegacyPadding(uipanel)
%    disableLegacyPadding(uifigure);
%

%   Copyright 2024 MathWorks, Inc.

isAPanel = isa(graphicsHandle, 'matlab.ui.container.Panel');
isAFigure =  isa(graphicsHandle, 'matlab.ui.Figure');

if isAPanel
    set(graphicsHandle,'EnableLegacyPadding',false);
elseif isAFigure
    % Set the setting so all panels created in the figure use
    % the correct padding
    set(graphicsHandle,'DefaultUipanelEnableLegacyPadding',false)
    set(graphicsHandle,'DefaultUibuttongroupEnableLegacyPadding',false)

    % Take any descendents of the figure and change the padding
    panelHandles = findall(graphicsHandle,'EnableLegacyPadding',true);
    if(size(panelHandles)>0)
        set(panelHandles,'EnableLegacyPadding',false)
    end
else
    error(message('MATLAB:Uipanel:LegacyPaddingInvalidValue'));
end
end