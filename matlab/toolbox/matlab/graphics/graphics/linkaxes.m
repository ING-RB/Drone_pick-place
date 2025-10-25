function linkaxes(ax,option,varargin)
%LINKAXES Synchronize limits of specified axes
%  Use LINKAXES to synchronize the individual axis limits
%  on different subplots within a figure. Calling linkaxes
%  will make all input axis have identical limits. This is useful
%  when you want to zoom or pan in one subplot and display
%  the same range of data in another subplot.
%
%  LINKAXES(AX) Links x, y and z axis limits of an axes
%  specified in AX.
%
%  LINKAXES(AX,OPTION) Links the axes AX according to the
%  specified option. The option argument can be one of the
%  following strings:
%        'x'   ...link x-axis only
%        'y'   ...link y-axis only
%        'z'   ...link z-axis only
%        String combination of x, y and z will link their respective axes.
%        'off' ...remove linking
%
%  See the LINKPROP function for more advanced capabilities
%  that allows linking object properties on any graphics object.
%
%  Example (Linked Zoom & Pan):
%
%  ax(1) = subplot(2,2,1);
%  plot(rand(1,10)*10,'Parent',ax(1));
%  ax(2) = subplot(2,2,2);
%  plot(rand(1,10)*100,'Parent',ax(2));
%  linkaxes(ax,'x');
%  % Interactively zoom and pan to see link effect
%
%  See also LINKPROP, ZOOM, PAN.

% Copyright 2003-2024 The MathWorks, Inc.

extra = varargin;
if nargin==0
    fig = get(0,'CurrentFigure');
    canvas = fig.getCanvas;
    if isempty(fig), return; end
    ax = findobj(gcf,'type','axes');
    nondatachild = logical([]);
    for k=length(ax):-1:1
        nondatachild(k) = isappdata(ax(k),'NonDataObject');
    end
    ax(nondatachild) = [];
    option = 'xyz';
    
else
    if nargin==1
        option = 'xyz';
    end
    naxin = length(ax);
    ax = ax(isgraphics(ax,'matlab.graphics.axis.AbstractAxes'));
    if ~isempty(ax) && length(ax)<naxin
        warning(message('MATLAB:linkaxes:RequireDataAxes'));
    end
    %get the figure object
    if ~isempty(ax)
        nearestParent = ancestor(ax(1), 'matlab.ui.internal.mixin.CanvasHostMixin');
        canvas = nearestParent.getCanvas;
    end
    
    % Ensure that no axes are repeated.
    [~,I] = unique(ax);
    Idup = setdiff(1:length(ax),I);
    ax(Idup) = [];

    option = lower(option);
end


if isempty(ax)
    error(message('MATLAB:linkaxes:InvalidFirstArgument'));
end
ax = handle(ax);

if any(~iscartesian(ax))
    error(message('MATLAB:linkaxes:CartesianAxes'));
end

% Remove any prior links to input handles
preserveLinks = 'off';
if ~strcmpi(option, 'off') && ~isempty(extra)
    for idx = 1:length(extra)
        if ischar(extra{idx}) && strcmpi(extra{idx}, 'PreserveLinks') && length(extra) > idx &&...
            ischar(extra{idx+1}) && strcmp(extra{idx+1}, 'on')
            preserveLinks = 'on';
            break;
        end
    end
end
if strcmp(preserveLinks, 'off')
    localRemoveLink(ax)
end

% Flush graphics queue so that all axes
% are forced to update their limits. Otherwise,
% calling XLimMode below may get the wrong axis limits
drawnow nocallbacks;

% Create new link
useClientSideInteractions = ~isempty(canvas) && isprop(canvas,'ControlManager') ...
    && ~matlab.graphics.interaction.internal.hasMultiCanvasLinkedAxes(ax) ...
    && ~matlab.graphics.interaction.internal.hasMultiTargetLinkedAxes(ax);

KEY = 'graphics_linkaxes';

if (strcmp(option,'off'))
    for idx=1:length(ax)
        if isappdata(ax(idx), KEY)
            rmappdata(ax(idx),KEY)
        end
    end

    % Update the interactions on the axes after setting the appdata and
    % before sending message to client, to ensure AxesControls exist 
    % and the correct interactions are installed
    arrayfun(@(a) updateInteractionsOnAxes(a), ax);

    if (useClientSideInteractions)
        canvas.ControlManager.linkControls(ax, 'off', 'axes', 'off');
    end
