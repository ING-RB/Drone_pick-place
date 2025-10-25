function varargout = splitapply(fun,varargin)
% SPLITAPPLY Split data into groups and apply function
%   Y = SPLITAPPLY(FUN,X,G) splits the variable X into groups specified by G 
%   and applies the function FUN to each group. SPLITAPPLY returns Y as a 
%   column vector where each row contains the output from FUN for each group. 
%   Specify G as a vector of positive integers. You can use FINDGROUPS 
%   to create G. If G contains NaN values, SPLITAPPLY discards the 
%   corresponding values in X.
%
%   Y = SPLITAPPLY(FUN,X1,X2,...,G) splits variables X1,X2,... into groups 
%   specified by G and applies FUN to each group. SPLITAPPLY calls FUN once per 
%   group, with X1,X2,... as the input arguments to FUN.
%
%   [Y1,Y2,...] = SPLITAPPLY(FUN,...) splits variables into groups and
%   applies FUN to each group. FUN returns multiple output arguments.
%   Y1,...,YM contains the concatenated outputs from FUN for the groups
%   split out of the input data variables. FUN can return output arguments
%   that belong to different classes, but the class of each output must be
%   the same each time FUN is called. You can use this syntax with any of
%   the input arguments of the previous syntaxes.  The number of output
%   arguments from FUN need not be the same as the number of input
%   arguments specified by X1,...,XN.
%
%   Examples:
%      % Load patients data.
%      % List Height, Weight, Gender, and Smoker variables for patients.
%      load patients;
%      whos Height Weight Gender Smoker
%      
%      % Find groups of patients by gender and status as a smoker.
%      % Make a table that lists the four group identifiers.
%      [G,gender,smoker] = findgroups(Gender,Smoker);
%      results = table(gender,smoker)
%
%      % Split Weight into groups. Calculate mean weights for the groups
%      % of patients.
%      results.meanWeight = splitapply(@mean,Weight,G)
% 
%      % Find the average BMI by gender and status as a smoker.
%      meanBMIFcn = @(h,w)mean((w ./ (h.^2)) * 703);
%      results.meanBMI = splitapply(meanBMIFcn,Height,Weight,G)
%
%   See also FINDGROUPS, UNIQUE, VARFUN, ROWFUN

% Copyright 2015-2024 MathWorks, Inc.

% Check number of inputs
narginchk(3,inf);

gnums = varargin{end};
varargin(end) = [];

% Check Function handle
if ~isa(fun,'function_handle')
    error(message('MATLAB:splitapply:InvalidFunction'));
end

% Check indices
if isempty(gnums) || ~isnumeric(gnums) || ~isvector(gnums) || ...
        any(gnums <= 0) || issparse(gnums)
    error(message('MATLAB:splitapply:InvalidGroupNums'));
end

% Drop leading singleton dimensions to find dimension to split on
if iscolumn(gnums)
    gdim = 1;
else
    gnums = gnums(:);
    gdim = 2;
end
gsize = size(gnums,1);

% Ensure that indices are sorted
[gnums, sgnums] = sort(gnums);

% Account for NaN Groups
ngroups = max(gnums);
if isnan(ngroups) %for the case of gnums being all NaN
    emptyGroup = 1;
else
    emptyGroup = ngroups+1;
end

% Filter out empty group numbers
emptyIdx = isnan(gnums);
sgnums(emptyIdx,:) = emptyGroup;
gnums(emptyIdx,:) = emptyGroup;

% Check for non-integer group numbers (after filtering out the data) 
if any(floor(gnums) ~= gnums) || ~isreal(gnums)
    error(message('MATLAB:splitapply:InvalidGroupNums'));
end

% Check data
numArgs = numel(varargin);
for argnumber = 1:numArgs
    argsize = size(varargin{argnumber},gdim);
    if isscalar(gnums) || isequal(gsize, argsize)
        continue; % Sizes match
    end
    
    % Different error messages depending on grouping vector orientation
    if gdim == 1 %column vector gnums
        error(message('MATLAB:splitapply:RowMismatch', gsize, argnumber, argsize));
    elseif gdim == 2 %row vector gnums
        error(message('MATLAB:splitapply:ColumnMismatch', gsize, argnumber,argsize));
    end
end


% Check for non-continuous group numbers
% When sorted, valid group number vector will start at 1, and the numbers
% will not differ by more than 1
gdiffed = diff(gnums);
if ~isempty(gnums) && ((gnums(1) ~= 1) || ~all(gdiffed== 1 | gdiffed==0))
    error(message('MATLAB:splitapply:MissingGroupNums'));
end 

dataVars = {};
for argnumber = 1:numArgs
    expandedVars = expandVariables(varargin{argnumber});
    dataVars(end+1:end+size(expandedVars,2)) = expandedVars;
end

if isscalar(gnums)
   % Vector of group numbers is a scalar,  Use the first non-singleton
   % dimension as the dimension to split data on.
   sz = size(dataVars{1});
   gdim = find(sz == 1,1,'first');
   if isempty(gdim)
       gdim = 1;
   end
