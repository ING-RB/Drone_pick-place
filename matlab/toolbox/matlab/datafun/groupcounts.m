function [GC,GR,GP] = groupcounts(T,varargin)
%GROUPCOUNTS Counts by group.
%   GC = GROUPCOUNTS(T,GROUPVARS) for a table or timetable T, returns a
%   table containing the number of elements in each group and percentage of
%   each group. GROUPVARS specifies one or more variables in T that define
%   the groups of rows. Each group consists of rows in T that have the same
%   combination of values in those grouping variables. GROUPVARS must be a
%   table variable name, a cell array of table variable names, a vector of
%   table variable indices, a logical vector, a function handle that
%   returns a logical scalar (such as @isnumeric), or a table vartype
%   subscript. GROUPVARS can also be [] to indicate no grouping.
%
%   GC = GROUPCOUNTS(X) for a matrix X of grouping vectors, returns a
%   vector containing the number of elements in each group created by the
%   unique combinations of rows in X. X must be a column vector, a group of
%   column vectors stored as a matrix, or a group of column vectors stored
%   in a cell array.
%
%   GC = GROUPCOUNTS(T,GROUPVARS,GROUPBINS) or
%   GC = GROUPCOUNTS(X,GROUPBINS) additionally specifies the GROUPBINS to 
%   be applied to GROUPVARS or X prior to grouping. If GROUPBINS is one of 
%   the options from the list below, then that discretization is applied to
%   every grouping variable. Otherwise, GROUPBINS must be a cell array with 
%   one element for each grouping variable or there must be one grouping
%   variable. Elements of GROUPBINS can be one of the following:
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
%   GC = GROUPCOUNTS(___,"IncludeMissingGroups",TF) specifies whether 
%   groups of missing data in the grouping variables are included and given  
%   their own category. TF must be one of the following:
%      true     - (default) include missing groups 
%      false    - exclude missing groups
%
%   GC = GROUPCOUNTS(___,"IncludeEmptyGroups",TF) specifies whether groups  
%   with 0 elements are included in the output. TF must be one of the 
%   following:
%      true     - include empty groups 
%      false    - (default) exclude empty groups
%
%   GC = GROUPCOUNTS(___,"IncludedEdge",LR) specifies which edge is  
%   included for each bin in the discretization. This N-V pair can only be  
%   used when GROUPBINS is specified. LR must be one of the following:
%      "left"     - (default) all bins include the left bin edge, except  
%                 for the last bin which includes both edges.
%      "right"    - all bins include the right bin edge, except for the  
%                 first bin which includes both edges.
%
%   [GC,GR,GP] = GROUPCOUNTS(X,___) also returns the groups GR and the
%   percentages GP for any of the previous matrix syntaxes.
%
%   Examples:
%
%      % Load data and create table
%      load patients;
%      T = table(Age,Gender,Smoker);
%
%      % Count the number of patients grouped by gender and smoker
%      GC = groupcounts(T,["Gender","Smoker"])
%
%      % Count the number of patients grouped by age discretized into
%      % 4 bins
%      GC = groupcounts(T,"Age",4)
%
%      % Count the number of patients grouped by gender and age, and
%      % discretize age using bin edges
%      [GC,GR] = groupcounts({Gender,Age},{"none",[20 30 40 50 Inf]})
%
%   See also GROUPSUMMARY, GROUPTRANSFORM, GROUPFILTER, FINDGROUPS, DISCRETIZE.

%   Copyright 2018-2023 The MathWorks, Inc.

narginchk(1,Inf);

% Compute matrix/table switch flag
tableFlag = istabular(T);

% Initial processing depends on table vs matrix
if tableFlag
    % Make sure we have at least 2 inputs and only 1 output for table input
    narginchk(2,Inf);
    nargoutchk(0,1);
    
    % Parse grouping variables
    [groupingData,groupVars] = matlab.internal.math.parseGroupVars(varargin{1},tableFlag,"groupcounts:Group",T);
       
    % Create labels for groupVars in output table
    gvLabels = groupVars;
    
    % Create label for the group count in output table
    gcLabel = ["GroupCount","Percent"];
else
    % Parse grouping variables
    [groupingData,groupVars] = matlab.internal.math.parseGroupVars(T,tableFlag,"groupcounts:Group");
    
    % To avoid errors create numbered labels
    gvLabels = string(1:numel(groupingData));
end

% Set rest of default values
inclEmpty = false;
inclNan = true;
inclEdge = "left";

