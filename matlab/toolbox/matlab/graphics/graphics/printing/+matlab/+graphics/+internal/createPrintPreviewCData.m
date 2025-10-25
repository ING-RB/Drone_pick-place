function createPrintPreviewCData(axPreview, fig)
% This undocumented helper function is for internal use.

% Creates CData for the figure that is used in the printpreview GUI

%   Copyright 1984-2017 The MathWorks, Inc.

zoom = getappdata(axPreview, 'ZoomFactor');
if isempty(zoom) 
    zoom=1; 
else 
    zoom = ceil(zoom); 
end
res = get(groot,'ScreenPixelsPerInch')*zoom;
DPISwitch = ['-r' num2str(ceil(res))];
tic;

% Get CData for Printing
%%% TODO: Enable this by default when printing can print with disruptions 
if isappdata(fig,'PrintPreview_NOCDATA') && getappdata(fig,'PrintPreview_NOCDATA')
    % Create dummy cdata without calling print command.  
    cdata = rand(25,25,2);
else  
    % Disables deprecation warning for printing with ui components and
    % raster graphics. This is called when printpreview is ran and disables
    % the warnings in cmd window.
    cl_ui = matlab.graphics.internal.export.disableWarningInScope( ...
        'MATLAB:print:ExcludesUIInFutureRelease');
    cl_img = matlab.graphics.internal.export.disableWarningInScope( ...
        'MATLAB:print:RasterNotSupportedInFutureRelease');
    % Else call "print" and get the real CDATA. 
    cdata = flip(print(fig, DPISwitch, '-RGBImage'),1);
end


if ~ishghandle(fig), return; end
refresh(fig);
elapse = toc;

if ishghandle(axPreview)
    %Set the cdata as appdata in axPreview
    setappdata(axPreview, 'CData', cdata);
    setappdata(axPreview, 'ElapseTime',elapse)
end
