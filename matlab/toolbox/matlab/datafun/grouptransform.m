function [G,GR] = grouptransform(T,groupVars,method,varargin)
%GROUPTRANSFORM Transformations by group.
%   G = GROUPTRANSFORM(T,GROUPVARS,METHOD) or 
%   G = GROUPTRANSFORM(X,GROUPVARS,METHOD) groups the data in the variables
%   in table or timetable T, or the columns in a matrix or cell of matrices
%   X according to the grouping variables specified in GROUPVARS and
%   applies the METHOD to each group.
%
%   For table or timetable T, G is a table or timetable with the
%   computations specified by METHOD replacing the data of the non-grouping
%   variables. METHOD is applied group-wise to all non-grouping variables
%   in T. GROUPVARS specifies one or more variables in T that define the
%   groups of rows. Each group consists of rows in T that have the same
%   combination of values in those grouping variables. GROUPVARS must be a
%   table variable name, a cell array of table variable names, a vector of
%   table variable indices, a logical vector whose elements each correspond
%   to a table variable, a function handle that takes the table variables
%   as input and returns a logical scalar (such as @isnumeric), or a table
%   vartype subscript.
%
%   For matrix X, G is a matrix containing the results of applying the
%   METHOD to X by group. The groups are defined by rows in GROUPVARS that
%   have the same combination of values. GROUPVARS must have the same
%   number of rows as X and must be a column vector, multiple column
%   vectors stored as a matrix, or multiple column vectors stored in a cell
%   array.
%   GROUPVARS can also be [] to indicate no grouping.
%
%   METHOD can be a function handle or one of the following:
% 
%        "zscore"       - normalizes by centering the data to have mean 0 
%                         and scaling to have standard deviation 1
% 
%        "norm"         - normalizes by scaling the data to unit length 
%                         using the vector 2-norm
% 
%        "meancenter"   - normalizes by centering the data to have mean 0
% 
%        "rescale"      - normalizes by rescaling the range of the data to 
%                         the interval [0,1] 
% 
%        "meanfill"     - fill missing values with the mean of the group
% 
%        "linearfill"   - fill missing values using linear interpolation of 
%                         non-missing entries in the group
% 
%   G = GROUPTRANSFORM(T,GROUPVARS,GROUPBINS,METHOD) or
%   [G,GR] = GROUPTRANSFORM(X,GROUPVARS,GROUPBINS,METHOD) specifies the 
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
%   G = GROUPTRANSFORM(T,...,DATAVARS) applies the method only to the data 
%   in the table variables specified by DATAVARS. The default is all 
%   non-grouping variables in T. DATAVARS must be a table variable name, a 
%   cell array of table variable names, a vector of table variable indices,
%   a logical vector whose elements each correspond to a table variable, a 
%   function handle that takes the table variables as input and returns a 
%   logical scalar, or a table vartype subscript.
% 
%   G = GROUPTRANSFORM(...,"IncludedEdge",LR) specifies which edge is 
%   included for each bin in the discretization. This N-V pair can only be 
%   used when GROUPBINS is specified. LR must be one of the following:
%        "left"     - (default) all bins include the left bin edge, except  
%                   for the last bin which includes both edges.
%        "right"    - all bins include the right bin edge, except for the 
%                   first bin which includes both edges.
% 
%   G = GROUPTRANSFORM(...,"ReplaceValues",TF) specifies how the 
%   transformed data is returned. TF must be one of the following:
%        true       - (default) replace data variables with transformed 
%                   data
%        false      - appends the transformed data as additional matrix
%                   columns or table variables to the input data
%
%   [G,GR] = GROUPTRANSFORM(X,...) also returns the groups GR for any of
%   the previous matrix syntaxes.
%
%   Examples:
%
%      % Normalize concentration data by dose
%      Time = seconds([1;1;1;2;2;2;5;5;5;9;9;9]);
%      Dose = [1;2;3;1;2;3;1;2;3;1;2;3];
%      Concentration = [14.2;28.1;11.5;13.7;16.1;11;10;10;9.5;6;2;7.5];
%      T = timetable(Time,Dose,Concentration);
%      G = grouptransform(T,"Dose","zscore","Concentration")
%
%      % Fill missing temperature and pressure data by hour
%      t1 = datetime('2015-12-18 08:00:00');
%      t2 = datetime('2015-12-18 10:59:00');
%      Time = (t1:minutes(20):t2).';
%      Temp = [37.3;37.9;38.2;39.1;NaN;40.0;42.3;43.1;NaN];
%      Pressure = [30.1;30.2;30.1;30.03;NaN;30.1;29.9;29.8;29.7];
%      T = timetable(Time,Temp,Pressure);
%      G = grouptransform(T,"Time","hour","linearfill")
%
%      % Compute the difference between each pressure measurement and the
%      % hourly mean, i.e. center pressure mean to 0 by hour
%      [G,GR] = grouptransform(Pressure,Time,"hour","meancenter")
%
%   See also GROUPSUMMARY, GROUPFILTER, GROUPCOUNTS, FINDGROUPS, SPLITAPPLY, DISCRETIZE.

