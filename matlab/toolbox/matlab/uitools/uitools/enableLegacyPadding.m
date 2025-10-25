function enableLegacyPadding(graphicsHandle)
%ENABLELEGACYPADDING turns on legacy panel padding
%
%   All panels or button groups created in a uifigure use default padding.
%   All panels or button groups created in a figure use legacy padding to ease the
%   transition to the new MATLAB desktop
%
%   Use this method to move to the legacy padding which is slightly tighter
%   than the default padding
%
%   graphicsHandle - must be either a panel or figure
%   Example:
%    enableLegacyPadding(uipanel)
%    enableLegacyPadding(uifigure);
%

%   Copyright 2024 MathWorks, Inc.

isAPanel = isa(graphicsHandle, 'matlab.ui.container.Panel');
isAFigure =  isa(graphicsHandle, 'matlab.ui.Figure');

if isAPanel
    set(graphicsHandle,'EnableLegacyPadding',true);
elseif isAFigure
    % Set the setting so all panels created in the figure use
    % the correct padding
    set(graphicsHandle,'DefaultUipanelEnableLegacyPadding',true)
    set(graphicsHandle,'DefaultUibuttongroupEnableLegacyPadding',true)

    % Take any descendents of the figure and change the padding
    panelHandles = findall(graphicsHandle,'EnableLegacyPadding',false);
    if(size(panelHandles)>0)
        set(panelHandles,'EnableLegacyPadding',true)
    end
else
    error(message('MATLAB:Uipanel:LegacyPaddingInvalidValue'));
end
end