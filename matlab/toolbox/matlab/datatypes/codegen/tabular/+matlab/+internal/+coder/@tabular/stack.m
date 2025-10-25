function [b,ia] = stack(a,dataVarsIn,varargin) %#codegen
%STACK Stack up data from multiple variables into a single variable

%   Copyright 2020 The MathWorks, Inc.

% Each function declared extrinsic below is in one of the following categories.
% - The coder implementation is always evaluated at runtime even when the
%   inputs are constant (e.g. unique), but the function is only called with
%   constant inputs in this file.
% - There is no coder implementation for cell array inputs (e.g. horzcat), but
%   the function is always called with constant inputs in this file.
% - There is no coder implementation, but the function is only called with
%   constant inputs in this file (e.g. namelengthmax).
%
% In each case, the outputs are always constant, so an extrinsic call wrapped
% in coder.const is always valid.
coder.extrinsic( ...
    'cell2mat', ...
    'cellfun', ...
    'cellstr', ...
    'getString', ...
    'horzcat', ...
    'intersect', ...
    'join', ...
    'matches', ...
    'matlab.internal.datatypes.isScalarText', ...
    'matlab.internal.datatypes.isText', ...
    'matlab.internal.i18n.locale', ...
    'matlab.lang.makeUniqueStrings', ...
    'message', ...
    'namelengthmax', ...
    'setdiff', ...
    'unique' ...
);

narginchk(2,Inf);
coder.internal.assert(coder.internal.isConst(dataVarsIn),'MATLAB:table:stack:NonConstantDataVars');

pnames = {'ConstantVariables' 'NewDataVariableNames' 'IndexVariableName'};
poptions = struct('CaseSensitivity', false, ...
                  'PartialMatching', 'unique', ...
                  'StructExpand',    false);
supplied = coder.internal.parseParameterInputs(pnames, poptions, varargin{:});

constantVariables         =  coder.internal.getParameterValue(supplied.ConstantVariables,    [], varargin{:});
newDataVariableNamesInput =  coder.internal.getParameterValue(supplied.NewDataVariableNames, [], varargin{:});
indexVariableName         =  coder.internal.getParameterValue(supplied.IndexVariableName,    [], varargin{:});

coder.internal.assert(coder.internal.isConst(constantVariables),'MATLAB:table:stack:NonConstantArg');
coder.internal.assert(coder.internal.isConst(newDataVariableNamesInput),'MATLAB:table:stack:NonConstantArg');
coder.internal.assert(coder.internal.isConst(indexVariableName),'MATLAB:table:stack:NonConstantArg');

% Some error checking on NewDataVariableNames. In MATLAB, this is done
% within varDim.setLabels. In codegen, since we don't call setLabels, have
% to check for errors explicitly
if isstring(newDataVariableNamesInput)
    newDataVariableNames = coder.const(cellstr(newDataVariableNamesInput));
elseif isempty(newDataVariableNamesInput) && (isa(newDataVariableNamesInput,'double') || isa(newDataVariableNamesInput,'char'))
    newDataVariableNames = {};
elseif ischar(newDataVariableNamesInput) && coder.const(matlab.internal.datatypes.isScalarText(newDataVariableNamesInput))
    newDataVariableNames = {newDataVariableNamesInput};
else
    newDataVariableNames = newDataVariableNamesInput;
end
coder.internal.assert(coder.const(matlab.internal.datatypes.isText(newDataVariableNames,true)),...
    'MATLAB:table:InvalidVarNames');  % only allow nonempty string scalar or cellstr

% Row labels are not allowed as a data variable. They are always treated as a
% constant variable.
rowLabelsName = a.metaDim.labels{1};
a.throwSubclassSpecificErrorIf(any(strcmp(rowLabelsName,dataVarsIn)),'stack:CantStackRowLabels');

% Convert dataVars or dataVars{:} to indices.  [] is valid, and does not
% indicate "default".
if isempty(dataVarsIn)
    dataVars = {[]}; % guarantee a zero length list in a non-empty cell
    allDataVars = [];
