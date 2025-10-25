function h = scatterhistogram(varargin)
% SCATTERHISTOGRAM Create scatterhistogram chart
%   SCATTERHISTOGRAM(tbl,xvar,yvar) creates a scatterhistogram from
%   the table tbl. The xvar input indicates the table variable to display 
%   along the x-axis. The yvar input indicates the table variable to 
%   display along the y-axis.
%
%   SCATTERHISTOGRAM(tbl,xvar,yvar,'GroupVariable',grpvar) uses the
%   table variable specified by grpvar to group observations specified by
%   xvar and yvar. 
%
%   SCATTERHISTOGRAM(xvalues,yvalues) specifies the data for the
%   values that appear along the x-axis and y-axis of the scatterplot
%
%   SCATTERHISTOGRAM(xvalues,yvalues,'GroupData',grpvalues) uses
%   the data specified by grpvalues for grouping xvalues and yvalues.
%
%   SCATTERHISTOGRAM(___,Name,Value) specifies additional options for
%   the scatterhistogram using one or more name-value pair arguments.
%   Specify the options after all other input arguments.
%
%   SCATTERHISTOGRAM(parent,___) creates the scatterhistogram in the
%   figure, panel, or tab specified by parent.
% 
%   s = SCATTERHISTOGRAM(___) returns the ScatterHistogramChart object. 
%   Use s to modify properties of the chart after creating it.

%   Copyright 2019-2022 The MathWorks, Inc.

% Capture the input arguments and initialize the extra name/value pairs to
% pass to the ScatterHistogramChart constructor.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
args = varargin;
parent = gobjects(0);

% Check if the first input argument is a graphics object to use as parent.
if ~isempty(args) && isa(args{1},'matlab.graphics.Graphics')
    % scatterhistogram(parent,___)
    parent = args{1};
    args = args(2:end);
end

% Check for the table vs. matrix syntax.
if isempty(args)
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif isa(args{1},'tabular')
    % Table syntax
    %   scatterhistogram(tbl,xvar,yvar,Name,Value)
    [extraArgs, args] = parseTableInputs(args);
elseif isnumeric(args{1}) || iscategorical(args{1})
    % Matrix syntax
    %   scatterhistogram(xdata,ydata,Name,Value)
    [extraArgs, args] = parseMatrixInputs(args);
else
    error(message('MATLAB:graphics:scatterhistogram:InvalidArguments'));
end

% Look for a Parent name-value pairs.
inds = find(strcmpi('Parent',args(1:2:end)));
if ~isempty(inds) && (inds(end)*2)<=numel(args)
    inds = inds*2-1;
    parent = args{inds(end)+1};
    args([inds inds+1]) = [];
end

% Look for a Position, InnerPosition, OuterPosition, name-value pairs.
posArgsPresent = ~isempty(find(strcmpi('OuterPosition',args(1:2:end)),1)) || ...
    ~isempty(find(strcmpi('InnerPosition',args(1:2:end)),1)) || ...
    ~isempty(find(strcmpi('Position',args(1:2:end)),1));

% Build the full list of name-value pairs.
args = [extraArgs args];

% If position not specified, use replaceplot behavior
if ~posArgsPresent
    if ~isempty(parent)
        validateParent(parent);
    end
    % Construct the ScatterHistogramChart.
    constructor = @(varargin) matlab.graphics.chart.ScatterHistogramChart(varargin{:},args{:});
    try
        s = matlab.graphics.internal.prepareCoordinateSystem('matlab.graphics.chart.ScatterHistogramChart',parent, constructor);
    catch e
        throw(e)
    end
else % Caller specified a position
    % Check parent argument if specified
    if isempty(parent)
        % If position specified, but not parent, assume current figure
        parent = gcf;
    else
        validateParent(parent);
    end
    
    % Construct scatterhistogram without replacing gca
    try
        s = matlab.graphics.chart.ScatterHistogramChart('Parent', parent, args{:});
    catch e
        throw(e)
    end
end

% Make the new scatterhistogram the CurrentAxes
fig = ancestor(s,'figure');
if isscalar(fig)
    fig.CurrentAxes = s;
