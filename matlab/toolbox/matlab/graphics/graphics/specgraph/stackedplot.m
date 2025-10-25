function hh = stackedplot(varargin)
%stackedplot  Stacked plot
%   STACKEDPLOT(T) plots the contents of a table or timetable in a stacked
%   plot. A stacked plot consists of multiple axes stacked vertically,
%   sharing the same x-axis. Each table variable is plotted in a separate y-axis.
%   If T is a table, each variable is plotted against the row indices. If T
%   is a timetable, each variable is plotted against the row times. STACKEDPLOT
%   plots all numeric, logical, categorical, datetime, and duration variables,
%   and ignores all other variables.
%
%   STACKEDPLOT(T1,...,TN) OR STACKEDPLOT({T1,...,TN}) plots the contents of
%   multiple tables or timetables in a stacked plot. If T1, ..., TN are tables,
%   each variable is plotted against the row indices. If T1, ..., TN are
%   timetables, each variable is plotted against the row times.
%
%   STACKEDPLOT(T,VARS) specifies which table or timetable variables to plot.
%   VARS can be a string array, a cell array of character vectors, an integer
%   vector, or a logical vector. VARS can also be a cell array of string arrays
%   or a nested cell array of character vectors, where all variables in a cell
%   are plotted in the same axes. For example, {"A", ["B" "C"]} plots variable
%   A in the first axes, and variables B and C in the second axes.
%
%   STACKEDPLOT(T1,...,TN,VARS) specifies which table or timetable variables to
%   plot. VARS can be a string array or a cell array of character vectors. VARS
%   can also be a cell array of string arrays or a nested cell array of
%   character vectors, where all variables in a cell are plotted in the same
%   axes.
%
%   STACKEDPLOT(X,Y), where X is a vector and Y a matrix, plots each column
%   in Y against X.
%
%   STACKEDPLOT(Y) plots each column in Y against its row indices.
%
%   STACKEDPLOT(__,LINESPEC) sets the line style, marker symbol, and color.
%
%   STACKEDPLOT(__,'XVariable',XVAR) specifies the table variable to use as the
%   X variable. This syntax is valid only when plotting one or more tables, and
%   not when plotting one or more timetables. When plotting multiple tables,
%   XVAR can also be a string array or cell array of character vectors
%   specifying the X variable for each table.
%
%   STACKEDPLOT(__,'CombineMatchingNames',false) plots variables from different
%   inputs but with the same names in different axes. This syntax only affects
%   the chart when the inputs are multiple tables or multiple timetables.
%
%   STACKEDPLOT(__,NAME,VALUE) specifies additional options for the stacked
%   plot using one or more name-value pair arguments. Specify the options
%   after all the other input arguments.
%
%   STACKEDPLOT(PARENT,__) creates the stacked plot in the figure, panel, or
%   tab specified by PARENT.
%
%   s = STACKEDPLOT(__) also returns a StackedLineChart object. Use s to
%   inspect and adjust properties of the stacked plot.
%
%   Example - Plot a timetable
%   --------------------------
%   Time = datetime(["2015-12-18 08:03:05";"2015-12-18 10:03:17";"2015-12-18 12:03:13"]);
%   Temp = [37.3;39.1;42.3];
%   Pressure = [30.1;30.03;29.9];
%   WindSpeed = [13.4;6.5;7.3];
%   TT = timetable(Time,Temp,Pressure,WindSpeed);
%   stackedplot(TT);
%
%   Example - Plot multiple timetables
%   ----------------------------------
%   x = linspace(0,2*pi,15)';
%   y1 = sin(x);
%   y2 = cos(2*x);
%   TT1 = timetable(hours(x),y1,y2);
%
%   x = linspace(pi,2.5*pi,30)';
%   y1 = cos(x);
%   y3 = sin(2*x);
%   TT2 = timetable(hours(x),y1,y3);
%
%   stackedplot(TT1,TT2);
%
%
%   See also heatmap, bubblechart, plot, stairs, scatter.

