function [GC,GR,GP] = groupcounts(T,varargin)
%GROUPCOUNTS Counts by group.
%
%   Supported syntaxes for tall tables T and tall matrices X:
%
%   GC = groupcounts(T,GROUPVARS)
%   GC = groupcounts(X)
%
%   GC = groupcounts(T,GROUPVARS,GROUPBINS)
%   GC = groupcounts(X,GROUPBINS)
%
%   GC = groupcounts(___,'IncludeMissingGroups',TF)
%   GC = groupcounts(___,'IncludedEdge',LR)
%
%   [GC,GR,GP] = groupcounts(X,___)
%
% Limitations:
% 1) The first input argument does not support cell arrays.
% 2) The GROUPVARS argument does not support function handles.
% 3) The 'IncludeEmptyGroups' name-value pair is not supported.
% 4) The order of the groups might be different compared to in-memory
%    GROUPCOUNTS calculations.
% 5) When grouping by discretized datetime arrays, the categorical group 
%    names will be different from in-memory GROUPCOUNTS calculations.
%
%   See also GROUPCOUNTS, GROUPSUMMARY, TALL, FINDGROUPS, DISCRETIZE.

%   Copyright 2018-2024 The MathWorks, Inc.

% Check correct number of inputs
narginchk(1,inf);

% Parse inputs and error out as early as possible.
fname = mfilename;

% Only first input can be tall
tall.checkIsTall(upper(fname), 1, T);
tall.checkNotTall(upper(fname), 1, varargin{:});

% Compute matrix/table switch flag
Tcls = tall.getClass(T);
isTabular = isequal(Tcls, 'table') || isequal(Tcls, 'timetable');

if isTabular
    narginchk(2,Inf);
    % Error if asking for more than 1 output for table
    nargoutchk(0,1);
    
    groupVars = varargin{1};
    
    % Parse grouping variables
    if isa(groupVars,'function_handle')
        error(message('MATLAB:bigdata:array:GroupcountsUnsupportedGroupVarsFcn'));
    end
    
    % Create sample of same types and run through in-memory groupcounts
    % for input validation
    sT = buildSample(T.Adaptor,'double',0);
    groupcounts(sT,varargin{:});
    
    [groupingData,groupVars,gvLabels,T] = parseGroupVarsTall(groupVars,isTabular,'groupcounts',T);
    ungrouped = isempty(groupVars);
    gcLabel = ["GroupCount","Percent"];
    indStart = 2;
else
    % Create sample of same types and run through in-memory groupcounts
    % for input validation
    sT = buildSample(T.Adaptor,'double',1);
    groupcounts(sT,varargin{:});
    
    % Parse grouping variables
    [groupingData,groupVars,gvLabels] = parseGroupVarsTall(T,isTabular,'groupcounts');
    ungrouped = false;
    indStart = 1;
end

% Set default values
inclNan = true;
inclEdge = 'left';

% ---------- start argument parsing ---------------

% Parse remaining inputs
gbProvided = false;

if nargin > indStart
    % Parse groupbins
    if matlab.internal.math.isgroupbins(varargin{indStart},'groupcounts')
        [groupBins,~,scalarExpandVars] = matlab.internal.math.parsegroupbins(varargin{indStart},numel(gvLabels),'groupcounts:Group');
        indStart = indStart + 1;
        gbProvided = true;
    end
    
    % Parse name-value pairs
    if rem(nargin-(indStart),2) == 0
        for j = indStart:2:length(varargin)
            % Other options caught by sample test above
            name = varargin{j};
            if matlab.internal.math.checkInputName(name,{'IncludeEmptyGroups'},8)
                error(message('MATLAB:bigdata:array:GroupcountsEmptyGroups'));
            elseif matlab.internal.math.checkInputName(name,{'IncludeMissingGroups'},8)
                inclNan = varargin{j+1};
                matlab.internal.datatypes.validateLogical(inclNan,'IncludeMissingGroups');
            elseif matlab.internal.math.checkInputName(name,{'IncludedEdge'},8)
                inclEdge = varargin{j+1};
            end
        end
    end
end

if gbProvided
    % Discretize grouping variables and remove repeated pairs of grouping
    % variables and group bins
    [groupingData,~,gvLabels] = discGroupVarTall(groupingData,groupVars,gvLabels,groupBins,inclEdge,isTabular,scalarExpandVars);
elseif isTabular
    % Remove repeated groupvars
    [~,ridx] = unique(groupVars,'stable');
    groupingData = groupingData(ridx);
    gvLabels = gvLabels(ridx);
end

% Compute final number of grouping variables from labels
numGroupVars = numel(gvLabels);

% -------------- end parsing code ---------------

if ~ungrouped
    % Find groups
    tx = mgrp2idxTall(inclNan,groupingData{:});
    
    % flag groups that are extra with tag 0
    txnm = elementfun(@flagMissingAsZero,tx);
    % Get groups and counts
    groups = cell(size(groupingData));
    [txnm_out,groups{:},gcount] = aggregatebykeyfun(@getGroupsAndCounts,@reduceGroupsAndCounts,txnm,groupingData{:},txnm);
    
    % Set Adaptors
    for k=1:numGroupVars
        groups{k}.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(groupingData{k}));
    end
    gcount.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(txnm));
else
    % Need to create data
    groups = cell(1,0);
    gvLabels = string.empty;
    gcount = size(T,1);
end

if ~inclNan && ~ungrouped
    % Remove extra groups with tag 0
    [gcount, groups{:}] = deleteMissingGroup(txnm_out,gcount,groups{:});
end

% reusing deleteMissingGroups to handle empty tall tables
if ungrouped
    [gcount] = deleteMissingGroup(gcount,gcount);
end

% Compute percentage
% No need to special case when sum(gcount)=0 since empty groups are not
% supported for tall and empties flow through this call fine.
gpercentage = (gcount*100)/sum(gcount,1);

if isTabular
    % Make sure all labels are unique
    uniquelabels = matlab.lang.makeUniqueStrings([gvLabels,gcLabel],["Row", "Variables"],namelengthmax);
        
    % Build the output tall table from tall variables.
    GC = table(groups{:},gcount,gpercentage,'VariableNames',uniquelabels);
else
    GC = gcount;
    if nargout > 1
        if numGroupVars == 1
            GR = groups{1};
        else
            GR = groups;
        end
        GP = gpercentage;
    end
end
end

%% Helpers for getting group names and counts
function [varargout] = getGroupsAndCounts(varargin)
varargout = cell(size(varargin));
if isempty(varargin{1})
    varargout = varargin;
else
    for k=1:nargin-1
        z = varargin{k};
        varargout{k} = z(1,:);
    end
    varargout{nargin} = numel(varargin{nargin});
end
end

function [varargout] = reduceGroupsAndCounts(varargin)
varargout = cell(size(varargin));
if isempty(varargin{1})
    varargout = varargin;
else
    for k=1:nargin-1
        z = varargin{k};
        varargout{k} = z(1,:);
    end
    varargout{nargin} = sum(varargin{nargin},1);
end
end

%% Dealing with missing groups and empty tall tables/timetables
function tout = flagMissingAsZero(tin)
tout = tin;
tout(ismissing(tin))=0;
end

function varargout = deleteMissingGroup(tin,varargin)
flag = logical(tin);
varargout = cell(size(varargin));
[varargout{:}] = filterslices(flag,varargin{:});
end
