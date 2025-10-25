function h = heatmap(varargin)
% HEATMAP Create heatmap chart from a tall table
%   h = HEATMAP(tbl,xvar,yvar)
%   h = HEATMAP(tbl,xvar,yvar,'ColorVariable',cvar)
%   h = HEATMAP(cdata)
%   h = HEATMAP(xvalues,yvalues,cdata)
%   h = HEATMAP(___,Name,Value)
%   h = HEATMAP(parent,___)
%
%   Limitations for tall table input:
%   1. ColorMethod 'none' and 'median' are not supported.
%   2. The HeatmapChart object returned contains only the summary data, not
%      the original tall table data.
%
%   See also: HEATMAP, TALL.

%   Copyright 2017-2024 The MathWorks, Inc.


% No matter whether we're dealing with numeric or table data, the first
% input must be tall.
tall.checkIsTall(upper(mfilename), 1, varargin{1});

% For numeric inputs the data specifies the actual values to plot and is
% expected to be small. We simply gather it and call standard heatmap. Only
% the table summary work-flow needs special implementation.
if varargin{1}.Adaptor.Class == "table"
    h = iTallTableHeatmap(varargin{:});
else
    [varargin{:}] = gather(varargin{:});
    h = heatmap(varargin{:});
end
end



function h = iTallTableHeatmap(varargin)
% Heatmap for table input
tbl = varargin{1};
if nargin<3
    error(message("MATLAB:graphics:heatmap:InvalidTableArguments"));
end

% All other args should be in-memory
tall.checkNotTall(upper(mfilename), 1, varargin{2:end});

% xvar and yvar should be valid table variable identifiers
xvar = varargin{2};
yvar = varargin{3};
iValidateTableSubscript(tbl, xvar, 'XVariable');
iValidateTableSubscript(tbl, yvar, 'YVariable');

% Now validate the remaining args
[parent, cvar, cmethod, title, otherArgs] = iParseParamValues(varargin{4:end});
if ~isempty(cvar)
    iValidateTableSubscript(tbl, cvar, 'ColorVariable');
end
% We don't support MEDIAN
if ismember(cmethod, ["median" "none"])
    error(message("MATLAB:bigdata:array:HeatmapColorMethod", cmethod));
end

[xdata, ydata, cdata] = iAggregateTallData(tbl, xvar, yvar, cvar, cmethod);

% Now run the calculation
[xdata, ydata, cdata] = gather(xdata, ydata, cdata);

% Call built-in heatmap to do the actual drawing, passing along any
% trailing args that aren't affected by us modifying data.
h = heatmap(parent, xdata, ydata, cdata, otherArgs{:});

varnames = iGetTableVarnames(tbl);
if ischar(xvar) || isstring(xvar)
    xvarname = xvar;
else
    xvarname= varnames{xvar};
end
h.XLabel = xvarname;
if ischar(yvar) || isstring(yvar)
    yvarname = yvar;
else
    yvarname = varnames{yvar};
end
h.YLabel = yvarname;
if isempty(cvar) || ischar(cvar) || isstring(cvar)
    cvarname = cvar;
else
    cvarname = varnames{cvar};
end

if isempty(title)
    % No user-supplied title, so we need to create one
    t = iCreateTitleText(cmethod, xvarname, yvarname, cvarname);
    if t ~= ""
        h.Title = t;
    end
else
    h.Title = title;
end
end


function names = iGetTableVarnames(tbl)
% Helper to extract the variable names from a tall table
props = subsref(tbl, substruct('.','Properties'));
names = props.VariableNames;
end

function iValidateParent(parent)
% Helper to validate that the initial argument is a valid parent for
% heatmap. We do this first so that we run any tall calculations only to
% error later.

if ~isa(parent, 'matlab.graphics.Graphics') || ~isscalar(parent)
    % Parent must be a valid scalar graphics object.
    throwAsCaller(MException(message("MATLAB:graphics:heatmap:InvalidParent")));