% Parse remaining inputs
gbProvided = false;
if (nargin > 2) || (~tableFlag && nargin > 1)
    if tableFlag
        indStart = 2;
    else
        indStart = 1;
    end
    % Parse groupbins
    if matlab.internal.math.isgroupbins(varargin{indStart},"groupcounts")
        [groupBins,scalarExpandBins,scalarExpandVars] = matlab.internal.math.parsegroupbins(varargin{indStart},numel(gvLabels),"groupcounts:Group");
        indStart = indStart + 1;
        gbProvided = true;
    end
    
    % Parse name-value pairs
    if rem(nargin-(indStart),2) == 0
        for j = indStart:2:length(varargin)
            name = varargin{j};
            if (~(ischar(name) && isrow(name)) && ~(isstring(name) && isscalar(name))) ...
                || (isstring(name) && strlength(name) == 0)
                error(message("MATLAB:groupcounts:ParseFlags"));
            elseif matlab.internal.math.checkInputName(name,"IncludeEmptyGroups",8)
                inclEmpty = varargin{j+1};
                matlab.internal.datatypes.validateLogical(inclEmpty,"IncludeEmptyGroups");
            elseif matlab.internal.math.checkInputName(name,"IncludeMissingGroups",8)
                inclNan = varargin{j+1};
                matlab.internal.datatypes.validateLogical(inclNan,"IncludeMissingGroups");
            elseif matlab.internal.math.checkInputName(name,"IncludedEdge",8)
                if ~gbProvided
                    error(message("MATLAB:groupcounts:IncludedEdgeNoGroupBins"));
                end
                inclEdge = varargin{j+1};
            else
                error(message("MATLAB:groupcounts:ParseFlags"));
            end
        end
    else
        % Return appropriate error message
        nextVarargin = varargin{indStart};
        if (ischar(nextVarargin) && (~isrow(nextVarargin) || ~startsWith(nextVarargin,"Inc","IgnoreCase",true))) ...
                || (isstring(nextVarargin) && (~isscalar(nextVarargin) || ~startsWith(nextVarargin,"Inc","IgnoreCase",true))) ...
                || isa(nextVarargin,"function_handle") || iscategorical(nextVarargin)
            % Next invalid argument is a char/string column vector,
            % char/string that doesn't start with 'Inc,' a function handle,
            % or categorical
            error(message("MATLAB:groupcounts:GroupBinsEmpty"));
        else
            % Error may be related to incomplete N-V pair
            error(message("MATLAB:groupcounts:KeyWithoutValue"));
        end
    end
end

if gbProvided
    % Discretize grouping variables and remove repeated pairs of grouping
    % variables and group bins
    [groupingData,groupVars,gvLabels] = matlab.internal.math.discgroupvar(groupingData,...
        groupVars,gvLabels,groupBins,inclEdge,scalarExpandBins,scalarExpandVars,"groupcounts",tableFlag);
else
    if tableFlag
        % Remove repeated groupvars
        [groupVars,ridx] = unique(groupVars,"stable");
        groupingData = groupingData(ridx);
        gvLabels = gvLabels(ridx);
    end
end

% Compute final number of grouping variables from labels
numGroupVars = numel(gvLabels);

% Compute grouping index and data
needUniqueGData = false;
needGData = tableFlag || nargout > 1;
needCounts = true;
[~,~,~,gData,gCount] = matlab.internal.math.mgrp2idx(groupingData,size(T,1),...
    inclNan,inclEmpty,needUniqueGData,needGData,needCounts);

% Set group count correctly in case of 0xN input
if ~tableFlag && size(T,1) == 0 
    gCount = zeros(0,1);
end

% Compute percentage
sGCount = sum(gCount,1);
if sGCount == 0
    % Return the same as gCount when gCount is empty or 0
    gPercentage = gCount;
else
    gPercentage = (gCount*100)/sGCount;
end

if tableFlag
    % Create output table
    if isempty(groupVars)
        GC = table.init({gCount,gPercentage},numel(gCount),{},2,gcLabel);
    else
        % Make sure labels are unique
        uniqueLabels = matlab.lang.makeUniqueStrings([gvLabels,gcLabel],["Row", "Variables"],namelengthmax);
        vars = [gData,{gCount},{gPercentage}];
        GC = table.init(vars,numel(gCount),{},numel(vars),uniqueLabels);
    end
    
else
    % Set group counts
    GC = gCount;
    
    % If requested also return groups and percentages
    if nargout > 1
        % Set groups
        if numGroupVars == 1
            GR = gData{1};
        elseif numGroupVars ==0
            emptyfun = str2func([class(T) '.empty']);
            if size(T,1) == 0
                % groupVars must be 0x0 here because for 0xn, numGroupVars is n
                GR = emptyfun(0,0);
            else
                GR = emptyfun(1,0);
            end
            if issparse(T)
                GR = sparse(GR);
            end
        else
            GR = gData;
        end
        GP = gPercentage;
    end
end
