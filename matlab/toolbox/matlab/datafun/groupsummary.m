function [G,GR,GC] = groupsummary(T,groupVars,varargin)
%GROUPSUMMARY Summary computations by group.
%   G = GROUPSUMMARY(T,GROUPVARS,METHOD) or 
%   G = GROUPSUMMARY(X,GROUPVARS,METHOD) groups the data in the variables
%   in table or timetable T, or the columns in a matrix or cell of matrices
%   X according to the grouping variables specified in GROUPVARS and
%   applies the METHOD to each group.
%
%   For table or timetable T, G is a table containing the unique groups,
%   group counts and the results of applying the methods to the groups.
%   Each row in G contains the results of the computations specified by
%   METHOD for one group of data in T. GROUPVARS specifies one or more
%   variables in T that define the groups of rows. Each group consists of
%   rows in T that have the same combination of values in those grouping
%   variables. GROUPVARS must be a table variable name, a cell array of
%   table variable names, a vector of table variable indices, a logical
%   vector, a function handle that returns a logical scalar (such as
%   @isnumeric), or a table vartype subscript.
%
%   For matrix or cell X, G is a matrix containing the concatenated results
%   of applying the methods to the groups. Each row in G contains the
%   computations for one group. The groups are defined by rows in GROUPVARS
%   that have the same combination of values. GROUPVARS must have the same
%   number of rows as X or as cell elements of X and must be a column
%   vector, a group of column vectors stored as a matrix or a group of
%   column vectors stored in a cell array. 
%   GROUPVARS can also be [] to indicate no grouping.
%
%   METHOD can be a function handle or name, or a cell array containing 
%   multiple function handles or names. Names can be any of the following:
%
%      "mean"          - mean
%      "sum"           - sum
%      "min"           - minimum
%      "max"           - maximum
%      "range"         - maximum - minimum
%      "median"        - median
%      "mode"          - mode
%      "var"           - variance
%      "std"           - standard deviation
%      "nummissing"    - number of missing elements 
%      "nnz"           - number of non-zero and non-NaN elements
%      "numunique"     - number of distinct non-missing elements
%      "all"           - all methods above
%
%   When METHOD is a function handle with more than one input, use syntax
%   GROUPSUMMARY(T,___,METHOD,DATAVARS) below for table or timetable T.
%
%   When METHOD is a function handle with more than one input, X must be a
%   cell array of matrices, where each matrix contains the data for one of
%   the inputs to the METHOD. In each METHOD call, the input arguments are
%   corresponding columns of the matrices. For example, if X is a cell with
%   two matrices each having two columns X = {[a1,a2], [b1,b2]} and METHOD
%   is @(x,y)myfun, then the data passed to myfun is (a1,b1) and (a2,b2).
%
%   G = GROUPSUMMARY(T,GROUPVARS,GROUPBINS,METHOD) or
%   G = GROUPSUMMARY(X,GROUPVARS,GROUPBINS,METHOD) additionally specifies
%   the GROUPBINS to be applied to GROUPVARS prior to grouping. If 
%   GROUPBINS is one of the options from the list below, then that 
%   discretization is applied to every grouping variable. 
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
%   G = GROUPSUMMARY(T,GROUPVARS) for a table or timetable T, returns a 
%   table containing the number of elements in each group created by the 
%   unique combinations of grouping variables in GROUPVARS. 
%
%   G = GROUPSUMMARY(T,GROUPVARS,GROUPBINS) for a table or timetable T, 
%   returns a table containing the number of elements in each group created 
%   by the unique combinations of grouping variables in GROUPVARS binned 
%   according to GROUPBINS. 
% 
%   G = GROUPSUMMARY(T,___,METHOD,DATAVARS) applies the methods only to the 
%   data in the table variables specified by DATAVARS. The default is all 
%   non-grouping variables in T. DATAVARS must be a table variable name, a
%   cell array of table variable names, a vector of table variable indices,
%   a logical vector, a function handle that returns a logical scalar (such
%   as @isnumeric), or a table vartype subscript.
%
%   When METHOD is a function handle with more than one input, DATAVARS
%   must be a cell array where each element is any of the previous options
%   and specifies the table variables for each input to the METHOD. In each
%   METHOD call, the input arguments are corresponding table variables of
%   the cell elements. For example, if DATAVARS is a cell of table
%   variable names {["Var1","Var2"],["Var3","Var4"]} and METHOD is
%   @(x,y)myfun, then the data passed to myfun is (T.Var1,T.Var3) and
%   (T.Var2,T.Var4).
%
%   G = GROUPSUMMARY(___,"IncludeMissingGroups",TF) specifies whether 
%   groups of missing data in the grouping variables are included and given  
%   their own category. TF must be one of the following:
%      true     - (default) include missing groups 
%      false    - exclude missing groups
%
%   G = GROUPSUMMARY(___,"IncludeEmptyGroups",TF) specifies whether groups  
%   with 0 elements are included in the output. TF must be one of the 
%   following:
%      true     - include empty groups 
%      false    - (default) exclude empty groups
%
%   G = GROUPSUMMARY(___,"IncludedEdge",LR) specifies which edge is  
%   included for each bin in the discretization. This N-V pair can only be  
%   used when GROUPBINS is specified. LR must be one of the following:
%      "left"     - (default) all bins include the left bin edge, except  
%                 for the last bin which includes both edges.
%      "right"    - all bins include the right bin edge, except for the  
%                 first bin which includes both edges.
%
%   [G,GR] = GROUPSUMMARY(X,___) also returns the groups GR for any of the
%   previous matrix or cell syntaxes.
%
%   [G,GR,GC] = GROUPSUMMARY(X,___) also returns the group counts GC for
%   any of the previous matrix or cell syntaxes.
%
%   Examples:
%
%      % Load data and create table
%      load patients;
%      T = table(Age,Diastolic,Gender,Height,Smoker,Systolic,Weight);
%
%      % Compute the mean height by gender
%      G = groupsummary(T,"Gender","mean","Height")
%
%      % Compute the range for height and weight grouped by gender and age,
%      % and discretize age into 10 bins
%      G = groupsummary(T,["Gender","Age"],{"none",10},"range")
%
%      % Compute the variances of the differences between systolic and 
%      % diastolic blood-pressure readings for smokers and nonsmokers
%      G = groupsummary(T,"Smoker",@(x,y)var(x-y),{"Systolic","Diastolic"})
%
%      % Compute correlation between height and weight and systolic and 
%      % diastolic by gender
%      G = groupsummary(T,"Gender",@(x,y)xcov(x,y,0,'coeff'),...
%           {["Height","Systolic"],["Weight","Diastolic"]})
%
%      % Compute average weight by age groups
%      [G, GR, GC] = groupsummary(Weight,Age,[20 30 40 50 Inf],"mean")
%
%      % Compute average BMI by gender
%      [G, GR, GC] = groupsummary({Height,Weight},Gender,...
%           @(h,w)mean((w ./ (h.^2)) * 703))
%
%      % Compute correlation between age and weight and systolic and 
%      % height by gender
%      [G, GR, GC] = groupsummary({[Age,Systolic],[Weight,Height]},...
%           Gender,@(x,y)xcov(x,y,0,'coeff'))
%
%   See also GROUPTRANSFORM, GROUPFILTER, GROUPCOUNTS, FINDGROUPS, SPLITAPPLY, DISCRETIZE.

