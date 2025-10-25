function b = splitvars(a,varsToSplit,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.

import matlab.internal.datatypes.matricize

% Find the variables that are not simply column vectors. They can be either
% multi-column matrices, higher-dimension arrays, or tables. For
% higher-dimension arrays, later they are matricized before splitting the
% 2nd dimension into multiple variables.
nvars = a.varDim.length;
widthVars = zeros([1,nvars]);
isTabularVars = false([1,nvars]);
for ii= 1:nvars
    data = a.data{ii};
    isTabularVars(ii) = isa(data, 'tabular');
    sz = size(data);
    sz(1) = [];
    widthVars(ii) = prod(sz);
end
if nargin < 2
    varsToSplit = widthVars > 1 | isTabularVars;
end
if nargin > 2
    pnames = {'NewVariableNames'};
    dflts =  {                  []};
    [splitVarNames,supplied] ...
        = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
else
    splitVarNames = [];
    supplied.NewVariableNames = false;
end
if isa(varsToSplit,'vartype')
    error(message('MATLAB:table:splitvars:VartypeInvalidVars'))
end
varsToSplit = a.varDim.subs2inds(varsToSplit);
b = a(:,~ismember(1:nvars,varsToSplit));

if numel(unique(varsToSplit)) ~= numel(varsToSplit)
    % Vars being split should not have duplicates
    error(message('MATLAB:table:splitvars:DuplicateVars'));    
end

% Check if there are any duplicate names between the tables being split,
% and set the flag to true to fix the names later.
duplicateInnerVarnames = false;
vars = a.data(:,varsToSplit(isTabularVars(varsToSplit))); % extract only tabular vars from those being split
innerVarNames = {};
for i = 1:numel(vars)
	innerVarNames = [innerVarNames vars{i}.varDim.labels]; %#ok<AGROW>
end

if numel(unique(innerVarNames)) ~= numel(innerVarNames)
    % Duplicate variable name found from inner tables being split, set the
    % flag to true.
    duplicateInnerVarnames = true;
end

% If splitting multiple variable and NewVariableNames is provided, make
% sure that it's a cell array the same length as the number of variables to
% split, with each cell a cellstr of varnames.
if supplied.NewVariableNames && numel(varsToSplit) > 1
    if numel(varsToSplit) ~= length(splitVarNames)
        error(message('MATLAB:table:splitvars:IncorrectNumVarnamesMultisplit'));
    end
    for v = 1:numel(varsToSplit)
        if ~matlab.internal.datatypes.isText(splitVarNames{v}, true) % forbid char
            error(message('MATLAB:table:splitvars:IncorrectNumVarnamesMultisplit'));
        end
    end
end

% newInds needs to be sorted to avoid assigning beyond the end of the b
% when it only includes the vars not being split.
varsToSplit = sort(varsToSplit);
newInds = varsToSplit;

% Loop through each variable to split, create separate tables.
for ii = 1:numel(varsToSplit)
    % Explicitly call dotReference to always dispatch to subscripting code, even
    % when the variable name matches an internal tabular property/method.
    var = a.dotReference(varsToSplit(ii)); % var = a.(varsToSplit(ii))
    varname = a.varDim.labels{varsToSplit(ii)};
    istabularVar = isTabularVars(varsToSplit(ii));
    widthVar = widthVars(varsToSplit(ii));
    
    
    % Split
    if ~istabularVar
        if ~ismatrix(var)
            var = matricize(var);
        end
        newvars = num2cell(var,1);
    else % istabular
        newvars = var.data;
        if var.rowDim.hasLabels
            newvars = [{var.rowDim.labels} newvars]; %#ok<AGROW>
        end
    end
    
    % Get new var names to use for after splitting
    if ~supplied.NewVariableNames
        if widthVar == 1 && ~istabularVar
            % If the given var to split has 1 column, and new variable
            % names are not given take the original variable name.
            newvarnames = varname;
        elseif ~istabularVar
            newvarnames = matlab.internal.datatypes.numberedNames([varname,'_'],1:widthVar);
        else % istabular: use existing names from table being split.
            newvarnames = var.varDim.labels;
            % If there are conflicts with existing varnames, add table name
            % at the front.
            if any(ismember(newvarnames,b.varDim.labels)) || duplicateInnerVarnames
                newvarnames = append(varname, '_', newvarnames);
            end
            if var.rowDim.hasLabels
                newvarnames = [append(varname, '_', var.metaDim.labels{1}) newvarnames]; %#ok<AGROW>
            end
        end
        % Make sure the names are unique w.r.t existing variables.
        newvarnames = matlab.lang.makeUniqueStrings(newvarnames,[b.varDim.labels,b.metaDim.labels],namelengthmax);
    else % supplied.NewVariableNames
        % Convenience, if they are splitting multiple variables, treat each
        % cell of the cell array as containing the variable names for each
        % variable being split. If they are splitting a single variable,
        % the cell array contains names for that one specific variable.
        if ~isscalar(varsToSplit)
            newvarnames = splitVarNames{ii};
        else
            newvarnames = splitVarNames;
        end
    end
    
    % Insert the new split variable, with the new names.
    b = addvars(b,newvars{:},'Before',newInds(ii),'NewVariableNames',newvarnames);
    if isa(var,'tabular')
        % Move per-variable metadata from the original nested table var
        % into the newly split vars in b. If var has row labels, account
        % for them in the position of the newvarnames whose metadata are
        % being copied.
        b.varDim = b.varDim.moveProps(var.varDim, 1:var.varDim.length, b.varDim.subs2inds(newvarnames(1+var.rowDim.hasLabels:end)));
    else % array
        % Move per-var metadata from the outer varsToSplit into the newly
        % split vars in b, replicating it to all the split vars.
        b.varDim = b.varDim.moveProps(a.varDim, varsToSplit(ii), b.varDim.subs2inds(newvarnames));
    end
    
    % update indices based on the width of the added split vars (note that
    % the unsplit variable counts as one, so subtract 1):
    newInds = newInds + length(newvars)-1;
end
