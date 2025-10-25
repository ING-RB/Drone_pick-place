function hh=bubblecloud(varargin)
%BUBBLECLOUD Create bubblecloud chart.
%
% BUBBLECLOUD(tbl,szvar) creates a bubble cloud chart using the data in the
% table tbl. Specify szvar as a reference to the table variable containing 
% bubble sizes. Table variables can be indicated with a character vector or
% string scalar containing the variable name, a numeric scalar containing 
% the variable index, or a logical vector with one true element.
%
% BUBBLECLOUD(tbl,szvar,labelvar) displays labels on the bubbles. Specify
% labelvar as a reference to the table variable containing the bubble
% labels.
%
% BUBBLECLOUD(tbl,szvar,labelvar,groupvar) specifies grouping data for the
% bubbles. Use groups to display multiple clouds with different colors.
%
% BUBBLECLOUD(sz) creates a bubble cloud with the bubble sizes specified
% as a vector.
%
% BUBBLECLOUD(sz,labels) displays labels on the bubbles. Specify labels as
% a cell array of character vectors or a string vector that is the same
% length as sz.
%
% BUBBLECLOUD(sz,labels,groups) specifies grouping data for the bubbles.
% Specify groups as a vector that is the same length as sz and labels.
%
% BUBBLECLOUD(___,Name,Value) specifies additional bubble cloud properties
% using one or more name-value arguments. Specify the properties after all
% other input arguments.
%
% b = BUBBLECLOUD(___) returns the BubbleCloud object. Use b to modify
% properties of the chart after creating it.
%
% Example (table syntax):
%   tbl = readtable('bicyclecounts');
%   summary = groupsummary(tbl,'Day','mean','Total');
%   BUBBLECLOUD(summary,'mean_Total','Day')
%
% Example (vector syntax):
%   sz = .5*randn(100,1).^2;
%   lbl = compose('%0.2f',sz);
%   gp = round(sz);
%   BUBBLECLOUD(sz,lbl,gp)

%   Copyright 2020-2023 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
args=varargin;
parent=gobjects(0);
if ~isempty(args) && isa(args{1},'matlab.graphics.Graphics')
    parent = args{1};
    args(1) = [];
end


if isempty(args)
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif isa(args{1}, 'tabular')
    %   BUBBLECLOUD(tbl,szvar)
    %   BUBBLECLOUD(tbl,szvar,lblvar)
    %   BUBBLECLOUD(tbl,szvar,lblvar,grpvar)
    pvpairs = parseTableInputs(args);
elseif isnumeric(args{1})
    %   BUBBLECLOUD(sz)
    %   BUBBLECLOUD(sz,lbl)
    %   BUBBLECLOUD(sz,lbl,grp)
    pvpairs = parseVectorInputs(args);
else
    error(message('MATLAB:graphics:bubblecloud:InvalidArguments'));
end

% Look for parent pv pairs
inds = find(strcmpi('Parent',pvpairs(1:2:end)));
if ~isempty(inds) && (inds(end)*2)<=numel(pvpairs)
    inds = inds*2-1;
    parent = pvpairs{inds(end)+1};
    pvpairs([inds inds+1]) = [];
end

% Validate parent
if ~isempty(parent) 
    % just check for scalar/valid, others bad parents handled by the object
    if ~isscalar(parent)
        error(message('MATLAB:hgbuiltins:NonScalarParent'))
    elseif ~isvalid(parent)
        error(message('MATLAB:hg:DeletedObject'))
    end
end

posProps = ["OuterPosition","InnerPosition","Position"];
posPropsPresent = any(startsWith(posProps, string(pvpairs(1:2:end)), 'IgnoreCase', 1));

if posPropsPresent
    % Position specified, construct without replacing anything
    if isempty(parent)
        parent=gcf;
    end
    try
        h = matlab.graphics.chart.BubbleCloud('Parent', parent, pvpairs{:});
    catch me
        throw(me)
    end
else
    % Replace existing plot (depending on hold)
    constructor=@(varargin)matlab.graphics.chart.BubbleCloud(varargin{:},pvpairs{:});
    try
        h = matlab.graphics.internal.prepareCoordinateSystem('matlab.graphics.chart.BubbleCloud', parent, constructor);
    catch me
        throw(me)
    end
end

% Set as current 'axes' if not already done
fig=ancestor(h,'figure');
if ~isempty(fig)
    fig.CurrentAxes=h;
end

if nargout > 0
    hh = h;
end
end

function pvpairs = parseVectorInputs(args)

if ~isvector(args{1})
    ME=MException(message('MATLAB:graphics:bubblecloud:MustBeVector','sz'));
    throwAsCaller(ME)
end


convArgs={'SizeData' args{1}};
n=numel(args{1});
args(1)=[];