%   Copyright 2018-2022 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);

% Capture the input arguments and initialize the extra name/value pairs to
% pass to the StackedLineChart constructor.
args = varargin;
inputNames = cell(1, nargin);
for i = 1:nargin
    inputNames{i} = inputname(i);
end
parent = gobjects(0);

% Check if the first input argument is a graphics object to use as parent.
if ~isempty(args) && isa(args{1},'matlab.graphics.Graphics')
    % stackedplot(parent,___)
    parent = args{1};
    args = args(2:end);
    inputNames = inputNames(2:end);
end

% Check for the table vs. matrix syntax.
if isempty(args)
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif isa(args{1}, 'tabular')
    singleTableInput = numel(args) == 1 || ~isa(args{2}, 'tabular');
    if singleTableInput
        % Table syntax
        %   stackedplot(tbl,Name,Value)
        %   stackedplot(tbl,vars,Name,Value)
        [extraArgs, args] = parseTableInputs(args, inputNames);
    else
        % Multiple Table syntax
        %   stackedplot(tbl1,...,tblN,Name,Value)
        %   stackedplot(tbl1,...,tblN,vars,Name,Value)
        [extraArgs, args] = parseMultipleTableInputs(args, inputNames);
    end
elseif isa(args{1}, 'cell')
    % Multiple Table syntax
    %   stackedplot({tbl1,...,tblN},Name,Value)
    %   stackedplot({tbl1,...,tblN},vars,Name,Value)
    [extraArgs, args] = parseMultipleTableInputs(args, inputNames);
else
    % Matrix syntax
    %   stackedplot(ydata,Name,Value)
    %   stackedplot(xdata,ydata,Name,Value)
    [extraArgs, args] = parseMatrixInputs(args, inputNames);
end

% Look for a Parent name-value pairs.
[parent, ~, args] = matlab.internal.datatypes.parseArgs({'Parent'}, {parent}, args{:});

% Look for a OuterPosition name-value pairs.
[~, ~, ~, flags, ~] = matlab.internal.datatypes.parseArgs({'OuterPosition', ...
    'InnerPosition', 'Position'}, {[], [], []}, args{:});
posArgsPresent = flags.OuterPosition || flags.InnerPosition || flags.Position;

% Build the full list of name-value pairs.
args = [extraArgs args];

% If position not specified, use replaceplot behavior
if ~posArgsPresent
    if ~isempty(parent)
        validateParent(parent);
    end
    % Construct the StackedLineChart.
    constructor = @(varargin) matlab.graphics.chart.StackedLineChart(varargin{:},args{:});
    try
        h = matlab.graphics.internal.prepareCoordinateSystem('matlab.graphics.chart.StackedLineChart',parent, constructor);
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
    
    % Construct stackedplot without replacing gca
    try
        h = matlab.graphics.chart.StackedLineChart('Parent', parent, args{:});
    catch e
        throw(e)
    end
end

% Make the new stacked plot the CurrentAxes
fig = ancestor(h,'figure');
if isscalar(fig)
    fig.CurrentAxes = h;

    % hide the figure toolbar if stackedplot is the only child
    if isscalar(fig.Children)
        removeToolbarExplorationButtons(fig);
    end
end

% Prevent outputs when not assigning to variable.
if nargout > 0
    hh = h;
end

end

function [found, linespecArgs] = parseLineSpec(arg)
found = false;
linespecArgs = {};
[l,c,m,tmsg] = colstyle(arg);
if isempty(tmsg)
    if ~isempty(l)
        linespecArgs = [linespecArgs {'LineStyle',l}];
    elseif ~isempty(m)  % if marker specified but not linestyle, use 'none' linestyle
        linespecArgs = [linespecArgs {'LineStyle','none'}];
    end
    if ~isempty(c)
        linespecArgs = [linespecArgs {'Color',c,'MarkerEdgeColor',c}];
    end
    if ~isempty(m)
        linespecArgs = [linespecArgs {'Marker',m}];
    end
    found = true;
