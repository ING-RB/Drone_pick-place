function hh = basicImageDisplay(fig_handle,ax_handle,...
                                cdata, cdatamapping, clim, map, ...
                                xdata, ydata, interpolation, varargin)
%basicImageDisplay Display image for IMSHOW.
%
% basicImageDisplay(hFig,hAx,cdata,cdatamapping,clim,map,xdata,ydata)
% displays an image for use in imtool/imshow contexts.
%
% basicImageDisplay(hFig,hAx,cdata,cdatamapping,clim,map,xdata,ydata,isSpatiallyReferenced)
% displays an image for use in imtool/imshow contexts. When the optional
% input argument isSpatiallyReferenced is true, the axes limits are
% displayed regardless of the ImshowAxesVisible property state.

%   Copyright 1993-2023 The MathWorks, Inc.

if isempty(varargin)
    isSpatiallyReferenced = false;
else
    isSpatiallyReferenced = varargin{1};
end

% Use default XData, YData whenever possible to keep as many modes automatic.
if isempty(xdata) && isempty(ydata)
    hh = image(cdata, ...
           'BusyAction', 'cancel', ...
           'Parent', ax_handle, ...
           'CDataMapping', cdatamapping, ...
           'Interruptible', 'off',...
           'Interpolation', interpolation);
else
    if isempty(xdata)
        xdata = [1 size(cdata,2)];
    end
    
    if isempty(ydata)
        ydata = [1 size(cdata,1)];
    end
    
    hh = image(xdata,ydata,cdata, ...
           'BusyAction', 'cancel', ...
           'Parent', ax_handle, ...
           'CDataMapping', cdatamapping, ...
           'Interruptible', 'off',...
           'Interpolation', interpolation);
end
% Set axes and figure properties if necessary to display the 
% image object correctly.

if ~matlab.internal.capability.Capability.isSupported(...
        matlab.internal.capability.Capability.LocalClient)
    % For MATLAB Online, restrict the max resolution size to be
    % 512. Larger images require a significantly higher
    % bandwidth than we have, so the time to transfer the data
    % to the client in ML Online is very poor. This choice
    % degrades rendering quality for online users, but it keeps
    % performance to a more acceptable level. Desktop users
    % will not be impacted.
    hh.MaxRenderedResolution = 512;
end

% If spatially referenced syntax is provided, we ignore axes visibility
% preference and show the axes limits.
if isSpatiallyReferenced
    show_axes = 'on';
else
    s = settings;
    if(s.matlab.imshow.ShowAxes.ActiveValue)
        show_axes = 'on';
    else
        show_axes = 'off';
    end
    
end

set(ax_handle, ...
    'YDir','reverse',...
    'TickDir', 'out', ...
    'XGrid', 'off', ...
    'YGrid', 'off', ...
    'DataAspectRatio', [1 1 1], ...
    'PlotBoxAspectRatioMode', 'auto', ...
    'Visible', show_axes);

if ~isempty(map)
    % Here we assume ax_handle is a scalar graphics object with a property
    % named either Colormap or ColorSpace, which contains a property named
    % Colormap
    if isprop(ax_handle,'Colormap')
        ax_handle.Colormap = map;
    else
        ax_handle.ColorSpace.Colormap = map;
    end
end

if ~isempty(clim)
    set(ax_handle, 'CLim', clim);
end
