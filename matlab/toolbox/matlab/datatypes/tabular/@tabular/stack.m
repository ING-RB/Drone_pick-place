function [b,ia] = stack(a,dataVars,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isText
import matlab.internal.datatypes.matricize
import matlab.internal.datatypes.throwInstead

pnames = {'ConstantVariables' 'NewDataVariableNames' 'IndexVariableName'};
dflts =  {                []                     []                  [] };

[constVars,tallVarNames,indicatorName,supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames,dflts,varargin{:});

% Row labels are not allowed as a data variable. They are always treated as a
% constant variable.
rowLabelsName = a.metaDim.labels(1);
if any(strcmp(rowLabelsName,dataVars))
    a.throwSubclassSpecificError('stack:CantStackRowLabels');
end

% if the user passes in a matrix for dataVars, flatten it to a vector
% (other vectors will remain the same)
dataVars = dataVars(:)';

% Convert dataVars or dataVars{:} to indices.  [] is valid, and does not
% indicate "default".
if isempty(dataVars)
    dataVars = {[]}; % guarantee a zero length list in a non-empty cell
elseif iscell(dataVars) && ~iscellstr(dataVars) %#ok<ISCLSTR>
    for i = 1:length(dataVars)
        dataVars{i} = a.varDim.subs2inds(dataVars{i}); % each cell containing a row vector
    end
elseif isa(dataVars,"pattern") && ~isscalar(dataVars) % pattern scalar flows through subs2inds in the else-branch
    dataVarsCopy = cell(size(dataVars));
    for i = 1:numel(dataVars)
        dataVarsCopy{i} = a.varDim.subs2inds(dataVars(i)); % each element containing a pattern
    end
    dataVars = dataVarsCopy;
else
    dataVars = { a.varDim.subs2inds(dataVars) }; % a cell containing a row vector
end
allDataVars = cell2mat(dataVars);
nTallVars = length(dataVars);

% Tabular arrays are not allowed as data variables.
for i = 1:length(allDataVars)
    if isa(a.data{allDataVars(i)},'tabular')
        error(message('MATLAB:table:stack:CantStackTabularVariable',a.varDim.labels{allDataVars(i)}));
    end
end

% Reconcile constVars and dataVars.  The two must have no variables in common.
% If only dataVars is provided, constVars defaults to "everything else".
if supplied.ConstantVariables
    % Convert constVars to indices.  [] is valid, and does not indicate "default".
    % Ignore empty row labels, they are always treated as a const var.
    constVars = a.getVarOrRowLabelIndices(constVars,true); % a row vector
    if ~isempty(intersect(constVars,allDataVars))
        error(message('MATLAB:table:stack:ConflictingConstAndDataVars'));
    end
    % If the specified constant vars include the input's row labels, i.e.
    % any(constVarIndicess==0), those will automatically be carried over as the
    % output's row labels, so clear those from constVarIndices.
    constVars(constVars==0) = [];
else
    constVars = setdiff(1:size(a,2),allDataVars);
end
nConstVars = length(constVars);
constVarNames = a.varDim.labels(constVars);

% Make sure all the sets of variables are the same width.
m = unique(cellfun(@numel,dataVars));
if ~isscalar(m)
    error(message('MATLAB:table:stack:UnequalSizeDataVarsSets'));
end

% Replicate rows for each of the constant variables. This carries over
% properties of the wide table.
n = size(a,1);
ia = repmat(1:n,max(m,1),1); ia = ia(:);
b = a(ia,constVars);
b_varDim = b.varDim;

aNames = a.varDim.labels;

if m > 0
    % Add the indicator variable and preallocate room in the data array
    vars = dataVars{1}(:);
    if nTallVars == 1
        % Unique the data vars for the indicator categories.  This will create
        % the indicator variable with categories ordered by var location in the
        % original table, not by first occurrence in the data.
        uvars = unique(vars,'sorted');
        if any(matches(aNames(vars),["<missing>" "<undefined>"]))
            error(message('MATLAB:table:stack:UndefOrMissingString'))
        end
        indicator = categorical(repmat(vars,n,1),uvars,aNames(uvars));
    else
        indicator = repmat(vars,n,1);
    end
    b_varDim = b_varDim.createLike(nConstVars + 1 + nTallVars);
    b_varDim = b_varDim.setLabels(constVarNames,1:nConstVars); % fill the remaining names in later
    indicatorVarIdx = nConstVars + 1;
    b.data{indicatorVarIdx} = indicator;
    b.data{b_varDim.length} = [];
    
    % For each group of wide variables to reshape ...
    for i = 1:nTallVars
        vars = dataVars{i}(:);
        
        % Interleave the group of wide variables into a single tall variable
        if ~isempty(vars)
            szOut = size(a.data{vars(1)}); szOut(1) = b.rowDim.length;
            tallVar = a.data{vars(1)}(ia,:);
            for j = 2:m
                interleaveIdx = j:m:m*n;
                try
                    tallVar(interleaveIdx,:) = matricize(a.data{vars(j)});
                catch ME
                    msg = message('MATLAB:table:stack:InterleavingDataVarsFailed',a.varDim.labels{vars(j)});
                    throw(addCause(MException(msg.Identifier,'%s',getString(msg)), ME));
                end
            end
            b.data{indicatorVarIdx+i} = reshape(tallVar,szOut);
        end
    end
    
    % Generate default names for the stacked data var(s) if needed, avoiding conflicts
    % with existing var or dim names. If NewDataVariableName was given, duplicate names
    % are an error, caught by setLabels here or by checkAgainstVarLabels below.
    if ~supplied.NewDataVariableNames
        % These will always be valid, no need to call makeValidName
        tallVarNames = cellfun(@(c)join(aNames(c),'_'),dataVars);
        avoidNames = [b_varDim.labels b.metaDim.labels];
        tallVarNames = matlab.lang.makeUniqueStrings(tallVarNames,avoidNames,namelengthmax);
    end
    try
        b_varDim = b_varDim.setLabels(tallVarNames,(indicatorVarIdx+1):b_varDim.length); % error if invalid, duplicate, or empty
    catch me
        if length(string(tallVarNames)) ~= nTallVars
            % Number of tall var names supplied is different from the
            % number of unique values in the indicator variable
            error(message('MATLAB:table:stack:NewDataVarNameLengthMismatch',nTallVars));
        elseif isequal(me.identifier,'MATLAB:table:DuplicateVarNames') ...
                && length(unique(tallVarNames)) == length(tallVarNames)
        % The tall var names must have been supplied, not the defaults. Give
        % a more detailed err msg than the one from setLabels if there's a
        % conflict with existing var names.
        if nTallVars == 1
            error(message('MATLAB:table:stack:ConflictingNewDataVarName',convertCharsToStrings(tallVarNames)));
        else
            error(message('MATLAB:table:stack:ConflictingNewDataVarNames'));
        end
        else
            % Duplicates within tallVarNames would be rethrown here
            rethrow(me);
        end
    end
    
    % Now that the data var names are OK, we can generate a default name
    % for the indicator var if needed, avoiding a conflict with existing
    % var or dim names. If IndexVariableName was given, a duplicate name is
    % an error, caught by setLabels here or by checkAgainstVarLabels below.
    if ~supplied.IndexVariableName
        % This will always be valid, no need to call makeValidName
        if nTallVars == 1
            indicatorName = [b_varDim.labels{indicatorVarIdx+1} '_' getString(message('MATLAB:table:uistrings:DfltStackIndVarSuffix'))];
        else
            indicatorName = getString(message('MATLAB:table:uistrings:DfltStackIndVarSuffix'));
        end
        avoidNames = [b_varDim.labels b.metaDim.labels];
        indicatorName = matlab.lang.makeUniqueStrings(indicatorName,avoidNames,namelengthmax);
    end
    try
        b_varDim = b_varDim.setLabels(indicatorName,indicatorVarIdx); % error if invalid, duplicate, or empty
    catch me
        if isequal(me.identifier,'MATLAB:table:DuplicateVarNames')
            % The index var name must have been supplied, not the default.
            % Give a more detailed err msg than the one from setLabels if
            % there's a conflict with existing var names
            error(message('MATLAB:table:stack:ConflictingIndVarName',convertCharsToStrings(indicatorName)));
        else
            % Give a more detailed err msg than the one from setLabels if
            % exactly one name was not supplied or if the supplied name was
            % invalid.
            throwInstead(me, {'MATLAB:table:IncorrectNumberOfVarNamesPartial','MATLAB:table:InvalidVarNames'}, ...
                'MATLAB:table:stack:ScalarIndexName');
        end
    end
else
    if supplied.NewDataVariableNames && ~isempty(tallVarNames)
        error(message('MATLAB:table:stack:NewDataVarNamesEmptyDataVars'));
    end
    if supplied.IndexVariableName && ~isempty(indicatorName)
        error(message('MATLAB:table:stack:IndexVarNameEmptyDataVars'));
    end
end

% Detect conflicts between the stacked var names (which may have been given by
% NewDataVariableName or IndexVariableName) and the original dim names.
b.metaDim = b.metaDim.checkAgainstVarLabels(b_varDim.labels);

% Copy per-var properties from constant vars and the first data var in each group
if m > 0
    firstDataVars = cellfun(@(x) x(1),dataVars(:)');
    b_varDim = b_varDim.moveProps(a.varDim,[constVars firstDataVars],[1:nConstVars nConstVars+1+(1:nTallVars)]);
else
    b_varDim = b_varDim.moveProps(a.varDim,constVars,1:nConstVars);
end
if b_varDim.hasDescrs
    newDescrs = b_varDim.descrs;
    if m > 0 % in case no indicator variable
        newDescrs{indicatorVarIdx} = getString(message('MATLAB:table:uistrings:StackIndVarDescr'));
    end
    b_varDim = b_varDim.setDescrs(newDescrs);
end
b.varDim = b_varDim;
