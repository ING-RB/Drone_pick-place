function [group,glabels,glocs] = table2gidx(a,varIndices,reduce) %#codegen
% TABLE2GIDX Create group indices from table grouping variables.

%   Copyright 2020 The MathWorks, Inc.

% Default behavior is to leave out categories that are not actually present in
% the data of a categorical variable. Non-categorical variables _always_, in
% effect, do that.
if nargin < 3, reduce = true; end

a_data = a.data;
a_varnames = a.varDim.labels;
nrows = a.rowDimLength;
ngroupVars = coder.const(length(varIndices));
if ngroupVars == 0 % if no grouping vars, create one group containing all observations
    group = ones(nrows,1);
    glocs = ones(min(nrows,1),1); % 1 if there are rows, 0x1 if not
    glabels = {'All'};

elseif ngroupVars == 1
    % Create an index vector based on the unique values of the grouping variable
    if varIndices == 0 % the row labels
        [group,glabels,glocs] = grp2idx(a.rowDim.labels,a.metaDim.labels{1},reduce);
    else
        [group,glabels,glocs] = grp2idx(a_data{varIndices},a_varnames{varIndices},reduce);
    end

else % ngroupVars > 1
    % Get integer group codes and names for each grouping variable
    groupsWithMissing = zeros(nrows,ngroupVars);
    names = coder.nullcopy(cell(1,ngroupVars));
    for j = 1:ngroupVars
        index_j = varIndices(j);
        if index_j == 0
            var_j = a.rowDim.labels;
            name_j = a.metaDim.labels{1};
        else
            var_j = a_data{index_j};
            name_j = a_varnames{index_j};
        end
        [groupsWithMissing(:,j),names{j}] = grp2idx(var_j,name_j,reduce);
    end

    % Create an index vector based on the unique combinations of individual grouping variables
    wasnan = any(isnan(groupsWithMissing),2);
    group = NaN(size(wasnan));
    groups = groupsWithMissing(~wasnan,:);
    [urows,glocs,gidx] = sortedUnique(groups,'rows');
    ngroups = size(urows,1);
    group(~wasnan) = gidx;

    % Translate the NaN-reduced row indices back to the original rows 
    tmp = find(~wasnan); glocs = tmp(glocs);

    % Do not bother creating actual names, currently this is only used in varfun
    % and varfun only needs to know the correct size of glabels.
    glabels = urows(:,1);
end

%-------------------------------------------------------------------------------
function [gidx,gnames,gloc] = grp2idx(varIn,varName,reduce)
% GRP2IDX  Create index vector from a grouping variable.
%   [G,GN,GL] = GRP2IDX(S) creates an index vector G from the grouping variable
%   S. S can be a categorical, numeric, string, or logical vector; a cell vector
%   of character vectors; or a character matrix with each row representing a
%   group label. G is a vector of integer values from 1 up to the number K of
%   distinct groups. GN is a cell array of character vectors containing group
%   labels. GN(G) reproduces S (aside from any differences in type). GL is a
%   vector of indices into the first element of S for each group.
%
%   GRP2IDX treats NaNs (numeric or logical), empty character vectors (char
%   or cell array of character vectors), or <undefined> values
%   (categorical) in S as missing values and returns NaNs in the
%   corresponding rows of G. Neither GN nor GL include entries for missing
%   values.

if ischar(varIn)
    if isempty(varIn)
        var = cell(0,1);
    else
        len = size(varIn,1);
        var = coder.nullcopy(cell(len,1));
        for i = 1:len
            var{i} = varIn(i,:);
        end
    end
else
    var = varIn;
end

% only allow columns with fixed size along second and higher dimensions 
coder.internal.assert(iscolumn(var),'MATLAB:table:GroupingVarNotColumn','IfNotConst','Fail');

if isa(var,'categorical')
    if reduce
        [glevels,gloc,gidx] = unique(var);
        if ~isempty(glevels) && isundefined(glevels(end)) % undefineds are sorted to end
            notNaN = ~isundefined(glevels);
            glevels = glevels(notNaN);
            gloc = gloc(notNaN);
            gidx(gidx > length(glevels)) = NaN; % other indices stay the same
        end
        gnames = cellstr(glevels);
    else
        gidx = double(var); % converts <undefined> to NaN
        gnames = categories(var)';
        [~,gloc] = ismember(1:length(gnames),gidx);
    end
