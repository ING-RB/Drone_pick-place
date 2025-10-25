function [leftKeys,rightKeys,leftVars,rightVars,outerType,outerMergeKeys] = ...
    joinGetKeyVars(joinType,adaptorA,adaptorB,varargin)
% joinGetKeyVars Parse join, innerjoin, and outerjoin key variable indices.
% Minimally duplicate the logic from in-memory join to extract the indices
% for 'LeftKeys', 'RightKeys', 'LeftVariables', and 'RightVariables'. We do
% not have access to table internals (like T.getVarOrRowLabelIndices,
% T.varDim.labels, or T.rowDim.hasLabels), so rely on the adaptors instead.

%   Copyright 2018-2019 The MathWorks, Inc.

% Same parseArgs call as in table join, innerjoin, and outerjoin.
outerType = ''; % Needed only for outerjoin: 'full', 'left', or 'right'.
outerMergeKeys = []; % Needed only for outerjoin: false or true.
if isequal(joinType,'innerjoin')
    pnames = {'Keys' 'LeftKeys' 'RightKeys' 'LeftVariables' 'RightVariables'};
    dflts =  {   []         []          []              []               [] };
    [keys,leftKeys,rightKeys,~,~,supplied] ...
        = matlab.internal.datatypes.parseArgs(pnames,dflts,varargin{:});
elseif isequal(joinType,'outerjoin')
    pnames = {'Type' 'Keys' 'LeftKeys' 'RightKeys' 'MergeKeys' 'LeftVariables' 'RightVariables'};
    dflts =  {'full'    []         []          []       false              []               [] };
    [outerType,keys,leftKeys,rightKeys,outerMergeKeys,~,~,supplied] ...
        = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
    outerMergeKeys = matlab.internal.datatypes.validateLogical(outerMergeKeys,'MergeKeys');
else
    pnames = {'Keys' 'LeftKeys' 'RightKeys' 'LeftVariables' 'RightVariables' 'KeepOneCopy'};
    dflts =  {   []         []          []              []               []            {} };
    [keys,leftKeys,rightKeys,~,~,~,supplied] ...
        = matlab.internal.datatypes.parseArgs(pnames,dflts,varargin{:});
end

% Same keys branching as in joinUtil, BUT with adaptors and without error
% messages (because we error before we get here -- in joinNamedTables).
clsA = adaptorA.Class;
clsB = adaptorB.Class;
if supplied.Keys
    if isequal(keys,'RowNames') && isequal(joinType,'join') && ...
            strcmp(clsA,'table') && strcmp(clsB,'table')
        leftKeys = 0;
        rightKeys = 0;
    else
        leftKeys = iGetVarOrRowLabelIndices(adaptorA,keys);
        rightKeys = iGetVarOrRowLabelIndices(adaptorB,keys);
    end
else
    if ~supplied.LeftKeys && ~supplied.RightKeys
        if strcmp(clsA,'timetable') && strcmp(clsB,'timetable')
            leftKeys = 0;
            rightKeys = 0;
        else
            [leftKeys,rightKeys] = ismember(getVariableNames(adaptorA),...
                                            getVariableNames(adaptorB));
            leftKeys = find(leftKeys);
            rightKeys = rightKeys(rightKeys>0);
        end
    else
        leftKeys = iGetVarOrRowLabelIndices(adaptorA,leftKeys);
        rightKeys = iGetVarOrRowLabelIndices(adaptorB,rightKeys);
    end
end

% No need for ~strcmpi(type,'simple') branch from inner and outer join to
% handle row labels because tall does not support row labels.

% Manually parsing the LeftVariables and RightVariables is too complicated.
% We do not want to duplicate the complex parsing logic in joinUtil.
% Instead, call join on empty in-memory tables.

% Empty tables with tagged VariableDescriptions: the table variables are
% tagged as {'A1' 'A2' ...} and {'B1' 'B2' ...}.
tagA = 'A';
tagB = 'B';
emptyA = iEmptyTableWithTaggedVarNames(adaptorA,tagA);
emptyB = iEmptyTableWithTaggedVarNames(adaptorB,tagB);

% JOIN keeps ONLY the LeftVariables and RightVariables as output variables.
% By default, the LeftVariables is all of A, including the left keys.
emptyC = feval(joinType,emptyA,emptyB,varargin{:});

% Extract LeftVariables and RightVariables by looking at how the tags
% propagated after the (inner)join call on the empty in-memory table.
descrC = emptyC.Properties.VariableDescriptions;
leftVarNames = descrC(startsWith(descrC,tagA));
rightVarNames = descrC(startsWith(descrC,tagB));
leftVars = str2double(extractAfter(leftVarNames,tagA));
rightVars = str2double(extractAfter(rightVarNames,tagB));
end

function emptyA = iEmptyTableWithTaggedVarNames(adaptorA,tagA)
% Create an empty in-memory skeleton table, keeping the same variable names
% AND tagging them through the VariableDescriptions.
varNames = getVariableNames(adaptorA);
z = cell(1,numel(varNames));
% To avoid artificially erroring for mismatched types for empty table
% variables when merging keys in outerjoin, just use empty durations for
% all (time)table variables.
[z{:}] = deal(duration.empty(0,1));
if isequal(adaptorA.Class,'timetable')
    emptyA = timetable(duration.empty(0,1),z{:},'VariableNames',varNames);
else
    emptyA = table(z{:},'VariableNames',varNames);
end
% Also carry over the variable name for time/rownames, because time is the
% default join key for timetables.
emptyA.Properties.DimensionNames = getDimensionNames(adaptorA);

varDescr = varNames;
for ii = 1:numel(varDescr)
    varDescr{ii} = [tagA, num2str(ii)];
end
emptyA.Properties.VariableDescriptions = varDescr;
end

function inds = iGetVarOrRowLabelIndices(adaptorT,varSubs)
% Tall adaptation of getVarOrRowLabelIndices from tabular. Returns the
% index of the row labels or Time as 0.

% String scalar gets converted to char, string array to cellstr.
varSubs = convertStringsToChars(varSubs);
if ischar(varSubs)
    varSubs = {reshape(varSubs,1,[])}; % Treat char name as scalar.
elseif islogical(varSubs)
    varSubs = find(varSubs);
end
n = numel(varSubs);

% Look for a variable name specifying the row names. Match in-memory join:
% the row name variable cannot be specified as a numeric index or logical.
rowNamesT = getDimensionNames(adaptorT);
rowNamesT = rowNamesT{1};
rowMask = false(1,n);
for ii = 1:n
    rowMask(ii) = strcmp(rowNamesT,varSubs(ii));
end
inds(rowMask) = 0;

% Look for table variables specified as names, numeric, or logical.
inds(~rowMask) = resolveVarNamesToIdxs(adaptorT,varSubs(~rowMask));
end