function t2 = rows2vars(t1,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.

pnames = {'VariableNamesSource' 'DataVariables' 'VariableNamingRule'};
dflts =  {                   []             ':'             'modify'};
[varNamesSource,dataVars,variableNamingRule,supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames,dflts,varargin{:});

% If t1's dim names were the defaults, don't do anything special for t2's dim
% names. But if either of t1's dim names are set to non-default, use them in the
% opposite position for t2's dim names.
%dimNames = t1.metaDim.labels([2 1]); % probably a bad choice
dfltDimNames = table.defaultDimNames;
dimNames = dfltDimNames;
nonDfltDimNames = ~matches(dfltDimNames,t1.metaDim.labels);
if nonDfltDimNames(1)
    dimNames{2} = t1.metaDim.labels{1}; % t1's rows dim name as t2's vars dim name
end
if nonDfltDimNames(2)
    dimNames{1} = t1.metaDim.labels{2}; % t1's vars dim name as t2's rows dim name
end
% If VariableNamesSource is provided, we may use one of t1's var names for t2's
% vars dim name, below.

% Get dataVars first
if supplied.DataVariables
    varIndices = t1.varDim.subs2inds(dataVars); 
else
    varIndices = 1:t1.varDim.length;
end

% Ensure that VariableNamingRule has the appropriate value.
variableNamingRule = validatestring(variableNamingRule,{'modify','preserve'},'rows2vars','VariableNamingRule'); 

if supplied.VariableNamesSource % get t2's var names from one of t1's vars
    if isa(varNamesSource,"pattern")
        error(message('MATLAB:table:rows2vars:InvalidNewVarNamesSpec'));
    end

    % Remove the var in t1 to use as var names in t2
    try
        asVarNames = t1.getVarOrRowLabelIndices(varNamesSource);
    catch ME
        matlab.internal.datatypes.throwInstead(ME,'MATLAB:table:InvalidVarName','MATLAB:table:rows2vars:InvalidNewVarNamesSpec')
    end
    if ~isscalar(asVarNames)
        error(message('MATLAB:table:rows2vars:InvalidNewVarNamesSpec'))
    end
    varNames = t1.getVarOrRowLabelData(asVarNames);
    varNames = varNames{1};
    if ~supplied.DataVariables
        % Given a variable for VariableNamesSource but DataVariables not
        % specified, use setdiff to get the data variables.
        varIndices = setdiff(varIndices,asVarNames);
    elseif any(asVarNames==varIndices)
        % DataVariables must not include the VariableNameSource
        error(message('MATLAB:table:rows2vars:DataVarsIncludeVarNames'));
    end
    if asVarNames > 0
        % New var names in t2 come from a var in t1. Use t1's var name as t2's
        % vars dim name.
        dimNames{2} = t1.varDim.labels{asVarNames};
    end
elseif ~isempty(t1.rowDim.labels) % get t2's var names from t1's row labels
    varNames = t1.rowDim.labels;
else % construct default var names for t2
    varNames = matlab.internal.tabular.private.varNamesDim.dfltLabels(1:t1.rowDim.length);
end

% Check if any variables are tabular, in order to throw a better error.
for ii=varIndices
    if isa(t1.data{ii},'tabular')
        % if nested tables, throw better error
        error(message('MATLAB:table:rows2vars:CannotTransposeTableInTable'))
    end
    sz = size(t1.data{ii});
    if any(sz(2:end) > 1) % check for multi-column/ND vars
        error(message('MATLAB:table:rows2vars:CannotTransposeMulticolumnVar'))
    elseif any(sz(2:end) < 1) % check for multi-column/ND vars
        error(message('MATLAB:table:rows2vars:CannotTransposeNoColumnVar'))
    end
end

try
    % Let braces create a homogeneous array if it can
    a = t1{:,varIndices};
catch ME
    if matches(ME.identifier, ["MATLAB:table:ExtractDataIncompatibleTypeError" "MATLAB:table:ExtractDataCatError"])
        % If braces can't, just create a cell array
        a = table2cell(t1(:,varIndices));
    else
        rethrow(ME)
    end
end

% Split up the transposed data into vars, one per column
[nvars,nrows] = size(a);
vars = mat2cell(a.',nrows,ones(1,nvars));

% Convert the (possibly) non-text source in t1 into t2's text var names. The
% source might be one of t1's vars, which can be _anything_, or its row
% labels, which might already be text (if a table), or might be times (if a
% timetable). string is the most likely way to convert non-text into text.
try
    varNames = string(varNames);
catch ME % No string conversion
    m = message('MATLAB:table:rows2vars:InvalidNewVarNames');
    throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
end
if numel(varNames) ~= nvars % might have more than one column
    error(message('MATLAB:table:rows2vars:IncorrectNumVarNames'))
end

% Add t1's var names as a var in t2, with a special name. Do before cleaning up
% missing var names to get the default name numbering right.
vars = [{t1.varDim.labels(varIndices)'}, vars];
varNames = [string(getString(message('MATLAB:table:uistrings:Rows2varsNewVarName'))), varNames(:)'];

% Might have missing strings if var names came from a non-text source.
missingVarNames = ismissing(varNames);
varNames(missingVarNames) = t1.varDim.dfltLabels(find(missingVarNames));
varNames = cellstr(varNames);

if variableNamingRule == "preserve"
    % Call makeValidName to handle long names and names conflicting with reserved names.
    varNames = t1.varDim.makeValidName(varNames,'resolveConflict');
else
    % First convert to valid identifiers and then call makeUniqueStrings to ensure
    % that the conversion does not introduce any new duplicates or >namelenghtmax names
    
    % Display the warning only if VariableNamingRule was not specified
    if ~supplied.VariableNamingRule
        varNames = t1.varDim.makeValidName(varNames,'warnRows2Vars');
    else
        varNames = t1.varDim.makeValidName(varNames,'silent');
    end
end
varNames = matlab.lang.makeUniqueStrings(varNames,dimNames,namelengthmax);

nvars = nvars + 1;

% Update nrows based on number of varNames, in case t1 was empty.
nrows = size(vars{1},1);
rowNames = {};

t2 = table.init(vars,nrows,rowNames,nvars,varNames,dimNames);