%   Copyright 2018-2023 The MathWorks, Inc.

narginchk(3,Inf);

% Compute matrix/table switch flag
tableFlag = istabular(T);

if tableFlag
    % Error if asking for more than 1 output for table
    nargoutchk(0,1);
end

% Parse grouping variables
[groupingData,groupVars] = matlab.internal.math.parseGroupVars(groupVars,tableFlag,"grouptransform:Group",T);

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
replaceDataVars = true;

% Parse groupbins
gbProvided = false;
dvNotProvided = true;
indStart = 1;
if matlab.internal.math.isgroupbins(method,"grouptransform")
    [groupBins,scalarExpandBins,scalarExpandVars] = matlab.internal.math.parsegroupbins(method,numel(gvLabels),"grouptransform:Group");
    gbProvided = true;
    if isempty(varargin)
        error(message("MATLAB:grouptransform:MethodNotProvided"));
    else
        method = varargin{indStart};
        indStart = indStart + 1;
    end
end
% Parse method
[method,methodPrefix] = parseMethod(method);
if nargin > 2+indStart
    if tableFlag
        %Parse data variables
        if (isnumeric(varargin{indStart}) || islogical(varargin{indStart}) || ...
                ((ischar(varargin{indStart}) || isstring(varargin{indStart})) && ...
                ~any(matlab.internal.math.checkInputName(varargin{indStart},["IncludedEdge","ReplaceValues"],1))) || ...
                isa(varargin{indStart},"function_handle") || iscell(varargin{indStart}) || ...
                rem(nargin-(indStart+1),2) == 0)

            dataVars = matlab.internal.math.checkDataVariables(T, varargin{indStart}, "grouptransform","Data");
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
                error(message("MATLAB:grouptransform:ParseFlags"));
            elseif matlab.internal.math.checkInputName(name,"IncludedEdge",1)
                if ~gbProvided
                    error(message("MATLAB:grouptransform:IncludedEdgeNoGroupBins"));
                end
                inclEdge = varargin{j+1};
            elseif matlab.internal.math.checkInputName(name,"ReplaceValues",1)
                replaceDataVars = varargin{j+1};
                matlab.internal.datatypes.validateLogical(replaceDataVars,"ReplaceValues");
            else
                error(message("MATLAB:grouptransform:ParseFlags"));
            end
        end
    else
        error(message("MATLAB:grouptransform:KeyWithoutValue"));
    end
end

% Keep track of which groupVars have a group bin
gbForGV = false(size(groupVars));
if gbProvided
    % Discretize grouping variables and remove repeated pairs of grouping
    % variables and group bins
    [groupingData,groupVars,gvLabels,gbForGV] = matlab.internal.math.discgroupvar(groupingData,...
        groupVars,gvLabels,groupBins,inclEdge,scalarExpandBins,scalarExpandVars,"grouptransform",tableFlag);
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