elseif iscell(dataVarsIn) && ~iscellstr(dataVarsIn) %#ok<ISCLSTR>
    dataVars = cell(1,numel(dataVarsIn));
    for i = 1:length(dataVars)
        dataVars{i} = a.varDim.subs2inds(dataVarsIn{i}); % each cell containing a row vector
    end
    dataVars = coder.const(dataVars);
    allDataVars = coder.const(cell2mat(dataVars));
else
    % subs2inds always returns a constant value
    dataVars = { a.varDim.subs2inds(dataVarsIn) }; % a cell containing a row vector
    allDataVars = coder.const(cell2mat(dataVars));
end
nTallVars = length(dataVars);

% Tabular arrays are not allowed as data variables.
for i = 1:length(allDataVars)
    coder.internal.errorIf(isa(a.data{allDataVars(i)},'tabular'),'MATLAB:table:stack:CantStackTabularVariable',a.varDim.labels{allDataVars(i)});
end

% Reconcile constVars and dataVars.  The two must have no variables in common.
% If only dataVars is provided, constVars defaults to "everything else".
if supplied.ConstantVariables
    % Convert constVars to indices.  [] is valid, and does not indicate "default".
    % Ignore empty row labels, they are always treated as a const var.
    constVars = coder.const(a.getVarOrRowLabelIndices(constantVariables,true)); % a row vector
    coder.internal.assert(isempty(coder.const(intersect(constVars,allDataVars))),'MATLAB:table:stack:ConflictingConstAndDataVars');
    % If the specified constant vars include the input's row labels, i.e.
    % any(constVarIndicess==0), those will automatically be carried over as the
    % output's row labels, so clear those from constVarIndices.
    if ~isempty(constVars)
        constVars = constVars(constVars~=0);
    else
        constVars = [];
    end
else
    constVars = coder.const(setdiff(1:size(a,2),allDataVars));
end
nConstVars = length(constVars);
constVarNames = cell(1,nConstVars);
for i = 1:nConstVars
    constVarNames{i} = a.varDim.labels{constVars(i)};
end
constVarNames = coder.const(constVarNames);

% Make sure all the sets of variables are the same width.
m = coder.const(unique(coder.const(cellfun('prodofsize',dataVars))));
coder.internal.assert(isscalar(m),'MATLAB:table:stack:UnequalSizeDataVarsSets');

% Replicate rows for each of the constant variables. This carries over
% properties of the wide table.
n = size(a,1);
ia = repmat(1:n,max(m,1),1); ia = ia(:);

aNames = a.varDim.labels;

if m <= 0
    b = a.parenReference(ia,constVars); % a(ia,constVars);
    b_varDim = b.varDim;
    coder.internal.errorIf(supplied.NewDataVariableNames && ~isempty(newDataVariableNames),'MATLAB:table:stack:NewDataVarNamesEmptyDataVars');
    coder.internal.errorIf(supplied.IndexVariableName && ~isempty(indexVariableName),'MATLAB:table:stack:IndexVarNameEmptyDataVars');