else
    
        
    if isnumeric(var) || islogical(var) || isstring(var) || isdatetime(var) || isduration(var) || isa(var,'calendarDuration')
        if ~isdatetime(var)
            % Datetime allows unsorted inputs to unique, for other types we need
            % to call sort before calling unique.
            % Check for string scalar group variables first, which is not
            % supported in codegen
            coder.internal.errorIf(isstring(var), 'MATLAB:table:StringGroupType');
            [glevelsWithMissing,glocWithMissing,gidx] = sortedUnique(var);
        else
            [glevelsWithMissing,glocWithMissing,gidx] = unique(var,'sorted');
        end
    
        coder.internal.assert(size(gidx,1) == size(var,1),...
            'MATLAB:table:VarUniqueMethodFailedNumRows',varName);
        % Handle missing values: return NaN group indices
        if ~isempty(glevelsWithMissing) && ismissing(glevelsWithMissing(end)) % missing values are sorted to end
            notMissing = ~ismissing(glevelsWithMissing);
            glevels = glevelsWithMissing(notMissing);
            gloc = glocWithMissing(notMissing);
            gidx(gidx > length(glevels)) = NaN; % other indices stay the same
        else
            glevels = glevelsWithMissing;
            gloc = glocWithMissing;
        end
    else
        coder.internal.assert(iscell(var),'MATLAB:table:GroupTypeIncorrect');
        % Check for cellstr separately, to give the same error as MATLAB.
        coder.internal.assert(iscellstr(var),'MATLAB:table:VarUniqueMethodFailed',varName); %#ok<ISCLSTR>
        cellstr_var = var;
        if coder.internal.isConst(size(cellstr_var)) && ~isempty(cellstr_var)
            coder.varsize('cellstr_var',[],[false false]);
        end
        [glevelsWithMissing,glocWithMissing,gidx] = matlab.internal.coder.datatypes.cellstr_unique(cellstr_var,'sorted');
        
        coder.internal.assert(size(gidx,1) == size(var,1),...
            'MATLAB:table:VarUniqueMethodFailedNumRows',varName);
        % Handle empty char vector missing values: return NaN group indices
        if ~isempty(glevelsWithMissing) && isempty(glevelsWithMissing{1}) % empty '' are sorted to beginning
            % All empties are treated as '', but defensively find the number of empty strings
            len = length(glevelsWithMissing);
            notNaN = true(len,1);
            for i = 1:len
                if isempty(glevelsWithMissing{i})
                    notNaN(i) = false;
                end
            end
            nEmpty = len - sum(notNaN);
            % Use cellstr_parenReference here
            glevels = coder.nullcopy(cell(nnz(notNaN),1));
            idx = 1;
            for i = 1:len
                if notNaN(i)
                    glevels{idx} = glevelsWithMissing{i};
                    idx = idx + 1;
                end
            end
            gloc = glocWithMissing(notNaN);
            adjustIdx = [NaN(1,nEmpty) 1:length(glevels)]';
            gidx = adjustIdx(gidx);
        else
            glevels = glevelsWithMissing;
            gloc = glocWithMissing;
        end
        gnames = glevels;
    end
    gnames = glevels;
end


%-------------------------------------------------------------------------------
function [c,ia,ic] = sortedUnique(a,~)
% Helper to do a sorted unique. If the second argument is supplied we call
% unique with the rows flag.
if nargin < 2
   sortingFunc = @sort;
   uniqueFunc = @(x)unique(x,'sorted');
else
   sortingFunc = @sortrows;
   uniqueFunc = @(x)unique(x,'sorted','rows');
end

[sortedA, sortedIA] = sortingFunc(a);
[c,ia,ic] = uniqueFunc(sortedA);
ia = sortedIA(ia);
[~,ord] = sort(sortedIA);
ic = ic(ord);