%   Copyright 2017-2023 The MathWorks, Inc.

narginchk(2,Inf);

% Compute matrix/table switch flag
tableFlag = istabular(T);

if tableFlag
    % Error if asking for more than 1 output for table
    nargoutchk(0,1);
end

% Parse grouping variables
[groupingData,groupVars] = matlab.internal.math.parseGroupVars(groupVars,tableFlag,"groupsummary:Group",T);

if tableFlag
    % Create labels for groupVars in output table
    gvLabels = groupVars;

    % Create label for the group count in output table
    gcLabel = "GroupCount";
    
    % Set default values for data variables
    varNamesT = string(T.Properties.VariableNames);
    dataVars = varNamesT;
else
    % To avoid errors create numbered labels
    gvLabels = string(1:numel(groupingData));
    dataVars = T;
end

% Set rest of default values
inclEmpty = false;
inclNan = true;
inclEdge = "left";
numMethods = 0;
numMethodInput = 1;
if iscell(T) && ~iscellstr(T) %#ok<ISCLSTR>
    numMethodInput = numel(T);
end
dvSets = {};
gbProvided = false;
groupBins = [];
scalarExpandBins = [];
scalarExpandVars = [];
dvNotProvided = true;
methods = [];
methodPrefix = [];

% Parse remaining inputs
if nargin > 2
    indStart = 1;
    % Parse group bins
    if matlab.internal.math.isgroupbins(varargin{indStart},"groupsummary")
        [groupBins,scalarExpandBins,scalarExpandVars,flag] = matlab.internal.math.parsegroupbins(varargin{indStart},numel(gvLabels),"groupsummary:Group");
        if flag
            indStart = indStart + 1;
            gbProvided = true;
        end
    end
    if indStart < nargin-1
        % Parse method
        if matlab.internal.math.isgroupmethod(varargin{indStart})
            [methods,methodPrefix,numMethods] = parseMethods(varargin{indStart});
            indStart = indStart + 1;
            if indStart < nargin-1
                if tableFlag
                    % Parse data variables
                    if iscell(varargin{indStart}) && ~iscellstr(varargin{indStart})
                        % This is the case where we have a cell where each
                        % input tells you the values for one input to the
                        % function handle method
                        dataVars = varargin{indStart};
                        numMethodInput = numel(dataVars);
                        % dataVars will be concatenated names of input sets
                        % to be passed to function handle
                        % dvSets is a numeric matrix where the columns
                        % represent the indices of input data sets
                        [dataVars,dvSets] = matlab.internal.math.checkMultDataVariables(T,dataVars,varNamesT,numMethodInput);
                        dvNotProvided = false;
                        indStart = indStart + 1;
                    elseif (isnumeric(varargin{indStart}) || islogical(varargin{indStart}) || ...
                            ((ischar(varargin{indStart}) || isstring(varargin{indStart})) && ...
                            ~any(matlab.internal.math.checkInputName(varargin{indStart},["IncludeEmptyGroups","IncludedEdge","IncludeMissingGroups"],8))) || ...
                            isa(varargin{indStart},"function_handle") || iscellstr(varargin{indStart}) || ...
                            rem(nargin-(indStart),2) == 0)
                        % This is the case where we have 1 input to the method
                        dataVars = matlab.internal.math.checkDataVariables(T, varargin{indStart}, "groupsummary", "Data");
                        dataVars = varNamesT(dataVars);
                        dataVars = unique(dataVars,"stable");
                        dvNotProvided = false;
                        indStart = indStart + 1;
                    end
                end
            end
        end
    end
    
    % Parse name-value pairs
    if rem(nargin-(1+indStart),2) == 0
        for j = indStart:2:length(varargin)
            name = varargin{j};
            if (~(ischar(name) && isrow(name)) && ~(isstring(name) && isscalar(name))) ...
                || (isstring(name) && strlength(name) == 0)
                error(message("MATLAB:groupsummary:ParseFlags"));
            elseif matlab.internal.math.checkInputName(name,"IncludeEmptyGroups",8)
                inclEmpty = varargin{j+1};
                matlab.internal.datatypes.validateLogical(inclEmpty,"IncludeEmptyGroups");
            elseif matlab.internal.math.checkInputName(name,"IncludeMissingGroups",8)
                inclNan = varargin{j+1};
                matlab.internal.datatypes.validateLogical(inclNan,"IncludeMissingGroups");
            elseif matlab.internal.math.checkInputName(name,"IncludedEdge",8)
                if ~gbProvided
                    error(message("MATLAB:groupsummary:IncludedEdgeNoGroupBins"));
                end
                inclEdge = varargin{j+1};
            else
                error(message("MATLAB:groupsummary:ParseFlags"));
            end
        end
    elseif (nargin < 4) || (gbProvided && nargin < 5)
        error(message("MATLAB:groupsummary:InvalidMethodOption"));
    else
        error(message("MATLAB:groupsummary:KeyWithoutValue"));
    end