end

varargout = localsplitandapply(fun,dataVars,gdiffed,sgnums,gdim,nargout);

% Clean up NaN Groups
if any(emptyIdx)
    for ii = 1:length(varargout)
        % Preserve shape along non-grouping dimension when cleaning out NaN groups
        emptyGroupIdx = repmat({':'}, 1, ndims(varargout{ii}));
        emptyGroupIdx{gdim} = emptyGroup;
        varargout{ii}(emptyGroupIdx{:}) = [];
    end
end

end


%-------------------------------------------------------------------------------
function varRows = getVarRows(datavar,i,gdim)
if istabular(datavar) || (ismatrix(datavar) && gdim == 1)
    varRows = datavar(i,:);
elseif ismatrix(datavar) && gdim == 2
    varRows = datavar(:,i);
else
    % Each var could have any number of dims, no way of knowing,
    % except how many rows they have.  So just treat them as 2D to get
    % the necessary rows, and then reshape to their original dims.
    indexVar = repmat({':'}, 1, ndims(datavar));
    indexVar{gdim} = i;
    varRows = datavar(indexVar{:});
end
end

%-------------------------------------------------------------------------------
function finalOut = localsplitandapply(fun,vars,gdiffed,sgnums,gdim,nout)

% Find group begin and end
grpStart = find([1;gdiffed>0]);
grpEnd = [grpStart(2:end)-1;length(sgnums)];
numGroups = numel(grpStart);
numVars = numel(vars);

% Call function passing parameters
funOut = cell(numGroups,nout);
if (gdim > 1)
    funOut = funOut';
end

if numGroups == 1
    % When there is only one group apply function directly
    [funOut,nout] = localapply(fun,vars,gdim,nout,funOut,1,numVars);
else
    % Loop over the groups, extract the data for the group, and apply the
    % function
    for curGroup = 1:numGroups
        % Find the elements of the group
        groupNums = sgnums(grpStart(curGroup):grpEnd(curGroup));
        dataVars = cell(1,numVars);
        % Extract the group data
        for i = 1:numVars
            dataVars{1,i} = getVarRows(vars{i},groupNums,gdim);
        end
        % Apply the function to the group
        [funOut,nout] = localapply(fun,dataVars,gdim,nout,funOut,curGroup,numVars);
    end
end

finalOut = cell(1,nout);
for curVar = 1:nout
    if gdim == 1
        finalOut{curVar} = vertcat(funOut{:,curVar});
    else
        finalOut{curVar} = horzcat(funOut{curVar,:});
    end
end
end

%--------------------------------------------------------------------------
function [funOut,nout] = localapply(fun,dataVars,gdim,nout,funOut,curGroup,numVars)

try
    % Invoke the function based on the number of output arguments
    if nout > 0
        if nout == 1
            if gdim == 1
                funOut{curGroup,:} = fun(dataVars{1,:});
            else
                funOut{:,curGroup} = fun(dataVars{1,:});
            end
        else
            if gdim == 1
                [funOut{curGroup,:}] = fun(dataVars{1,:});
            else
                [funOut{:,curGroup}] = fun(dataVars{1,:});
            end
        end
    else
        clear ans;
        fun(dataVars{1,:});

        % did the call to 'fun' above output to ans?
        % If so pass it through.
        if exist('ans','var')
            funOut{1} = ans; %#ok<NOANS>
            nout = 1;
        end
    end
catch ME
    funStr = func2str(fun);
    m = message('MATLAB:splitapply:FunFailed',funStr,matlab.internal.datatypes.ordinalString(curGroup));
    throwAsCaller(addCause(MException(m.Identifier,getString(m)),ME));
end

if nout > 0
    for curVar=1:nout
        if gdim == 1
            var = funOut{curGroup,curVar};
        else
            var = funOut{curVar,curGroup};
        end

        if isscalar(var) || (size(var,gdim) == 1)
            % Output is Uniform
            continue;
        end

        % Construct a suggested correction to be included in the
        % error message
        funStr = func2str(fun);
        if strcmp(funStr(1), '@') % anonymous function
            funTokens = regexp(funStr, '(@\([^\(\)]*\))(.*)', 'tokens', 'once');
            funSuggest = [funTokens{1}, '{',funTokens{2},'}'];
        else % simple function handle
            funArgs = strjoin( strcat('x', strsplit(int2str(1:numVars)) ), ',');
            funSuggest = ['@(',funArgs,'){',funStr,'(',funArgs,')}'];
        end

        throwAsCaller(MException(message('MATLAB:splitapply:OutputNotUniform', ...
            funStr, matlab.internal.datatypes.ordinalString(curGroup), funSuggest)));
    end
end
end

%-------------------------------------------------------------------------------
function out = expandVariables(inVar)
    if istabular(inVar)
        out = cell(1, width(inVar));
        for k = 1:numel(out)
            out{k} = inVar.(k);
        end
    else
        out = {inVar};
    end
end