else
    if (~valid_arguments(option))
        error(message('MATLAB:linkaxes:InvalidSecondArgument'));
    end

    linkProps = {};
    if (contains(option,'x'))
        syncLimits(ax,'ActiveXRuler');
        linkProps{end+1} = 'XLim';
    end
    if (contains(option,'y'))
        syncLimits(ax,'ActiveYRuler');
        linkProps{end+1} = 'YLim';
    end
    if (contains(option,'z'))
        syncLimits(ax,'ActiveZRuler');
        linkProps{end+1} = 'ZLim';
    end
    hlink = linkprop(ax,linkProps,extra{:});

    % MCOS graphics cannot rely on custom machinery in hgload to restore
    % linkaxes. Instead, create a matlab.graphics.internal.LinkAxes to wrap the
    % linkprop which will restore the linkaxes when it is de-serialized.
    for idx=1:length(ax)
        axHlink = hlink;
        if isappdata(ax(idx),KEY) && ~isempty(getappdata(ax(idx), KEY)) && ~strcmp(preserveLinks, 'off')
            existingLinkProps = getappdata(ax(idx),KEY).LinkProp;
            axHlink(end+1) = existingLinkProps;
        end
        setappdata(ax(idx),KEY,matlab.graphics.internal.LinkAxes(axHlink));
    end

    % Update the interactions on the axes after setting the appdata and
    % before sending message to client, to ensure AxesControls exist before linking axes, 
    % and ensuring the correct interactions are installed
    arrayfun(@(a) updateInteractionsOnAxes(a), ax);

    if (useClientSideInteractions)
        canvas.ControlManager.linkControls(ax, option, 'axes', hlink(1).PreserveLinks);
    end
end

%--------------------------------------------------%
function localRemoveLink(ax)

KEY = 'graphics_linkaxes';

for n = 1:length(ax)
    % Remove this handle from previous link object
    hlink = getappdata(ax(n),KEY);
    if ~isempty(hlink)
        removetarget(hlink,ax(n));
    end
end


% detects whether the input arguments are valid

%--------------------------------------------------%
function [isValid] = valid_arguments(arg)
if length(arg) ~= length(unique(arg))
    isValid = false;
    return;
end
invalidChars = erase(arg,{'x','y','z'});
isValid = strlength(invalidChars) == 0;

%--------------------------------------------------%
function out = iscartesian(ax)
out = true(1,length(ax));
for n = 1:length(ax)
    out(n) = isa(ax(n),'matlab.graphics.axis.Axes');
end

%--------------------------------------------------%
function syncLimits(ax,prop)
ruler = ax(1).(prop);
bestLim = ruler.Limits;
% Can compare different numerics but class might be different.
if isnumeric(bestLim)
    limType = 'numeric';
else
    limType = class(bestLim);
end

if iscategorical(bestLim)
    firstCategories = ruler.Categories;
end

for k = 1:length(ax)
    axLim = ax(k).(prop).Limits;
    if (isnumeric(axLim) && ~strcmp(limType, 'numeric')) || ~isa(axLim,limType)
        throwAsCaller(MException((message('MATLAB:linkaxes:CompatibleData'))));
    end
    
    if iscategorical(axLim)
        currentCategories = ax(k).(prop).Categories;
        
        if ~isequal(firstCategories, currentCategories)
            throwAsCaller(MException((message('MATLAB:linkaxes:CompatibleCategories'))));
        end
        
        lower = min(double(axLim(1)),double(bestLim(1)));
        upper = max(double(axLim(2)),double(bestLim(2)));
        bestLim = ax(1).(prop).makeNonNumeric([lower, upper]);
        
    else
        bestLim = [min(axLim(1),bestLim(1)) max(axLim(2),bestLim(2))];
    end
    
end

set(ax,[prop(7) 'LimMode'],'manual')
set(ax, [prop(7) 'Lim'], bestLim)

%--------------------------------------------------%
function updateInteractionsOnAxes(ax)
if(matlab.graphics.interaction.internal.isWebAxes(ax))
    ax.InteractionContainer.clearList;
    ax.InteractionContainer.updateInteractions;
end