else
    % Add the indicator variable and preallocate room in the data array
    vars = dataVars{1}(:);
    if nTallVars == 1
        % Unique the data vars for the indicator categories.  This will create
        % the indicator variable with categories ordered by var location in the
        % original table, not by first occurrence in the data.
        uvars = coder.const(unique(vars,'sorted'));
        coder.internal.errorIf(any(coder.const(matches(subsrefParens(aNames,{vars}),{'<missing>' '<undefined>'}))),'MATLAB:table:stack:UndefOrMissingString');
        indicator = categorical(repmat(vars,n,1),uvars,coder.const(subsrefParens(aNames,{uvars})));
    else
        indicator = repmat(vars,n,1);
    end
    b_tmp = a.parenReference(ia,constVars);
    b_varDim_labels_first = coder.const(cellstr(constVarNames)); % fill the remaining names in later
    
    % Preallocate b
    b_varDim_length = nConstVars + 1 + nTallVars;
    indicatorVarIdx = nConstVars + 1;
    b = a.cloneAsEmpty();
    b.data = cell(1,b_varDim_length);
    
    % Copy the indicator variable into b
    b.data{indicatorVarIdx} = indicator;
    
    % Copy constant variables from b_tmp to b
    for i = 1:nConstVars
        b.data{i} = b_tmp.data{i};
    end
    
    % Initialize b's metadata
    b.rowDim = b_tmp.rowDim;
    b.metaDim = b_tmp.metaDim;
    b.arrayProps = b_tmp.arrayProps;
    
    % For each group of wide variables to reshape ...
    for i = 1:nTallVars
        vars = dataVars{i}(:);

        % Interleave the group of wide variables into a single tall variable
        if ~isempty(vars)
            szOut = size(a.data{vars(1)}); szOut(1) = b.rowDim.length;
            tallVarSize = size(a.data{vars(1)});
            tallVarSize(1) = length(ia);
            if iscell(a.data{vars(1)})
                tallVar = cell(tallVarSize);
                for idx = 1:length(ia)
                    for j = 1:prod(tallVarSize(2:end))
                        tallVar{idx,j} = a.data{vars(1)}{ia(idx),j};
                    end
                end
            else
                tallVar = a.data{vars(1)}(ia,:);
            end
            for j = 2:m
                interleaveIdx = j:m:m*n;
                if ~iscell(tallVar)
                    if ~isempty(interleaveIdx)
                    tallVar(interleaveIdx,:) = matlab.internal.coder.datatypes.matricize(a.data{vars(j)});
                else
                        % This code path is a special case for stacking sized empty variables (e.g.
                        % stack(table(zeros(0,1),[]),[1 2]) ). A separate branch is needed because
                        % coder is more strict than MATLAB in requiring that sized empty arrays
                        % have compatible dimensions for subscripted assignment.
                        % 
                        % We cannot ignore the assignment, because the subscripted assignment may
                        % error or have other side effects such as changing metadata of the target
                        % array.
                        tallVar(interleaveIdx,:) = reshape(a.data{vars(j)},size(tallVar(interleaveIdx,:)));
                    end
                else
                    tmp = matlab.internal.coder.datatypes.matricize(a.data{vars(j)});
                    szTmp = size(tmp);
                    coder.internal.errorIf(iscell(tallVar) && ~iscell(a.data{vars(j)}),'MATLAB:table:stack:InterleavingDataVarsFailed',a.varDim.labels{j});
                    for ii = 1:length(interleaveIdx)
                        for jj = 1:prod(szTmp(2:end))
                            tallVar{interleaveIdx(ii),jj} = tmp{ii,jj};
                        end
                    end
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
        tallVarNamesTmp = cell(1,length(dataVars));
        for i = 1:length(tallVarNamesTmp)
            tmp = coder.const(join(coder.const(subsrefParens(aNames,{dataVars{i}})),'_'));
            tallVarNamesTmp{i} = tmp{1};
        end
        avoidNames = coder.const([b_varDim_labels_first,b_tmp.metaDim.labels]);
        tallVarNames = coder.const(matlab.lang.makeUniqueStrings(coder.const(tallVarNamesTmp),avoidNames,coder.const(namelengthmax)));
    else
        tallVarNames = newDataVariableNames;
        % The isempty checks are necessary in case tallVarNames is an empty double,
        % since the matches function will error on non-text inputs.
        if ~isempty(tallVarNames)
            coder.internal.errorIf(~isempty(tallVarNames) && nTallVars == 1 && any(coder.const(matches(tallVarNames,b_varDim_labels_first))),'MATLAB:table:stack:ConflictingNewDataVarName',tallVarNames{1});
            coder.internal.errorIf(~isempty(tallVarNames) && any(coder.const(matches(tallVarNames,b_varDim_labels_first))),'MATLAB:table:stack:ConflictingNewDataVarNames');
        end
    end
    if isa(tallVarNames,'double') && isempty(tallVarNames)
        length_tallVarNames = 0;
    else
        length_tallVarNames = coder.const(length(coder.const(cellstr(tallVarNames))));
    end
    coder.internal.assert(length_tallVarNames == nTallVars,'MATLAB:table:stack:NewDataVarNameLengthMismatch',nTallVars);
    b_varDim_labels_last = coder.const(cellstr(tallVarNames));
    
    % Now that the data var names are OK, we can generate a default name
    % for the indicator var if needed, avoiding a conflict with existing
    % var or dim names. If IndexVariableName was given, a duplicate name is
    % an error, caught by setLabels here or by checkAgainstVarLabels below.
    b_varDim_labels_so_far = coder.const([b_varDim_labels_first,b_varDim_labels_last]);
    if ~supplied.IndexVariableName
        % This will always be valid, no need to call makeValidName
        str = coder.const(getString(message('MATLAB:table:uistrings:DfltStackIndVarSuffix'),matlab.internal.i18n.locale('en_US')));
        if nTallVars == 1
            tallVarNamesTmp = coder.const(cellstr(tallVarNames));
            indicatorNameTmp = coder.const([tallVarNamesTmp{1},'_',str]);
        else
            indicatorNameTmp = str;
        end
        avoidNames = coder.const([b_varDim_labels_so_far,b_tmp.metaDim.labels]);
        indicatorName = coder.const(matlab.lang.makeUniqueStrings(indicatorNameTmp,avoidNames,coder.const(namelengthmax)));
    else
        rawIndicatorName = convertStringsToChars(indexVariableName);
        % Just check that only a single name was supplied. Do not need to check
        % for missing or '' since that would be caught by varDim.createLike
        % below.
        coder.internal.assert(coder.const(matlab.internal.datatypes.isScalarText(rawIndicatorName)) || ...
            coder.const(matlab.internal.datatypes.isText(rawIndicatorName)) && coder.const(isscalar(rawIndicatorName)), 'MATLAB:table:stack:ScalarIndexName');
        coder.internal.errorIf(coder.const(matches(rawIndicatorName,b_varDim_labels_so_far)),'MATLAB:table:stack:ConflictingIndVarName',rawIndicatorName);
        
        if ischar(rawIndicatorName)
            % Convert chars to cellstr
            indicatorName = {rawIndicatorName};
        else
            indicatorName = rawIndicatorName;
        end
    end
    b_varDim_labels = coder.const([b_varDim_labels_first,indicatorName,b_varDim_labels_last]);
    b_varDim = b_tmp.varDim.createLike(b_varDim_length,b_varDim_labels);