% Parse label argument
if ~isempty(args) 
    if ~isvector(args{1}) && ~isempty(args{1})
        ME=MException(message('MATLAB:graphics:bubblecloud:MustBeVector','labels'));
        throwAsCaller(ME)
    end
    
    % Scalar strings are considered potential name/value pairs, unless sz 
    % is scalar, in which the second arg is considered a label.
    if iscellstr(args{1}) || ...
            (isstring(args{1}) && (~isscalar(args{1}) || n==1))
        if numel(args{1})~=n
            throwAsCaller(MException(message('MATLAB:graphics:bubblecloud:SizeMismatch','labels')));
        end
        convArgs=[convArgs {'LabelData' args{1}}];
        args(1)=[];
    elseif isempty(args{1})
        % placeholder arg
        args(1)=[];
    elseif ~isstring(args{1}) && ~ischar(args{1})
        % invalid arg
        throwAsCaller(MException(message('MATLAB:graphics:bubblecloud:BadTypeLabel')));
    end
end

% Parse group argument
if ~isempty(args)
    if ~isvector(args{1})
        ME=MException(message('MATLAB:graphics:bubblecloud:MustBeVector','groups'));
        throwAsCaller(ME)
    end
    
    % Scalar strings are considered potential name/value pairs, unless sz 
    % is scalar, in which the second arg is considered a group.
    if iscellstr(args{1}) || ...
            (isstring(args{1}) && (~isscalar(args{1}) || n==1)) || ...
            isnumeric(args{1}) || islogical(args{1}) || iscategorical(args{1})
        
        if numel(args{1})~=n
            throwAsCaller(MException(message('MATLAB:graphics:bubblecloud:SizeMismatch','groups')));
        end
        convArgs=[convArgs {'GroupData' args{1}}];
        args(1)=[];
    elseif ~isstring(args{1}) && ~ischar(args{1})
        throwAsCaller(MException(message('MATLAB:graphics:bubblecloud:BadTypeGroup')));
    end
end

% add convenience argument pvpairs to remaining arguments.
pvpairs=[convArgs args];
end

function pvpairs = parseTableInputs(args)
import matlab.graphics.chart.internal.validateTableSubscript
import matlab.graphics.internal.isCharOrString

nargs=numel(args);
if nargs<2
    throwAsCaller(MException(message('MATLAB:narginchk:notEnoughInputs')));
end

% Grab property names to support throwing appropriate exceptions for
% ambiguous bad tablevar/property arguments.
classmeta=meta.class.fromName('matlab.graphics.chart.BubbleCloud');
proplist=classmeta.PropertyList;
propnames={proplist.Name};
propsettable=strcmp({proplist.SetAccess},'public');
SettablePropNames=propnames(propsettable);


tbl=args{1};
args(1)=[];

[varname, ~, err] = validateTableSubscript(tbl, args{1}, 'SizeVariable');
if ~isempty(err)
    throwAsCaller(err);
elseif isempty(varname)
    throwAsCaller(MException(message('MATLAB:Chart:NonScalarTableSubscript', 'SizeVariable')));
end
convArgs={'SourceTable' tbl 'SizeVariable' args{1}};
args(1)=[];

% The next argument can either be a table variable of a property name. If
% it's a valid table variable, assume it's LabelVariable. If not, validate
% it against the list of settable properties so that an appropriate error
% message can be thrown.
if ~isempty(args)
    [varname, ~, err] = validateTableSubscript(tbl, args{1}, 'LabelVariable');
    if isempty(err) && isempty(varname)
        err=MException(message('MATLAB:Chart:NonScalarTableSubscript', 'LabelVariable'));
    end
    if isempty(err)
        convArgs=[convArgs {'LabelVariable' args{1}}];
        args(1)=[];
    elseif isCharOrString(args{1})
        if any(startsWith(SettablePropNames,args{1},'IgnoreCase',true))
            % Potentially valid prop name (note that this may still be
            % invalid if the propname is ambiguous)
            pvpairs=[convArgs args];
            return
        else
            throwAsCaller(MException(message('MATLAB:graphics:bubblecloud:BadTableVarPropAmbiguous', args{1})));
        end
    else
        throwAsCaller(err)
    end
end

if ~isempty(args)
    [varname, ~, err] = validateTableSubscript(tbl, args{1}, 'GroupVariable');
    if isempty(err) && isempty(varname)
        err=MException(message('MATLAB:Chart:NonScalarTableSubscript', 'GroupVariable'));
    end
    if isempty(err)
        convArgs=[convArgs {'GroupVariable' args{1}}];
        args(1)=[];
    elseif isCharOrString(args{1})
        if ~any(startsWith(SettablePropNames,args{1},'IgnoreCase',true))
            throwAsCaller(MException(message('MATLAB:graphics:bubblecloud:BadTableVarPropAmbiguous', args{1})));
        end
    else
        throwAsCaller(err)
    end
end
pvpairs=[convArgs args];
end