end
end

function [extraArgs, args] = parseTableInputs(args, inputNames)
% Parse the table syntax:
%   stackedplot(tbl,Name,Value)
%   stackedplot(tbl,vars,Name,Value)
%   stackedplot(tbl,linespec,Name,Value)
%   stackedplot(tbl,vars,linespec,Name,Value)

% Collect the first three input arguments.
try
    tbl = args{1};
    [extraArgs,args] = parseOptionalTableInputs(tbl,tbl.Properties.VariableNames,args);
catch ME
    throwAsCaller(ME);
end

extraArgs = [extraArgs {'LegendLabels_I' inputNames(1)}];
end

function [extraArgs, args] = parseMultipleTableInputs(args, inputNames)
% Parse the table syntax:
%   stackedplot(tbl1,...tblN,Name,Value)
%   stackedplot(tbl1,...tblN,vars,Name,Value)
%   stackedplot(tbl1,...tblN,linespec,Name,Value)
%   stackedplot(tbl1,...tblN,vars,linespec,Name,Value)

% Collect the first three input arguments.

% Input tables
if iscell(args{1})
    tbls = args{1};
    if isempty(inputNames{1})
        tableNames = {};
    else
        tableNames = cellstr(inputNames{1} + " " + (1:numel(tbls)));
    end
else
    idxLastTbl = 1;
    while idxLastTbl <= length(args) && isa(args{idxLastTbl},'tabular')
        idxLastTbl = idxLastTbl + 1;
    end
    idxLastTbl = idxLastTbl - 1;
    tbls = args(1:idxLastTbl);
    % Move initial tabular elements in args into a single cell array
    args{1} = tbls;
    args(2:idxLastTbl) = [];
    tableNames = inputNames(1:idxLastTbl);
end

try
    matlab.graphics.chart.internal.stackedplot.validateSourceTable(tbls);

    varNames = cellfun(@(t)t.Properties.VariableNames,tbls,'UniformOutput',false);
    varNames = unique([varNames{:}],'stable');
    [extraArgs,args] = parseOptionalTableInputs(tbls,varNames,args);
catch ME
    throwAsCaller(ME);
end

extraArgs = [extraArgs {'LegendLabels_I' tableNames}];
end

function [extraArgs, args] = parseOptionalTableInputs(tbl, varNames, args)
extraArgs = {'SourceTable', tbl};
args2delete = 1;
arg2MayBeVars = false;  % flag used to check whether the second input is ambiguous
numargs = numel(args);
if numargs > 1
    arg2 = args{2};
    if isStringScalar(arg2)
        % arg2 is a scalar string (not a char row). It may be a single table 
        % variable name, linespec or a parameter name. Check whether it 
        % matches a table variable name exactly. 
        arg2MayBeVars = ismember(arg2, varNames);
        
    elseif ~(ischar(arg2) && isrow(arg2))  
        % arg2 is not a char row or string scalar and therefore cannot be
        % a linespec or a parameter name. Treat that as DisplayVariables
        matlab.graphics.chart.internal.stackedplot.validateDisplayVariables(...
            arg2, tbl, mfilename, 'vars');
        extraArgs = [extraArgs {'DisplayVariables' arg2}];
        args2delete = args2delete + 1;
    end
end

% resolve the ambiguous case where the second input is a string scalar that
% matches a table variable name.
linespecArgs = {};
if arg2MayBeVars
    % check whether the number of remaining inputs is odd or even
    if rem(numargs - 1, 2) == 1
        % Number of trailing inputs is odd. Can be:
        %   stackedplot(tbl,vars,Name,Value)
        %   stackedplot(tbl,linespec,Name,Value)
        
        % check linespec first
        [found, linespecArgs] = parseLineSpec(arg2);
        % if not linspec, then must be vars
        if ~found
            extraArgs = [extraArgs {'DisplayVariables' arg2}];            
        end
        args2delete = 2;
    else
        % Number of trailing inputs is even. Can be:
        %   stackedplot(tbl,Name,Value)
        %   stackedplot(tbl,vars,linespec,Name,Value)

        % check whether the third input is linespec to decide
        if numargs > 2
            [found, linespecArgs] = parseLineSpec(args{3});
            if found
                args2delete = 3;
                extraArgs = [extraArgs {'DisplayVariables' arg2}];
            end
        end
        
    end