end

% Detect conflicts between the stacked var names (which may have been given by
% NewDataVariableName or IndexVariableName) and the original dim names.
b.metaDim = b.metaDim.checkAgainstVarLabels(b_varDim.labels);

% Copy per-var properties from constant vars and the first data var in each group
if m > 0
    firstDataVars = zeros(1,numel(dataVars));
    for i = coder.unroll(1:length(firstDataVars))
        firstDataVars(i) = coder.const(dataVars{i}(1));
    end
    b_varDim = b_varDim.moveProps(a.varDim,coder.const([constVars,coder.const(firstDataVars)]),coder.const([1:nConstVars,nConstVars+1+(1:nTallVars)]));
else
    b_varDim = b_varDim.moveProps(a.varDim,constVars,coder.const(1:nConstVars));
end
if b_varDim.hasDescrs
    newDescrs = b_varDim.descrs;
    if m > 0 % in case no indicator variable
        newDescrs{indicatorVarIdx} = coder.const(getString(message('MATLAB:table:uistrings:StackIndVarDescr'),matlab.internal.i18n.locale('en_US')));
    end
    b_varDim = b_varDim.setDescrs(newDescrs);
end
b.varDim = b_varDim;
end

function C = subsrefParens(A,subs)
    coder.inline('always');
    coder.extrinsic('subsref','substruct');
    C = subsref(A,substruct('()',subs));
end
