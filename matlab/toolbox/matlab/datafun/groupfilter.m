function [G,GR] = groupfilter(T,groupVars,method,varargin)
%GROUPFILTER Filter data by group.
%   G = GROUPFILTER(T,GROUPVARS,METHOD) or 
%   G = GROUPFILTER(X,GROUPVARS,METHOD) groups the data in the variables
%   in table or timetable T, or the columns in a matrix or cell of matrices
%   X according to the grouping variables specified in GROUPVARS and
%   applies the METHOD to each group.
%
%   For table or timetable T, G is a table or timetable with rows filtered
%   based on the computations specified by METHOD. METHOD is applied
%   group-wise to all non-grouping variables in T. GROUPVARS specifies one
%   or more variables in T that define the groups of rows. Each group
%   consists of rows in T that have the same combination of values in those
%   grouping variables. GROUPVARS must be a table variable name, a cell
%   array of table variable names, a vector of table variable indices, a
%   logical vector whose elements each correspond to a table variable, a
%   function handle that takes the table variables as input and returns a
%   logical scalar (such as @isnumeric), or a table vartype subscript.
%
%   For matrix X, G is a matrix with rows filtered based on the results of
%   applying the METHOD to X by group. The groups are defined by rows in
%   GROUPVARS that have the same combination of values. GROUPVARS must have
%   the same number of rows as X and must be a column vector, multiple
%   column vectors stored as a matrix, or multiple column vectors stored in
%   a cell array. 
%   GROUPVARS can also be [] to indicate no grouping.
%
%   METHOD is a function handle used to filter out members from each group.
%   It must return a logical scalar or a logical column vector with the
%   same number of rows as the input data indicating which group members to
%   select. If the function handle returns a logical scalar, then either
%   all members of the group are filtered out (when it is false) or none
%   are filtered (when it is true). If the method returns true for every
%   column it is applied to, then that row is not filtered, otherwise it is
%   filtered.
% 
%   G = GROUPFILTER(T,GROUPVARS,GROUPBINS,METHOD) or
%   [G,GR] = GROUPFILTER(X,GROUPVARS,GROUPBINS,METHOD) specifies the 
%   discretization for GROUPVARS to be done prior to grouping. For table T,
%   the discretized grouping variables are returned as variables in the 
%   output table. For matrix X, the discretized grouping variables are 
%   returned in GR. If GROUPBINS is one of the options from the list below, 
%   then that discretization is applied to every grouping variable. 
%   Otherwise, GROUPBINS must be a cell array with one element for each 
%   grouping variable or there must be one grouping variable. Elements of
%   GROUPBINS can be one of the following:
%   
%      - (default) "none" indicating no discretization
%      - a list of bin edges specified as a numeric vector
%      - number of bins specified as an integer scalar
%      - time duration specified as a scalar of type duration or 
%        calendarDuration indicating bin widths for datetime or duration 
%        grouping variables
%      - time bins for datetime grouping variables specified as one of the 
%        following: "second", "minute", "hour", "day", "week", "month", 
%        "quarter", "year", "decade", "century", "secondofminute", 
%        "minuteofhour", "hourofday", "dayname", "dayofweek", "dayofmonth", 
%        "dayofyear", "weekofmonth", "weekofyear", "monthofyear", 
%        "monthname", or "quarterofyear"
%      - time bins for duration grouping variables specified as one of the 
%        following: "second", "minute", "hour", "day", or "year"
% 
%   G = GROUPFILTER(T,...,DATAVARS) applies the method only to the data 
%   in the table variables specified by DATAVARS. The default is all 
%   non-grouping variables in T. DATAVARS must be a table variable name, a 
%   cell array of table variable names, a vector of table variable indices,
%   a logical vector whose elements each correspond to a table variable, a 
%   function handle that takes the table variables as input and returns a 
%   logical scalar, or a table vartype subscript.
% 
%   G = GROUPFILTER(...,"IncludedEdge",LR) specifies which edge is 
%   included for each bin in the discretization. This N-V pair can only be 
%   used when GROUPBINS is specified. LR must be one of the following:
%        "left"     - (default) all bins include the left bin edge, except  
%                   for the last bin which includes both edges.
%        "right"    - all bins include the right bin edge, except for the 
%                   first bin which includes both edges.
%
%   [G,GR] = GROUPFILTER(X,...) also returns the groups GR for any of
%   the previous matrix syntaxes.
%
%   Examples:
%
%      % Load data and create table
%      load patients;
%      T = table(Age,Diastolic,Gender,Height,Smoker,Systolic,Weight);
%
%      % Group by age and only keep rows that are associated with groups
%      % that have more than 5 elements
%      G = groupfilter(T,"Age",@(x) numel(x) > 5);
%
%      % Group table by gender and only keep rows that have an age greater
%      % than the mean age of the group
%      G = groupfilter(T,"Gender",@(x) x > mean(x),"Age");
%
%   See also GROUPSUMMARY, GROUPTRANSFORM, GROUPCOUNTS.