else
    % not the ambiguous case. Just proceed to check for linespec.
    if numargs > args2delete
        [found, linespecArgs] = parseLineSpec(args{args2delete+1});
        if found
            args2delete = args2delete + 1;
        end
    end
end

extraArgs = [extraArgs linespecArgs];
args(1:args2delete) = [];
end

function [extraArgs, args] = parseMatrixInputs(args, inputNames)
% Parse the matrix syntax:
%   stackedplot(ydata,Name,Value)
%   stackedplot(ydata,linespec,Name,Value)
%   stackedplot(xdata,ydata,Name,Value)
%   stackedplot(xdata,ydata,linespec,Name,Value)

funcname = mfilename;
if numel(args) > 1 && ~(ischar(args{2}) || isStringScalar(args{2}))
    try
        validateattributes(args{1}, {'datetime', 'duration', 'numeric', 'logical'}, ...
            {'vector'}, funcname, 'x');
        validateattributes(args{2}, {'numeric', 'logical', ...
            'datetime', 'duration', 'categorical'}, {}, funcname, 'y');
    catch ME
        throwAsCaller(ME);
    end
    if length(args{1}) ~= size(args{2},1)
        throwAsCaller(MException(message('MATLAB:stackedplot:XDataYDataMismatch')));
    end
    extraArgs = {'XData', args{1}, 'YData', args{2}};
    args2delete = 2;
    matrixName = inputNames(2);
else
    try
        validateattributes(args{1}, {'numeric', 'logical', ...
            'datetime', 'duration', 'categorical'}, {}, funcname, 'y');
    catch ME
        throwAsCaller(ME);
    end
    extraArgs = {'XData', 1:size(args{1},1), 'YData', args{1}};
    args2delete = 1;
    matrixName = inputNames(1);
end
if numel(args) > args2delete
    nextarg = args{args2delete+1};
    if ischar(nextarg) || isStringScalar(nextarg)
        [l,c,m,tmsg] = colstyle(char(nextarg));
        if isempty(tmsg)
            if ~isempty(l)
                extraArgs = [extraArgs {'LineStyle',l}];
            elseif ~isempty(m)  % if marker specified but not linestyle, use 'none' linestyle
                extraArgs = [extraArgs {'LineStyle','none'}];
            end
            if ~isempty(c)
                extraArgs = [extraArgs {'Color',c,'MarkerEdgeColor',c}];
            end
            if ~isempty(m)
                extraArgs = [extraArgs {'Marker',m}];
            end
            args2delete = args2delete + 1;
        end
    end
end
args(1:args2delete) = [];
extraArgs = [extraArgs {'LegendLabels_I' matrixName}];
end

function validateParent(parent)

if ~isa(parent, 'matlab.graphics.Graphics') || ~isscalar(parent)
    % Parent must be a valid scalar graphics object.
    throwAsCaller(MException(message('MATLAB:stackedplot:InvalidParent')));
elseif ~isvalid(parent)
    % Parent cannot be a deleted graphics object.
    throwAsCaller(MException(message('MATLAB:stackedplot:DeletedParent')));
elseif isa(parent,'matlab.graphics.axis.AbstractAxes')
    % StackedLineChart cannot be a child of Axes.
    throwAsCaller(MException(message('MATLAB:hg:InvalidParent',...
        'StackedLineChart', fliplr(strtok(fliplr(class(parent)), '.')))));
end

end