end

needGdata = tableFlag || nargout >= 2;
needCounts = tableFlag || nargout == 3;
[gCount,gData,gStats,gvLabels,gStatsLabel] = matlab.internal.math.reducebygroup(T,...
    groupingData,groupVars,gvLabels,gbProvided,groupBins,inclEdge,scalarExpandBins,...
    scalarExpandVars,dataVars,dvNotProvided,dvSets,methods,methodPrefix,numMethods,...
    numMethodInput, "groupsummary",tableFlag,false,needGdata,needCounts,inclNan,inclEmpty);

% Compute final number of grouping variables from labels
numGroupVars = numel(gvLabels);

if numMethods == 0
    if tableFlag
        % Create output table
        if isempty(groupVars)
            G = table.init({gCount},numel(gCount),{},1,gcLabel);
        else
            % Make sure labels are unique
            uniqueLabels = matlab.lang.makeUniqueStrings([gvLabels,gcLabel],["Row", "Variables"],namelengthmax);
            vars = [gData,{gCount}];
            G = table.init(vars,numel(gCount),{},numel(vars),uniqueLabels);
        end
        return;
    else
        % Error if no methods are specified in matrix case
        error(message("MATLAB:groupsummary:MustSpecifyMethod"));
    end
elseif tableFlag
    % Make sure all labels are unique
    uniqueLabels = matlab.lang.makeUniqueStrings([gvLabels,gcLabel,gStatsLabel],["Row", "Variables"],namelengthmax);
    
    % Assemble results
    if numGroupVars == 0
        vars = [{gCount},gStats];
        G = table.init(vars,numel(gCount),{},numel(vars),uniqueLabels(numGroupVars+1:end));
    else
        vars = [gData,{gCount},gStats];
        G = table.init(vars,numel(gCount),{},numel(vars),uniqueLabels);
    end