%   Copyright 2019-2023 The MathWorks, Inc.

narginchk(3,Inf);

% Compute matrix/table switch flag
tableFlag = istabular(T);

if tableFlag
    % Error if asking for more than 1 output for table
    nargoutchk(0,1);
end

% Parse grouping variables
[groupingData,groupVars] = matlab.internal.math.parseGroupVars(groupVars,tableFlag,"groupfilter:Group",T);

% Initial processing depends on table vs matrix
if tableFlag
    % Create labels for groupVars in output table
    gvLabels = groupVars;
    
    % Set default values for data variables
    varNamesT = string(T.Properties.VariableNames);
    dataVars = varNamesT;
else
    % To avoid errors create numbered labels
    gvLabels = string(1:numel(groupingData));
    dataVars = T;
end

% Set rest of default values
inclEdge = "left";

% Parse remaining inputs
gbProvided = false;
dvNotProvided = true;
indStart = 1;
if matlab.internal.math.isgroupbins(method,"groupfilter")
    [groupBins,scalarExpandBins,scalarExpandVars] = matlab.internal.math.parsegroupbins(method,numel(gvLabels),"groupfilter:Group");
    gbProvided = true;
    if isempty(varargin)
        error(message("MATLAB:groupfilter:MethodNotProvided"));
    else
        method = varargin{indStart};
        indStart = indStart + 1;
    end
end
% Parse method
if ~isa(method,"function_handle")
    error(message("MATLAB:groupfilter:InvalidMethodOption"));
end
if nargin > 2+indStart
    if tableFlag
        %Parse data variables
        if (isnumeric(varargin{indStart}) || islogical(varargin{indStart}) || ...
                ((ischar(varargin{indStart}) || isstring(varargin{indStart})) && ...
                ~any(matlab.internal.math.checkInputName(varargin{indStart},"IncludedEdge",1))) || ...
                isa(varargin{indStart},"function_handle") || iscell(varargin{indStart}) || ...
                rem(nargin-(indStart+1),2) == 0)
            dataVars = matlab.internal.math.checkDataVariables(T, varargin{indStart}, "groupfilter", "Data");
            dataVars = varNamesT(dataVars);
            dataVars = unique(dataVars,"stable");
            dvNotProvided = false;
            indStart = indStart + 1;
        end
    end
    
    % Parse name-value pairs
    if rem(nargin-(indStart),2) == 0
        for j = indStart:2:length(varargin)
            name = varargin{j};
            if (~(ischar(name) && isrow(name)) && ~(isstring(name) && isscalar(name))) ...
                || (isstring(name) && strlength(name) == 0)
                error(message("MATLAB:groupfilter:ParseFlags"));
            elseif matlab.internal.math.checkInputName(name,"IncludedEdge",1)
                if ~gbProvided
                    error(message("MATLAB:groupfilter:IncludedEdgeNoGroupBins"));
                end
                inclEdge = varargin{j+1};
            else
                error(message("MATLAB:groupfilter:ParseFlags"));
            end
        end
    else
        error(message("MATLAB:groupfilter:KeyWithoutValue"));
    end
end

% Keep track of which groupVars have a group bin
gbForGV = false(size(groupVars));
if gbProvided
    % Discretize grouping variables and remove repeated pairs of grouping
    % variables and group bins
    [groupingData,groupVars,gvLabels,gbForGV] = matlab.internal.math.discgroupvar(groupingData,...
        groupVars,gvLabels,groupBins,inclEdge,scalarExpandBins,scalarExpandVars,"groupfilter",tableFlag);