elseif ~isvalid(parent)
    % Parent cannot be a deleted graphics object.
    throwAsCaller(MException(message("MATLAB:graphics:heatmap:DeletedParent")));
elseif isa(parent,'matlab.graphics.axis.AbstractAxes')
    % HeatmapChart cannot be a child of Axes.
    throwAsCaller(MException(message("MATLAB:hg:InvalidParent",...
        "HeatmapChart", fliplr(strtok(fliplr(class(parent)), '.')))));
end

end

function iValidateTableSubscript(tbl, var, propName)
% Helper to check that VAR is a valid subscript for extracting a single
% variable from TBL.
try
    data = subsref(tbl, substruct('()', {':', var}));
catch err
    % Substitute special subscript error
    throwAsCaller(MException(message("MATLAB:Chart:TableSubscriptInvalid", propName)));
end

if width(data)~=1
    throwAsCaller(MException(message("MATLAB:Chart:NonScalarTableSubscript", propName)));
end
end


function [parent, cvar, cmethod, title, otherArgs] = iParseParamValues(varargin)
% Parse the allowed arguments for tall tabular heatmap.

% Some args can just be passed through.
otherArgNames = {
    'MissingDataLabel'
    'Colormap'
    'ColorScaling'
    'ColorLimits'
    'MissingDataColor'
    'ColorbarVisible'
    'GridVisible'
    'CellLabelColor'
    'CellLabelFormat'
    'FontColor'
    };

parser = inputParser;
addParameter(parser, 'ColorVariable', '');
addParameter(parser, 'ColorMethod', 'count');
addParameter(parser, 'Parent', gobjects(0));
addParameter(parser, 'Title', '');
for ii=1:numel(otherArgNames)
    addParameter(parser, otherArgNames{ii}, []);
end
% Now parse the inputs
parser.parse(varargin{:});

cvarSupplied = ~ismember('ColorVariable',parser.UsingDefaults);
cmethodSupplied = ~ismember('ColorMethod',parser.UsingDefaults);
parentSupplied = ~ismember('Parent',parser.UsingDefaults);

title = parser.Results.Title;
cvar = parser.Results.ColorVariable;
cmethod = parser.Results.ColorMethod;
parent = parser.Results.Parent;

if parentSupplied
    iValidateParent(parent);
end

if cmethodSupplied
    validMethods = ["none" "count" "mean" "median" "min" "max" "sum"];
    matches = find(startsWith(validMethods, lower(cmethod)));
    if ~isscalar(matches)
        % Ambiguous or invalid
        error(message("MATLAB:datatypes:InvalidEnumValue", cmethod, "'count' | 'mean' | 'sum'"))
    end
    cmethod = validMethods(matches);
else
    if cvarSupplied
        % Default method is COUNT when no ColorVariable is supplied, but is
        % MEAN when one is.
        cmethod = 'mean';
    else
        cmethod = 'count';
    end
end

% Check for other args that we can just pass along to in-memory heatmap.
otherArgs = cell(1,0);
for ii=1:numel(otherArgNames)
    if ~ismember(otherArgNames{ii},parser.UsingDefaults)
        otherArgs(1,end+1:end+2) = [otherArgNames(ii), {parser.Results.(otherArgNames{ii})}];
    end
end
end


function [xdata, ydata, cdata] = iAggregateTallData(tbl, xvar, yvar, cvar, cmethod)
% Helper to count occurences of each unique combination of x and y values
% (kind of like a 2D countcats)

xCat = categorical(subsref(tbl, substruct('{}', {':',xvar})));
yCat = categorical(subsref(tbl, substruct('{}', {':',yvar})));
xdata = categories(xCat);
ydata = categories(yCat);
subs = [uint64(yCat), uint64(xCat)];
m = size(ydata,1);
n = size(xdata,1);
if isempty(cvar)
    cdata = 1;
