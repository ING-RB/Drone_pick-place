function h = parallelplot(varargin)
% PARALLELPLOT Create parallel coordinates plot
% 
%     parallelplot(tbl) creates a parallel coordinates plot from the
%     table tbl. Each line in the plot represents a row in the table, and 
%     each coordinate variable in the plot corresponds to a column in the 
%     table. The software plots all table columns by default. 
%  
%     parallelplot(tbl,'CoordinateVariables', coordvars) creates a
%     parallel coordinates plot from the coordvars variables in the table
%     tbl.
%  
%     parallelplot(___,'GroupVariable',grpvar) uses the table variable
%     specified by grpvar to group the lines in the plot. Specify this
%     option after any of the input argument combinations in the previous
%     syntaxes.
%  
%     parallelplot(data) creates a parallel coordinates plot from the
%     numeric matrix data.
% 
%     parallelplot(data,’CoordinateData’,coorddata) creates a parallel
%     coordinates plot from the coorddata columns in the matrix data.
%  
%     parallelplot(___,'GroupData',grpdata) uses the data in grpdata to
%     group the lines in the plot. Specify this option after any of the
%     previous input argument combinations for numeric matrix data.
%  
%     parallelplot(___,Name,Value) specifies additional options using
%     one or more name-value pair arguments. For example, you can specify
%     the data normalization method for coordinates with numeric values.
% 
%     parallelplot(parent,___) creates the parallel coordinates plot in
%     the figure, panel, or tab specified by parent.
%
%     p = parallelplot(___) returns the ParallelCoordinatesPlot object. 
%     Use p to modify properties of the chart after creating it.

%   Copyright 2019-2022 The MathWorks, Inc.

% Capture the input arguments and initialize the extra name/value pairs to
% pass to the ParallelCoordinatesPlot constructor.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);

args = varargin;
parent = gobjects(0);

% Check if the first input argument is a graphics object to use as parent.
if ~isempty(args) && isa(args{1},'matlab.graphics.Graphics')
    % parallelplot(parent,___)
    parent = args{1};
    args = args(2:end);
end

% Check for the table vs. matrix syntax.
if isempty(args)
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif isa(args{1},'tabular')
    % Table syntax
    %   parallelcoordinates(tbl,Name,Value)
    [extraArgs, args] = parseTableInputs(args);
elseif isnumeric(args{1})
    % Matrix syntax
    %   parallelplot(data,Name,Value)
    [extraArgs, args] = parseMatrixInputs(args);
else
    error(message('MATLAB:graphics:parallelplot:InvalidArguments'));
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
    % Construct the ParallelCoordinatesPlot.
    constructor = @(varargin) matlab.graphics.chart.ParallelCoordinatesPlot(varargin{:},args{:});
    try
        p = matlab.graphics.internal.prepareCoordinateSystem('matlab.graphics.chart.ParallelCoordinatesPlot',parent, constructor);
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
    
    % Construct parallelplot without replacing gca
    try
        p = matlab.graphics.chart.ParallelCoordinatesPlot('Parent', parent, args{:});
    catch e
        throw(e)
    end
end

% Make the new parallelplot the CurrentAxes
fig = ancestor(p,'figure');
if isscalar(fig)
    fig.CurrentAxes = p;
end

% Prevent outputs when not assigning to variable.
if nargout > 0
    h = p;
end

end

function [extraArgs, args] = parseTableInputs(args)
% Parse the table syntx:
%   parallelcoordinates(tbl,Name,Value)
%   parallelcoordinates(tbl,vars,Name,Value)

import matlab.graphics.chart.internal.validateTableSubscript

% Collect the first input argument.
tbl = args{1};
args = args(2:end);

extraArgs = {'SourceTable', tbl};

% Look for GroupVariable in the remaining name-value pairs.
inds = find(strcmpi('GroupVariable',args(1:2:end-1)));
p = properties('matlab.graphics.chart.ParallelCoordinatesPlot');
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
        throwAsCaller(MException(message('MATLAB:graphics:parallelplot:GroupVariableNameValuePair')));
    end
end
end

function [extraArgs, args] = parseMatrixInputs(args)
% Parse the matrix syntax:
%   parallelplot(data,Name,Value)
if numel(args) < 1
    throwAsCaller(MException(message('MATLAB:graphics:parallelplot:InvalidArguments')));
end

if (isnumeric(args{1}) || iscategorical(args{1}))    
    % Obtain data
    data = args{1};
else
    throwAsCaller(MException(message('MATLAB:graphics:parallelplot:InvalidArguments')));
end

% Validate data
if ~ismatrix(data)
    throwAsCaller(MException(message('MATLAB:graphics:parallelplot:InvalidX')));
end

% Build the name-value pairs for the matrix syntax.
extraArgs = {'Data', data};
args = args(2:end);
end

function validateParent(parent)
if ~isa(parent, 'matlab.graphics.Graphics') || ~isscalar(parent)
    % Parent must be a valid scalar graphics object.
    throwAsCaller(MException(message('MATLAB:graphics:parallelplot:InvalidParent')));
elseif ~isvalid(parent)
    % Parent cannot be a deleted graphics object.
    throwAsCaller(MException(message('MATLAB:graphics:parallelplot:DeletedParent')));
elseif isa(parent,'matlab.graphics.axis.AbstractAxes')
    % ParallelCoordinatesPlot cannot be a child of Axes.
    throwAsCaller(MException(message('MATLAB:hg:InvalidParent',...
        'ParallelCoordinatesPlot', fliplr(strtok(fliplr(class(parent)), '.')))));
end
end