else       
    % Try to extract G from data
    try
        G = [gStats{:}];
    catch ME
        % Error if data cannot be concatenated
        error(message("MATLAB:groupsummary:StatsCattable"));
    end
    
    % If requested also return groups
    if nargout > 1
        % Set groups
        if numGroupVars == 1
            GR = gData{1};
        elseif numGroupVars ==0
            emptyfun = str2func([class(groupVars) '.empty']);
            if size(T,1) == 0 || (iscell(T) && ~isempty(T) && size(T{1},1) == 0)
                % groupVars must be 0x0 here because for 0xn numGroupVars is n
                GR = emptyfun(0,0);
            else
                if size(groupVars,1) == 0
                    GR = emptyfun(1,0);
                else
                    GR = groupVars(1,:);
                end
            end
            if issparse(groupVars)
                GR = sparse(GR);
            end
        else
            GR = gData;
        end
    end
    
    % If requested return group counts also
    if nargout > 2
        % Set group counts
        GC = gCount;
    end
end
end

% -------------------------------------------------------------------------
function [methods,methodPrefix,numMethods] = parseMethods(methods)
%PARSEMETHODS Assembles groupsummary methods into a cell array of
%   function handles. This function checks and replaces 'all' with list of
%   methods then changes values into function handles and computes correct
%   prefixes for the methods given.
if isstring(methods)
    methods = num2cell(methods);
elseif ~iscell(methods)
    methods = {methods};
end

% Check for all option and invalid methods
numMethods = numel(methods);
allmethods = ["mean", "sum", "min", "max", "range", "median", "mode", "var", "std", "nummissing", "nnz", "numunique"];
isall = false(1,numMethods);
for k = numMethods:-1:2
    % first element is taken care of with isgroupmethod/groupMethod2FcnHandle
    if ~isa(methods{k},"function_handle")
        ind = matlab.internal.math.checkInputName(methods{k},[allmethods "all"]);
        if ~any(ind)
            error(message("MATLAB:groupsummary:InvalidMethodOption"));
        elseif ind(end)
            isall(k) = true;
            firstall = k;
        end
    end
end
if strncmpi(methods{1},"all",1)
    isall(1) = true;
    firstall = 1;
end

if any(isall)
    methods(isall) = [];    
    methods = [methods(1:firstall-1) num2cell(allmethods) methods(firstall:end)];
    numMethods = numel(methods);
end

% Change each option to a function handle and set names appropriately
methodPrefix = strings(1,numMethods);
numfun = 1;
for jj = 1:numMethods
    [methods{jj},methodPrefix(jj)] = matlab.internal.math.groupMethod2FcnHandle(methods{jj},"groupsummary");
    if isequal(methodPrefix(jj),"fun")
        methodPrefix(jj) = "fun" + string(numfun);
        numfun = numfun + 1;
    end
end

% Remove repeated method names
if ~isequal(numMethods,1)
    [methodPrefix,idx] = unique(methodPrefix,"stable");
    methods = methods(idx);
    numMethods = numel(methods);
end
end
