function bout = splitvars(a,varsToSplit,varargin) %#codegen
%SPLITVARS Split multi-column variables in table or timetable.

%   Copyright 2020-2021 The MathWorks, Inc.

% Find the variables that are not simply column vectors. They can be either
% multi-column matrices, higher-dimension arrays, or tables. For
% higher-dimension arrays, later they are matricized before splitting the
% 2nd dimension into multiple variables.
coder.extrinsic('any','append','cat','matlab.lang.makeUniqueStrings','namelengthmax','unique','ismember','matlab.internal.datatypes.numberedNames');

nvars = a.varDim.length;
widthVars = zeros([1,nvars]);
isTabularVars = false([1,nvars]);
coder.unroll()
for i = 1:nvars
    data = a.data{i};
    isTabularVars(i) = isa(data, 'tabular');
    sz = size(data,2:ndims(data));

    widthVars(i) = coder.const(prod(sz));
end
if nargin < 2
    varsToSplit = widthVars > 1 | isTabularVars;
end
if nargin > 2
    pnames = {'NewVariableNames'};
    poptions = struct( ...
        'CaseSensitivity',false, ...
        'PartialMatching','unique', ...
        'StructExpand',false);
    
    supplied = coder.internal.parseParameterInputs(pnames, poptions, varargin{:});
    splitVarNames = coder.internal.getParameterValue(supplied.NewVariableNames,[],varargin{:});
    % variable names must be constant
                                coder.internal.assert(coder.internal.isConst(splitVarNames), ...
                                    'MATLAB:table:splitvars:NewVarNamesMustBeConstant');
    coder.const(splitVarNames);
else
    splitVarNames = [];
    supplied.NewVariableNames = false;
end

coder.internal.errorIf(isa(varsToSplit,'vartype'),'MATLAB:table:splitvars:VartypeInvalidVars');

varsToSplitInds = a.varDim.subs2inds(varsToSplit);

v = coder.const(~ismember(1:nvars,coder.const(varsToSplitInds)));

if coder.internal.isConstTrue(isempty(a))
    b = a.parenReference(:,v);
else
    b = a.parenReference(':',v);
end

% Vars being split should not have duplicates
coder.internal.errorIf(numel(coder.const(unique(varsToSplitInds))) ~= numel(varsToSplitInds),'MATLAB:table:splitvars:DuplicateVars');

% Check if there are any duplicate names between the tables being split,
% and set the flag to true to fix the names later.
duplicateInnerVarnames = false;

tabularVars = varsToSplitInds(isTabularVars(varsToSplitInds));
vars = cell(1,numel(tabularVars));
numInnerVars = 0;

for j = 1:numel(tabularVars)
    vars{j} = a.data{tabularVars(j)}; % extract only tabular vars from those being split
    numInnerVars = numInnerVars + numel(vars{j}.varDim.labels);
end

innerVarNames = cell(1,numInnerVars);
loc = 0;
coder.unroll()
for i =1:numel(vars)
    coder.unroll()
    for j = 1:numel(vars{i}.varDim.labels)
        loc = loc+1;
        innerVarNames{loc} = coder.const(vars{i}.varDim.labels{j});
    end
end

if numel(coder.const(unique(coder.const(innerVarNames)))) ~= numInnerVars
    % Duplicate variable name found from inner tables being split, set the
    % flag to true.
    duplicateInnerVarnames = true;
end

% If splitting multiple variable and NewVariableNames is provided, make
% sure that it's a cell array the same length as the number of variables to
% split, with each cell a cellstr of varnames.
if supplied.NewVariableNames && numel(varsToSplitInds) > 1
    coder.internal.errorIf(numel(varsToSplitInds) ~= length(splitVarNames),'MATLAB:table:splitvars:IncorrectNumVarnamesMultisplit');
    
    for v = 1:numel(varsToSplitInds)
        coder.internal.assert(matlab.internal.coder.datatypes.isText(splitVarNames{v}, true),'MATLAB:table:splitvars:IncorrectNumVarnamesMultisplit'); % forbid char
    end
end

varsToSplitInds = sort(varsToSplitInds);
newInds = varsToSplitInds;


growingPains = cell(1,numel(varsToSplitInds)+1);
growingPains{1} = b;

currentVar = cell(1,numel(varsToSplitInds));