end

% Prevent outputs when not assigning to variable.
if nargout > 0
    h = s;
end
end

function [extraArgs, args] = parseTableInputs(args)
% Parse the table syntx:
%   scatterhistogram(tbl,xvar,yvar,Name,Value)

import matlab.graphics.chart.internal.validateTableSubscript

% Three input arguments are required for the table syntax.
if numel(args)<3
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidTableArguments')));
end

% Collect the first three input arguments.
tbl = args{1};
xvar = args{2};
yvar = args{3};
args = args(4:end);

% Validate the xvar table subscript.
[varname, xvar, err] = validateTableSubscript(tbl, xvar, 'XVariable');
if ~isempty(err)
    throwAsCaller(err);
elseif isempty(varname)
    throwAsCaller(MException(message('MATLAB:Chart:NonScalarTableSubscript', 'XVariable')));
end

% Validate the yvar table subscript.
[varname, yvar, err] = validateTableSubscript(tbl, yvar, 'YVariable');
if ~isempty(err)
    throwAsCaller(err);
elseif isempty(varname)
    throwAsCaller(MException(message('MATLAB:Chart:NonScalarTableSubscript', 'YVariable')));
end

% Build the name-value pairs for the table syntax.
extraArgs = {'SourceTable', tbl, 'XVariable', xvar, 'YVariable', yvar};

% Look for GroupVariable in the remaining name-value pairs.
inds = find(strcmpi('GroupVariable',args(1:2:end-1)));
p = properties('matlab.graphics.chart.ScatterHistogramChart');
if ~isempty(inds)
    % Found a GroupVariable.
    inds = inds*2-1;
    cvar = args{inds(end)+1};
    
    % Validate the GroupVariable, but do not remove it from the list of
    % name-value pairs.
    [~, ~, err] = validateTableSubscript(tbl, cvar, 'GroupVariable');
    if ~isempty(err)
        throwAsCaller(err);
    end
elseif ~isempty(args) && ...
        ((~ischar(args{1}) && ~(isstring(args{1}) && isscalar(args{1})))...
        || ~ismember(args{1},p))
    % The fourth input argument is not a recognized property name. This
    % suggests it may be a table subscript meant to be the GroupVariable.
    % Check if the argument specified happens to refer to a single variable
    % in the table.
    [~, ~, err] = validateTableSubscript(tbl, args{1},'');
    if isempty(err)
        % The fourth input argument matches a single variable in the table,
        % generate error indicating the correct syntax.
        throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:GroupVariableNameValuePair')));
    end
end
end

function [extraArgs, args] = parseMatrixInputs(args)
% Parse the matrix syntax:
%   scatterhistogram(xdata,ydata,Name,Value)
if numel(args) < 2
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidArguments')));
end

if (isnumeric(args{1}) || iscategorical(args{1})) &&...
        (isnumeric(args{2}) || iscategorical(args{2}))
    
    % Obtain xdata and ydata
    xdata = args{1};
    ydata = args{2};
else
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidArguments')));
end

% Validate xdata and ydata
if ~isvector(xdata) || ~isvector(ydata)
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidXOrYSize')));
end

if length(xdata) ~= length(ydata)
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidXOrYSize')));
end

% Build the name-value pairs for the matrix syntax.
extraArgs = {'XData', xdata(:), 'YData', ydata(:)};
args = args(3:end);
end

function validateParent(parent)
if ~isa(parent, 'matlab.graphics.Graphics') || ~isscalar(parent)
    % Parent must be a valid scalar graphics object.
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidParent')));
elseif ~isvalid(parent)
    % Parent cannot be a deleted graphics object.
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:DeletedParent')));
elseif isa(parent,'matlab.graphics.axis.AbstractAxes')
    % ScatterHistogramChart cannot be a child of Axes.
    throwAsCaller(MException(message('MATLAB:hg:InvalidParent',...
        'ScatterHistogramChart', fliplr(strtok(fliplr(class(parent)), '.')))));
end
end
