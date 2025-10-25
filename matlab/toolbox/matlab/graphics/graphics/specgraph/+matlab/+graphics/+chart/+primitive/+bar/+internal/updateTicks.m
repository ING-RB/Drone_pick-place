function updateTicks(ax, maindim, orthodim, data, updateOrthoTicks)
% Update the axes ticks based on the bars

%   Copyright 2014-2024 The MathWorks, Inc.

% maindim is the dimension that bar should pick ticks for, and orthodim is
% the other dimension.

tickProperty = maindim + "Tick";
tickvals = ax.(tickProperty + "_I");
if iscategorical(tickvals)
    return
end

tickModeProperty = tickProperty + "Mode";
sortedX = sort(data);
appdataproperty = "barseries" + tickProperty;
appdataexists = isappdata(ax, appdataproperty);
% Set ticks if there are less than 16, and the tick values match the values
% in an appdata cache, which indicates that they were previously set by this
% function (and so, even though they aren't 'auto', they are controlled by 
% MATLAB.
if ~appdataexists || ...
        isequal(tickvals, getappdata(ax, appdataproperty)) || ...
        ax.(tickModeProperty) == "auto"

    ax.(tickModeProperty) = "auto";
    if appdataexists
        rmappdata(ax, appdataproperty)
    end

    if all(floor(sortedX)==sortedX,'all') && numel(sortedX) < 16
        xDiff = diff(sortedX);
        if all(xDiff > 0)
            tickvals = double(sortedX); % ticks must be doubles
            rulerName = "Active" + maindim + "Ruler";
            if isprop(ax, rulerName)
                tickvals = num2ruler(tickvals, ax.(rulerName));
            end
            ax.(tickProperty) = tickvals;
            setappdata(ax, appdataproperty, tickvals(:)');
        end
    end
end

% Check orthogonal ticks to see if they have previously set ticks by bar
% that need to be cleared
orthoTickProperty = orthodim + "Tick";
appdataproperty = "barseries" + orthoTickProperty;
appdataexists = isappdata(ax, appdataproperty);
orthoTickvals = ax.(orthoTickProperty + "_I");

% Only set the orthogonal ticks if the horizontal property of bar was
% changed AND there is appdata AND the appdata is equal to the current
% orthogonal ticks
if updateOrthoTicks && ...
    appdataexists && ...
    isequal(orthoTickvals, getappdata(ax, appdataproperty))
    ax.(orthodim + "TickMode") = 'auto';
end

% Unconditionally clear orthogonal appdata
if appdataexists
    rmappdata(ax, appdataproperty);
end
