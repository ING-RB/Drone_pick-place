function leg = bubblelegend(varargin)
% BUBBLELEGEND creates a bubble legend in the current axes.
%
% BUBBLELEGEND(txt) specifies a title for the legend. Specify txt as a
% character vector, cell array of character vectors, or a string array.
%
% BUBBLELEGEND(__,Name,Value) sets properties of the legend using one or
% more name-value pair arguments.
%
% % BUBBLELEGEND(target,__) creates the legend in the specified target 
% axes.
%
% blgd = BUBBLELEGEND(__) returns the BubbleLegend object. Use blgd to set
% properties on the legend after creating it.
%
%     Examples:
%         % Position the legend in the upper-left corner of the axes
%         bubblelegend('My Legend','Location','northwest')
%
%         % Specify a horizontal legend 
%         bubblelegend('MyLegend','Style','horizontal')
%
%         % Specify a telescopic legend with overlapping bubbles
%         bubblelegend('My Legend','Style','telescopic')
%
%         % Display only two bubbles in the legend to save space
%         bubblelegend('My Legend','NumBubbles',2)

%   Copyright 2020 The MathWorks, Inc.

narg = nargin;
args = varargin;
hAxes = matlab.graphics.Graphics.empty;


% Grab target for the bubblelegend
if narg > 0 && isa(args{1}, 'matlab.graphics.Graphics')
    hAxes = args{1};
    args = args(2:end);
    narg = narg - 1;

end

% Grab the title which only exists if there are an odd number of arguments
% left.

if mod(numel(args), 2) == 0
    titleProvided = false;
elseif narg > 0 && isstring(args{1}) || ischar(args{1}) || iscell(args{1}) || isnumeric(args{1})
    % Remove title before processing Name/Value pairs.
    try
        title = string(args{1});
        titleProvided = true;
        args = args(2:end);
    catch err
        throw(err);
    end
else
    error(message('MATLAB:bubblelegend:InvalidTitle'));
end

% Check if Parent or Axes are provided in name value pairs.
deleteIndex = [];
parent = gobjects(0);
for i = 1:2:numel(args)
    name = args{i};
    if (ischar(name) || isstring(name)) && ~isempty(name)
        if strcmpi('Parent', name)
            parent = args{i+1};
            deleteIndex([end+1 end+2]) = [i i+1];
        elseif strcmpi('Axes', name)
            hAxes = args{i+1};
            deleteIndex([end+1 end+2]) = [i i+1];
        end
    end
end
args(deleteIndex) = [];

% Populate axes and parent if not specified. 
if ~isempty(hAxes) && (~isscalar(hAxes) || ~isvalid(hAxes) || ~isa(hAxes, 'matlab.graphics.mixin.LegendTarget'))
    error(message('MATLAB:bubblelegend:InvalidTarget'));
elseif isempty(hAxes) && isempty(parent)
    hAxes = gca;
elseif ~isempty(hAxes) && isempty(parent)
    parent = hAxes.Parent;
elseif isempty(hAxes) && ~isempty(parent)
    hAxes = matlab.graphics.chart.internal.getAxesInParent(parent);
elseif ~isempty(hAxes) && ~isempty(parent) && ~isequal(hAxes.Parent, parent)
    error(message('MATLAB:bubblelegend:TargetParentNotEqual'));
end


if isempty(hAxes.BubbleLegend) || ~isvalid(hAxes.BubbleLegend)
    try
        hBLegend = matlab.graphics.illustration.BubbleLegend('Parent', parent, 'Axes', hAxes, args{:});
    catch err
        throwAsCaller(err);
    end
else
    if ~isempty(args)
        set(hAxes.BubbleLegend, args{:});
    end
    hBLegend = hAxes.BubbleLegend;
end


% If axes is 3D or polar, update to different location.
camUp = hAxes.Camera.UpVector;
if ~(isequal(hAxes.View,[0,90]) && isequal(abs(camUp),[0 1 0]))
    hBLegend.Location_I = 'northeastoutside';
elseif isa(hAxes, 'matlab.graphics.axis.PolarAxes')
    hBLegend.Location_I = 'eastoutside';
end

% Only want to update the title if the user specified or delete it if title
% is specified to be deleted. 
if titleProvided && nargin ~= 0
    hBLegend.Title.String = title;
end

% Prevent output when not assigning to variable
if nargout > 0
    leg = hBLegend;
end
end