else
    cdata = subsref(tbl, substruct('{}', {':',cvar}));
end
switch cmethod
    case "count"
        cdata = iAccumCount(subs, cdata, m, n);
        % CData will come back as a single cell, so de-cell it
        cdata = clientfun(@(x) x{1}, cdata);
    case "sum"
        cdata = iAccumSum(subs, cdata, m, n);
        % CData will come back as a single cell, so de-cell it
        cdata = clientfun(@(x) x{1}, cdata);
    case "max"
        cdata = aggregatefun(@iPerChunkAccumarray, @iMaxChunks, subs, cdata, m, n, @max, -inf);
        % CData will come back as a single cell, so de-cell it
        cdata = clientfun(@(x) x{1}, cdata);
    case "min"
        cdata = aggregatefun(@iPerChunkAccumarray, @iMinChunks, subs, cdata, m, n, @min, inf);
        % CData will come back as a single cell, so de-cell it
        cdata = clientfun(@(x) x{1}, cdata);
    case "mean"
        sumdata = iAccumSum(subs, cdata, m, n);
        countdata = iAccumCount(subs, cdata, m, n);
        % both sum and count come back in a cell, so divide the contents
        cdata = clientfun(@(x,count) x{1}./count{1}, sumdata, countdata);
end

end

function outCell = iAccumSum(subs, values, m, n)
% Accumulate the sum of all chunks, ignoring NaNs
fcn = @(x) sum(x,"omitnan");
outCell = aggregatefun(@iPerChunkAccumarray, @iSumChunks, subs, values, m, n, fcn, 0);
end

function outCell = iAccumCount(subs, values, m, n)
% Count all non-nan values
fcn = @(x) nnz(~isnan(x));
outCell = aggregatefun(@iPerChunkAccumarray, @iSumChunks, subs, values, m, n, fcn, 0);
end


function out = iPerChunkAccumarray(subs, cdata, m, n, fcn, varargin)
% Accumulate the result for one chunk, putting it in a cell for output.

% Be careful of empty results - accumarray doesn't like it
if m*n == 0
    out = {zeros(m, n, like=cdata)};
    return
end

out = {accumarray(subs, cdata, [m n], fcn, varargin{:})};
end

function out = iSumChunks(in)
% Sum a set of [mxn] chunks, each in its own cell
out = iReduceChunks(@plus, in);
end

function out = iMinChunks(in)
% Take the minimum over a set of [mxn] chunks, each in its own cell
out = iReduceChunks(@min, in);
end

function out = iMaxChunks(in)
% Take the maximum over a set of [mxn] chunks, each in its own cell
out = iReduceChunks(@max, in);
end

function out = iReduceChunks(fcn, in)
% Reduce a set of [mxn] chunks, each in its own cell

% NB: the input is never empty. Empty chunks produce a 1x1 cell with empty
% contents.
out = in(1);
for ii = 2:numel(in)
    out{1} = fcn(out{1}, in{ii});
end
end

function t = iCreateTitleText(cmethod, xName, yName, cName)
t = "";
switch cmethod
    case 'count'
        if ~isempty(xName) && ~isempty(yName)
            m = message("MATLAB:graphics:heatmap:CountTitle", yName, xName);
            t = m.getString;
        end
    case 'mean'
        if ~isempty(cName)
            m = message("MATLAB:graphics:heatmap:MeanTitle", cName);
            t = m.getString;
        end
    case 'min'
        if ~isempty(cName)
            m = message("MATLAB:graphics:heatmap:MinTitle", cName);
            t = m.getString;
        end
    case 'max'
        if ~isempty(cName)
            m = message("MATLAB:graphics:heatmap:MaxTitle", cName);
            t = m.getString;
        end
    case 'sum'
        if ~isempty(cName)
            m = message("MATLAB:graphics:heatmap:SumTitle", cName);
            t = m.getString;
        end
end
end