% Compute group tranformations
gStats = cell(1,numDataVars);
gStatsLabel = strings(1,numDataVars);
[gvIdxSorted, gvIdxSortedIdx] = sort(gvIdx);
grpStart = find([1;diff(gvIdxSorted)>0]);
grpEnd = [grpStart(2:end)-1;length(gvIdxSorted)];
for ii = 1:numDataVars
    try
        x = dvData{ii};
        
        % If not grouping by anything then apply method directly - this
        % only happens when the inputs are empty since we always include
        % missing groups in grouptransform
        if isempty(gvIdx)
            % Need to special case mean fill of an empty since mean of an
            % empty will return NaN
            if isempty(x) && strcmp(methodPrefix,"meanfill")
                d = x;
            else
                d = method(x);
            end
            if ~tableFlag
                if length(size(d)) ~= 2 || ~(size(d,2) == 0 || size(d,2) == 1)
                    error(message("MATLAB:grouptransform:MethodOutputInvalidSize"));
                end
            end
            if (size(d,1) ~= size(x,1)) && ~(isscalar(d) && size(x,1) == 0) ...
                    && size(d,1) ~= 0 % Output should be empty here
                    error(message("MATLAB:grouptransform:MethodOutputInvalidSize"));
            end
            if size(d,1) ~= size(x,1)
                % Make sure that the output is always the same height as
                % the input when, for example, d is a scalar we need to
                % shrink it to an empty
                d = repmat(d,size(x,1),1);
            end
        else
            % Otherwise apply function by group
            d = applyFunByGroup(grpStart,grpEnd,gvIdxSortedIdx,x,method,tableFlag,dataLabels(ii));
        end
        gStats{ii} = d;
        gStatsLabel(ii) = methodPrefix + "_" + dataLabels(ii);
    catch ME
        if (strcmp(ME.identifier,"MATLAB:grouptransform:MethodOutputInvalidSize"))
            rethrow(ME);
        else
            % Single error being thrown for all other possible problems above
            if tableFlag
                error(message("MATLAB:grouptransform:ApplyDataVarsError",dataLabels(ii)));
            else
                error(message("MATLAB:grouptransform:ApplyDataVecsError",dataLabels(ii)));
            end
        end
    end
end

% Prepare discretized groupingData
if (gbProvided && tableFlag) || nargout > 1
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
            % groupVars must be 0x0 or mx0 here because for 0xn numGroupVars is n
            GR = emptyfun(size(T,1),0);
            if issparse(groupVars)
                GR = sparse(GR);
            end
        else
            GR = groupingData;
        end
    end
end

if replaceDataVars % "ReplaceValues" true
    if tableFlag
        G = T;
        if gbProvided
            % Make sure all labels are unique
            uniqueLabels = matlab.lang.makeUniqueStrings([varNamesT,gvLabels],string(T.Properties.DimensionNames),namelengthmax);
            gdataT = table.init(groupingData,height(T),{},numel(groupingData),uniqueLabels(numel(varNamesT)+1:end));
            G = [G,gdataT];
        end
        for jj = 1:numDataVars
            G.(dataLabels(jj)) = gStats{:,jj};
        end
    else
        % Try to extract G from Data
        try
            G = [gStats{:}];
        catch ME
            % Error if data cannot be concatenated
            error(message("MATLAB:grouptransform:StatsCattable"));
        end
    end
else % "ReplaceValues" false
    if tableFlag
        if gbProvided
            % Make sure all labels are unique
            uniqueLabels = matlab.lang.makeUniqueStrings([varNamesT,gvLabels,gStatsLabel],string(T.Properties.DimensionNames),namelengthmax);
            vars = [groupingData,gStats];
            G = table.init(vars,height(T),{},numel(vars),uniqueLabels(numel(varNamesT)+1:end));
        else
            % Make sure all labels are unique
            uniqueLabels = matlab.lang.makeUniqueStrings([varNamesT,gStatsLabel],string(T.Properties.DimensionNames),namelengthmax);
            G = table.init(gStats,height(T),{},numel(gStats),uniqueLabels(numel(varNamesT)+1:end));
        end
        if isequal(T, timetable.empty)
            G = T;
        else
            G = [T,G];
        end
    else
        % Try to extract G from Data
        try
            G = [T,gStats{:}];
        catch ME
            % Error if results cannot be concatenated
            error(message("MATLAB:grouptransform:StatsCattable"));
        end
    end
end

%--------------------------------------------------------------------------
function [method,methodPrefix] = parseMethod(method)
%PARSEMETHOD Assembles method into a function handles

if ischar(method)
    method = string(method);
end
if numel(method) > 1
    error(message("MATLAB:grouptransform:InvalidMethodOption"));
end

if isstring(method) && ~any(startsWith(["zscore", "norm", "meancenter", "rescale", "meanfill", ...
        "linearfill"], method,"IgnoreCase",true))
    error(message("MATLAB:grouptransform:InvalidMethodOption"));
end