else
    if tableFlag
        % Remove repeated grouping variables
        [groupVars,ridx] = unique(groupVars,"stable");
        groupingData = groupingData(ridx);
        gvLabels = gvLabels(ridx);
        gbForGV = gbForGV(ridx);
    end
end

% Compute grouping index and data
gvIdx = matlab.internal.math.mgrp2idx(groupingData,size(T,1),true,false);

% Extract data variables
[dvData,dataLabels,numDataVars] = matlab.internal.math.extractDataVars(T,groupVars,dataVars,tableFlag,dvNotProvided);

% Filter groups
gStats = false(size(T,1),numDataVars);
[gvIdxSorted, gvidxSortedIdx] = sort(gvIdx);
grpStart = find([1;diff(gvIdxSorted)>0]);
grpEnd = [grpStart(2:end)-1;length(gvIdxSorted)];
for ii = 1:numDataVars
    try
        x = dvData{ii};

        % If not grouping by anything then should apply method directly
        if isempty(gvIdx)
            d = method(x);
            if (size(d,1) ~= size(x,1)) && ~isscalar(d) || ~islogical(d)
                error(message("MATLAB:groupfilter:MethodOutputInvalidSize"));
            end
        else
            % Otherwise apply function by group
            d = applyFunByGroup(grpStart,grpEnd,gvidxSortedIdx,x,method);
        end
        gStats(:,ii) = d;
    catch ME
        if (strcmp(ME.identifier,"MATLAB:groupfilter:MethodOutputInvalidSize"))
            rethrow(ME);
        else
            % Single error being thrown for all other possible problems above
            if tableFlag
                error(message("MATLAB:groupfilter:ApplyDataVarsError",dataLabels(ii)));
            else
                error(message("MATLAB:groupfilter:ApplyDataVecsError",dataLabels(ii)));
            end
        end
    end
end

% Figure out which groups to filter
filterRows = all(gStats,2);

% Prepare discretized groupingdata
if (gbProvided && tableFlag) || nargout>1
    if tableFlag
        groupingData = groupingData(gbForGV);
        gvLabels = gvLabels(gbForGV);
    else
        % Set groups
        numGroupVars = numel(groupingData);
        if numGroupVars == 1
            GR = groupingData{1};
        elseif numGroupVars == 0
            emptyfun = str2func([class(groupVars) '.empty']);
            % groupvars must be 0x0 or mx0 here because for 0xn numgvars is n
            GR = emptyfun(size(T,1),0);
            if issparse(groupVars)
                GR = sparse(GR);
            end
        else
            GR = groupingData;
        end
        if iscell(GR) && ~isempty(GR) && numGroupVars ~= 1
            for k = 1:numGroupVars
                GR{1,k} = GR{1,k}(filterRows,:);
            end
        else
            GR = GR(filterRows,:);
        end
    end
end

G = T;
if tableFlag
    if gbProvided
        % Make sure all labels are unique
        uniqueLabels = matlab.lang.makeUniqueStrings([varNamesT,gvLabels],string(T.Properties.DimensionNames),namelengthmax);
        gdataT = table.init(groupingData,height(T),{},numel(groupingData),uniqueLabels(numel(varNamesT)+1:end));
        G = [G,gdataT];
    end
end

G = G(filterRows,:);

%--------------------------------------------------------------------------
function a = applyFunByGroup(grpStart,grpEnd,sortOrd,x,fun)
% APPLYFUNBYGROUP Apply function to data using sorted groups

% Allocate output
a = true(size(x,1),1);

% Apply function to groups
doReshape = ~ismatrix(x);
szXiter = size(x,2:ndims(x));
for g = 1:length(grpStart)
    gvals = x(sortOrd(grpStart(g):grpEnd(g)),:);
    if doReshape
        gvals = reshape(gvals, [size(gvals,1), szXiter]);
    end
    d = fun(gvals);

    if ~ismatrix(d) || ~(size(d,2) == 0 || size(d,2) == 1) || ~islogical(d)
        error(message("MATLAB:groupfilter:MethodOutputInvalidSize"));
    end

    if size(gvals,1) ~= size(d,1) && ~(isscalar(d) || (isempty(d) && isrow(d)))
        error(message("MATLAB:groupfilter:MethodOutputInvalidSize"));
    end

    if isempty(d)
        d = false;
    end

    a(sortOrd(grpStart(g):grpEnd(g)),:) = d;
end
