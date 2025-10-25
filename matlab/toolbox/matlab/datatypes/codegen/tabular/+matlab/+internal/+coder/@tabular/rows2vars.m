function t2 = rows2vars(t1,varargin)  %#codegen
%ROWS2VARS Reorient rows of table or timetable to be variables of output table.

%   Copyright 2020 The MathWorks, Inc.
coder.extrinsic('matches', 'getString', 'message', 'matlab.internal.i18n.locale', ...
    'matlab.lang.makeUniqueStrings', 'namelengthmax', 'horzcat');

% Input table cannot be variable sized
coder.internal.assert(coder.internal.isConst(size(t1, 1)), 'MATLAB:table:rows2vars:VarsizeTable');

pnames = {'VariableNamesSource' 'DataVariables' 'VariableNamingRule'};
poptions = struct('CaseSensitivity', false, 'PartialMatching', 'unique', ...
    'StructExpand', false);
pstruct = coder.internal.parseParameterInputs(pnames, poptions, varargin{:});
% VariableNamesSource is not supported in codegen
coder.internal.assert(pstruct.VariableNamesSource==0, ...
    'MATLAB:table:rows2vars:UnsupportedVarNamesSource');

dataVars = coder.internal.getParameterValue(pstruct.DataVariables, ':', varargin{:});
variableNamingRule = coder.internal.getParameterValue(pstruct.VariableNamingRule, ...
    'modify', varargin{:});   
% DataVariables and VariableNamingRule must be constant
coder.internal.assert(coder.internal.isConst(dataVars), 'MATLAB:table:rows2vars:NonconstantDataVars');
coder.internal.assert(coder.internal.isConst(variableNamingRule), 'MATLAB:table:rows2vars:NonconstantNamingRule');

% If t1's dim names were the defaults, don't do anything special for t2's dim
% names. But if either of t1's dim names are set to non-default, use them in the
% opposite position for t2's dim names.
%dimNames = t1.metaDim.labels([2 1]); % probably a bad choice
dfltDimNames = table.defaultDimNames;
dimNames = cell(1,2);
nonDfltDimNames = ~coder.const(matches(dfltDimNames,t1.metaDim.labels));
if nonDfltDimNames(1)
    dimNames{2} = t1.metaDim.labels{1}; % t1's rows dim name as t2's vars dim name
else
    dimNames{2} = dfltDimNames{2};
end
if nonDfltDimNames(2)
    dimNames{1} = t1.metaDim.labels{2}; % t1's vars dim name as t2's rows dim name
else
    dimNames{1} = dfltDimNames{1};
end

% Get dataVars first
if pstruct.DataVariables
    varIndices = t1.varDim.subs2inds(dataVars);
else
    varIndices = 1:t1.varDim.length;
end

% Ensure that VariableNamingRule has the appropriate value.
variableNamingRule = validatestring(variableNamingRule,{'modify','preserve'},'rows2vars','VariableNamingRule'); 

if ~isempty(t1.rowDim.labels) % get t2's var names from t1's row labels
    varNamesBeforePrepend = t1.rowDim.labels;
    coder.internal.assert(coder.internal.isConst(varNamesBeforePrepend), ...
        'MATLAB:table:rows2vars:NonconstantRowNames');
else % construct default var names for t2
    varNamesBeforePrepend = matlab.internal.coder.tabular.private.varNamesDim.dfltLabels(1:rowDimLength(t1));
end

% Check if any variables are tabular, in order to throw a better error.
coder.unroll(~coder.internal.isHomogeneousCell(t1.data));
for ii=varIndices
    % if nested tables, throw better error
    coder.internal.errorIf(isa(t1.data{ii}, 'tabular'), 'MATLAB:table:rows2vars:CannotTransposeTableInTable');
    sz = size(t1.data{ii});
    % check for multi-column/ND vars
    coder.internal.errorIf(any(sz(2:end) > 1), 'MATLAB:table:rows2vars:CannotTransposeMulticolumnVar', ...
        'IfNotConst','Fail');   % also throw for nonconstant sz
    coder.internal.errorIf(any(sz(2:end) < 1), 'MATLAB:table:rows2vars:CannotTransposeNoColumnVar');
end

if matlab.internal.coder.datatypes.canCellValuesConcatenate(t1.data, varIndices, false)
    % TODO: somehow ':' is not working for some cases. Investigate.
    %a = t1.braceReference(':',varIndices);
    a = t1.braceReference(1:rowDimLength(t1),varIndices);
else  % table values cannot concatenate, return a cell array
    %a = table2cell(t1.parenReference(':',varIndices));
    a = table2cell(t1.parenReference(1:rowDimLength(t1),varIndices));
end

% Split up the transposed data into vars, one per column
% Add t1's var names as a var in t2, with a special name. 
[nvars,nrows] = size(a);
%vars = mat2cell(a',nrows,ones(1,nvars));
vars = coder.nullcopy(cell(1,nvars+1));
vars1 = cell(numel(varIndices),1);
coder.unroll();
for i = 1:numel(vars1)
    vars1{i} = t1.varDim.labels{varIndices(i)};
end
vars{1} = vars1;
if iscell(a)
    ahomogeneous = coder.internal.isHomogeneousCell(a);
    coder.unroll(); % vars is heterogeneous in most cases, always unroll
    for i = 1:nvars
        col = cell(nrows,1);
        coder.unroll(~ahomogeneous);
        for j = 1:nrows
            col{j} = a{i,j};
        end
        vars{i+1} = col;
    end
else
    a = a.';
    coder.unroll(); % vars is always heterogeneous, always unroll
    for i = 1:nvars
        vars{i+1} = a(:,i);
    end
end

coder.internal.assert(numel(varNamesBeforePrepend) == nvars, 'MATLAB:table:rows2vars:IncorrectNumVarNames');

% Add t1's var names as a var in t2, with a special name. Do before cleaning up
% missing var names to get the default name numbering right.
varName1 = coder.const(getString(message('MATLAB:table:uistrings:Rows2varsNewVarName'),...
    matlab.internal.i18n.locale('en_US')));
varNamesBeforePrepend = coder.const(reshape(varNamesBeforePrepend,1,[]));  % reshape to row vector
varNames = coder.const([varName1 varNamesBeforePrepend]);  % extrinsic horzcat

if variableNamingRule == "preserve"
    % Call makeValidName to handle long names and names conflicting with reserved names.
    varNames = t1.varDim.makeValidName(varNames,'resolveConflict');
else
    % First convert to valid identifiers and then call makeUniqueStrings to ensure
    % that the conversion does not introduce any new duplicates or >namelenghtmax names
    
    % Display the warning only if VariableNamingRule was not specified
    if pstruct.VariableNamingRule == 0
        varNames = t1.varDim.makeValidName(varNames,'warnRows2Vars');
    else
        varNames = t1.varDim.makeValidName(varNames,'silent');
    end
end

varNames = coder.const(matlab.lang.makeUniqueStrings(coder.const(varNames),...
    coder.const(dimNames),coder.const(namelengthmax)));

nvars = nvars + 1;

% Update nrows based on number of varNames, in case t1 was empty.
nrows = size(vars{1},1);
rowNames = {};

t2 = table.init(vars,nrows,rowNames,nvars,varNames,dimNames);