% Change each option to a function handle and set names appropriately
if isstring(method)
    if strncmpi(method,"zscore",1)
        method = @(x) normalizeArray(x,"zscore","std",1,[],[],false);
        methodPrefix = "zscore";
    elseif strncmpi(method,"norm",3)
        method = @(x) normalizeArray(x,"norm",2,1,[],[],false);
        methodPrefix = "norm";
    elseif strncmpi(method,"meancenter",5)
        method = @(x) normalizeArray(x,"center","mean",1,[],[],false);
        methodPrefix = "meancenter";
    elseif strncmpi(method,"rescale",1)
        method = @(x) normalizeArray(x,"range",[0 1],1,[],[],false);
        methodPrefix = "rescale";
    elseif strncmpi(method,"meanfill",5)
        method = @(x) fillmissing(x,"constant",mean(x,1,"omitnan"),1);
        methodPrefix = "meanfill";
    elseif strncmpi(method,"linearfill",1)
        method = @(x) fillmissing(x,"linear",1);
        methodPrefix = "linearfill";
    else
        error(message("MATLAB:grouptransform:InvalidMethodOption"));
    end
else
    if ~isa(method,"function_handle")
        error(message("MATLAB:grouptransform:InvalidMethodOption"));
    end
    methodPrefix = "fun";
end

%--------------------------------------------------------------------------
function a = applyFunByGroup(grpStart,grpEnd,sortOrd,x,fun,tableFlag,dataLabels)
% APPLYFUNBYGROUP Apply function to data using sorted groups

% Apply the function to the first group to get the type/size of the output
% to preallocate

grpSz = grpEnd(1) - grpStart(1) + 1;

szXiter = size(x,2:ndims(x));
gvals = reshape(x(sortOrd(grpStart(1):grpEnd(1)),:), [grpSz, szXiter]);
d = fun(gvals);
szD1 = size(d,1);
szD = size(d,2:ndims(d));

if grpSz ~= szD1 && ~(isscalar(d) || (isempty(d) && szD1 == 1) || (tableFlag && szD1 == 1))
    error(message("MATLAB:grouptransform:MethodOutputInvalidSize"));
end

if ~tableFlag && (length(size(d)) ~= 2 || ~(size(d,2) == 0 || size(d,2) == 1))
    error(message("MATLAB:grouptransform:MethodOutputInvalidSize"));
end

useIdxOutput = false;
if ~ismatrix(d)
    useIdxOutput = true;
    idxOutput = repmat({':'},ndims(x)-1,1);
end

% Allocate output - use d to figure out type, but since d could have height
% of the number of group elements, just use a sample to get the right size
if ~isempty(d)
    a = repmat(d(1),[size(x,1),szD]);
else
    if useIdxOutput
        a = repmat(d(1,idxOutput{:}),size(x,1),1);
    else
        a = repmat(d(1,:),size(x,1),1);
    end
end

% Fill output with result of function applied to first group
if (tableFlag && szD1 == 1) || (~tableFlag && issparse(d) && isempty(d) && szD1 == 1)
    d = repmat(d,grpSz,1);
end
if useIdxOutput
    a(sortOrd(grpStart(1):grpEnd(1)),idxOutput{:}) = d;
else
    a(sortOrd(grpStart(1):grpEnd(1)),:) = d;
end


% Apply function to remaining groups
for g = 2:length(grpStart)
    grpSz = grpEnd(g) - grpStart(g) + 1;

    gvals = reshape(x(sortOrd(grpStart(g):grpEnd(g)),:), [grpSz, szXiter]);
    d = fun(gvals);
    szD1 = size(d,1);

    if grpSz ~= szD1 && ~(isscalar(d) || (isempty(d) && szD1 == 1) || (tableFlag && szD1 == 1))
        error(message("MATLAB:grouptransform:MethodOutputInvalidSize"));
    end
    if ~isequal(size(d,2:ndims(d)),szD)
        if tableFlag
            error(message("MATLAB:grouptransform:ApplyDataVarsError",dataLabels));
        else
            error(message("MATLAB:grouptransform:ApplyDataVecsError",dataLabels));
        end
    end
    if szD1 == 1 && (tableFlag || (~tableFlag && issparse(d) && isempty(d)))
        d = repmat(d,grpSz,1);
    end
    if useIdxOutput
        a(sortOrd(grpStart(g):grpEnd(g)),idxOutput{:}) = d;
    else
        a(sortOrd(grpStart(g):grpEnd(g)),:) = d;
    end
end