% Loop through each variable to split, create separate tables.
coder.unroll()
for i = 1:numel(varsToSplitInds)
    j = varsToSplitInds(i);
    varRaw = a.data{j};
    currentVar{i} = a.varDim.labels{varsToSplitInds(i)};
    istabularVar = isTabularVars(varsToSplitInds(i));
    widthVar = widthVars(varsToSplitInds(i));
    
    % Split
    if ~istabularVar
        if ~ismatrix(varRaw)
            var = matlab.internal.coder.datatypes.matricize(varRaw);
        else
            var = varRaw;
        end
        
        newvars = cell(1,size(var,2));
        coder.unroll()
        for k = 1:size(var,2)
            
            if iscell(var)
                newvars{k} = coder.nullcopy(cell(size(var,1),1));
                for ii = 1:size(var,1)
                    newvars{k}{ii} = var{ii,k};
                end
            else
                newvars{k} = var(:,k);
            end
        end
        
        % newvars = num2cell(var,1);
    else % istabular
        var = varRaw;
        newvarsRaw = var.data;
        newvars = cell(1, numel(newvarsRaw)+var.rowDim.hasLabels);
        if var.rowDim.hasLabels
            % newvars = [{var.rowDim.labels},newvarsRaw];
            newvars{1} = var.rowDim.labels;
            for k = 1:numel(newvarsRaw)
                newvars{k+1} = newvarsRaw{k};
            end
        else
            newvars = newvarsRaw;
        end
    end
    
    % Get new var names to use for after splitting
    % NewVariableNames must be specified if adding any new variabe -- default names are not supported
    
    if ~supplied.NewVariableNames
        if widthVar == 1 && ~istabularVar
            % If the given var to split has 1 column, and new variable
            % names are not given take the original variable name.
            newvarnamesraw = currentVar{i};
        elseif ~istabularVar
            newvarnamesraw = coder.const(matlab.internal.datatypes.numberedNames(coder.const(cat(2,coder.const(currentVar{i}),'_')),coder.const(1:widthVar)));
        else % istabular: use existing names from table being split.
            
            % If there are conflicts with existing varnames, add table name
            % at the front.

            
            if coder.const(any(coder.const(ismember(var.varDim.labels,b.varDim.labels)))) || duplicateInnerVarnames
                newvarnamesrawNoRowNames = coder.const(append(coder.const(currentVar{i}), '_', var.varDim.labels));
            else
                newvarnamesrawNoRowNames = var.varDim.labels;
            end
            
            if var.rowDim.hasLabels
                newvarnamesraw = coder.const(cat(2,coder.const(append(coder.const(currentVar{i}), '_', var.metaDim.labels{1})),newvarnamesrawNoRowNames));
            else
                newvarnamesraw = newvarnamesrawNoRowNames;
            end
        end
        
        allLabels = coder.const(cat(2,growingPains{i}.varDim.labels,growingPains{i}.metaDim.labels));
        
        % Make sure the names are unique w.r.t existing variables.
        newvarnames = coder.const(matlab.lang.makeUniqueStrings(coder.const(newvarnamesraw),coder.const(allLabels),coder.const(namelengthmax)));
    else % supplied.NewVariableNames
        % Convenience, if they are splitting multiple variables, treat each
        % cell of the cell array as containing the variable names for each
        % variable being split. If they are splitting a single variable,
        % the cell array contains names for that one specific variable.
        if ~isscalar(varsToSplitInds)
            newvarnames = splitVarNames{i};
        else
            newvarnames = splitVarNames;
        end
    end
    % Insert the new split variable, with the new names.
    growingPains{i+1} = addvars(growingPains{i},newvars{:},'Before',newInds(i),'NewVariableNames',newvarnames);
    if isa(var,'tabular')
        % Move per-variable metadata from the original nested table var
        % into the newly split vars in b. If var has row labels, account
        % for them in the position of the newvarnames whose metadata are
        % being copied.
        
        toLocs = cell(1,numel(newvarnames) - var.rowDim.hasLabels);
        
        for x = 1:numel(toLocs)
            toLocs{x} = newvarnames{x+var.rowDim.hasLabels};
        end
        
        fromLocs = 1:var.varDim.length;
        
        growingPains{i+1}.varDim = growingPains{i+1}.varDim.moveProps(var.varDim, fromLocs,  growingPains{i+1}.varDim.subs2inds(toLocs));
    else % array
        % Move per-var metadata from the outer varsToSplit into the newly
        % split vars in b, replicating it to all the split vars.
        toLocs = growingPains{i+1}.varDim.subs2inds(newvarnames);
        fromLocs = repmat(varsToSplitInds(i),size(toLocs));
        
        growingPains{i+1}.varDim = growingPains{i+1}.varDim.moveProps(a.varDim, fromLocs, toLocs);
    end
    
    % update indices based on the width of the added split vars (note that
    % the unsplit variable counts as one, so subtract 1):
    newInds = newInds + length(newvars)-1;
end
bout = growingPains{end};
