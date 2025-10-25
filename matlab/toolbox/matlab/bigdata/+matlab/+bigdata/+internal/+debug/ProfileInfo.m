%ProfileInfo
% Profile statistics collected during tall evaluation.
%
% This is a helper class around a callstats function table, with methods
% to manipulate the table as needed.

%   Copyright 2018-2019 The MathWorks, Inc.

classdef ProfileInfo
    properties (GetAccess = private, SetAccess = immutable)
        % Underlying function table statistics. This is held in a form most
        % optimal for the needed manipulations:
        %  - Has similar properties to callstats function table
        %  - Uses N x 3 array for Children property instead of a struct
        %  - Uses N x 2 array for Parents property instead of a struct
        FunctionTable (:,1) struct
    end
    
    methods (Static)
        function obj = fromStack(stack, timeTaken)
            % Build a ProfileInfo from a stack trace. This assumes the
            % entire profile is a single call through every line in the
            % stack trace that took timeTaken.
            functionTable = iBuildFunctionTableFromStack(stack, timeTaken);
            obj =  matlab.bigdata.internal.debug.ProfileInfo(functionTable);
        end
    end
    
    methods
        function obj = ProfileInfo(functionTable)
            % Construct a ProfileInfo from callstats function table
            
            % Internal methods construct ProfileInfo with the more optimal
            % storage format. We need to switch between this and the
            % callstats format passed in by external callers.
            if isstruct(functionTable(1).Children)
                for ii = 1:numel(functionTable)
                    functionTable(ii).Children = [zeros(0, 3); iQuickCell2Num(struct2cell(functionTable(ii).Children))'];
                    functionTable(ii).Parents = [zeros(0, 2); iQuickCell2Num(struct2cell(functionTable(ii).Parents))'];
                end
            end
            obj.FunctionTable = functionTable;
        end
        
        function out = combine(obj, other)
            % Combine two ProfileInfo objects into one. The output will
            % contain all statistics from both inputs.
            functionTable = iCombine(obj.FunctionTable, other.FunctionTable);
            out = matlab.bigdata.internal.debug.ProfileInfo(functionTable);
        end
        
        function out = removeCallersOfFunction(obj, functionName)
            % Remove all callers of a given function, leaving only the
            % given function name and anything called by it. This is used
            % to remove internal stack frames that call the code to be
            % profiled.
            functionTable = iRemoveCallersOfFunction(obj.FunctionTable, functionName);
            out = matlab.bigdata.internal.debug.ProfileInfo(functionTable);
        end
        
        function out = replaceFunction(obj, functionName, newStack)
            % Replace a function with the chain of functions provided by a
            % stack. This makes it look like the profiled code was called
            % directly by the deepest level function in the stack.
            functionTable = iReplaceFunction(obj.FunctionTable, functionName, newStack);
            out = matlab.bigdata.internal.debug.ProfileInfo(functionTable);
        end
        
        function out = removeFunctionsByBlacklist(obj, blacklist)
            % Remove functions in the collected results that match a given
            % blacklist. All children of blacklisted functions will be
            % re-parented to the parent of the blacklisted function.
            functionTable = iRemoveFunctionsByBlacklist(obj.FunctionTable, blacklist);
            out = matlab.bigdata.internal.debug.ProfileInfo(functionTable);
        end
        
        function s = asStruct(obj)
            % Convert this object back into a callstats info struct.
            ft = obj.FunctionTable;
            for ii = 1:numel(ft)
                ft(ii).Children = cell2struct(num2cell(ft(ii).Children)', {'Index', 'NumCalls', 'TotalTime'});
                ft(ii).Parents = cell2struct(num2cell(ft(ii).Parents)', {'Index', 'NumCalls'});
            end
            s.FunctionTable = ft;
            s.FunctionHistory = zeros(2, 0);
            [~, ~, s.ClockPrecision, ~, s.ClockSpeed] = callstats('stats');
            s.Name = 'Tall';
            s.Overhead = 0;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = iQuickCell2Num(x)
% Convert a cell array of double scalars into a numeric array.
x = reshape([x{:}], size(x));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ft = iRemoveCallersOfFunction(ft, functionName)
% Implementation of ProfileInfo/removeCallersOfFunction


allNames = {ft.FunctionName};
[~, replaceIdx] = ismember(functionName, allNames);
assert(replaceIdx ~= 0, ...
    "Assertion failed: Function %s is not in the profiling information.", functionName);

% Use a stack-based algorithm to figure out all children of functionName.
isSeen = false(size(ft));
stack = replaceIdx;
while ~isempty(stack)
    idx = stack(end);
    stack(end) = [];
    if isSeen(idx)
        continue;
    end
    isSeen(idx) = true;
    
    stack = [stack; ft(idx).Children(:, 1)]; %#ok<AGROW>
end

% Now remove all function table entries not seen in the above search. We
% need to remap all indices held by the properties of function table
% entries as well.
ft(~isSeen) = [];
oldToNewMap = cumsum(isSeen);
oldToNewMap(~isSeen) = 0;
for ii = 1:numel(ft)
    newIndices = oldToNewMap(ft(ii).Parents(:, 1));
    ft(ii).Parents(:, 1) = newIndices;
    ft(ii).Parents(newIndices == 0, :) = [];
    
    ft(ii).Children(:, 1) = oldToNewMap(ft(ii).Children(:, 1));
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ft = iReplaceFunction(ft, functionName, newStack)
% Implementation of ProfileInfo/replaceFunction

allNames = {ft.FunctionName};
[~, replaceIdx] = ismember(functionName, allNames);
assert(replaceIdx ~= 0, ...
    "Assertion failed: Function %s is not in the profiling information.", functionName);

% Build profile information representing the stack.
[newFtEntries, topStackIdx] = iBuildFunctionTableFromStack(newStack, ft(replaceIdx).TotalTime);

% The combine logic will merge two pieces of profile information, correctly
% handling overlap between the two. This exploits that by making the top
% level stack overlap with the input profile information.
ft(replaceIdx).CompleteName = newFtEntries(topStackIdx).CompleteName;
ft(replaceIdx).FunctionName = newFtEntries(topStackIdx).FunctionName;
ft(replaceIdx).FileName = newFtEntries(topStackIdx).FileName;
ft(replaceIdx).Parents = ft(replaceIdx).Parents([], :);
ft(replaceIdx).ExecutedLines = ft(replaceIdx).ExecutedLines([],:);
ft(replaceIdx).NumCalls = 0;
ft(replaceIdx).TotalTime = 0;
ft = iCombine(ft, newFtEntries);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ft = iRemoveFunctionsByBlacklist(ft, blacklist)
% Implementation of ProfileInfo/removeFunctionsByBlacklist

% First figure out which entries are to be dropped.
% Only remove names that contain one of the keywords in the blacklist and
% they are placed in an internal folder.
isBlacklisted = false(size(ft));
names = {ft.FunctionName}';
fileNames = {ft.FileName}';
isInternal = contains(fileNames, '+matlab') & contains(fileNames, '+internal');
for ii = 1:numel(blacklist)
    isBlacklisted = isBlacklisted ...
        | (isInternal & ~cellfun(@isempty, regexp(names, blacklist{ii}, "Once")));
end

% Now, for each function table entry, figure out the index of the closest
% non-blacklisted parent.
newIndex = (1:numel(ft))';
for ii = 1:numel(ft)
    if ~isBlacklisted(ii)
        continue;
    end
    assert(~numel(ft.Parents) <= 1, ...
        "Assertion failed: Blacklisted entry with multiple parents is not supported.");
    newParent = newIndex(ft(ii).Parents(1));
    newIndex(newIndex == ii) = newParent;
end
[outputParents, ~, mapOldToNew] = unique(newIndex);

% Update all non-blacklisted function table entries to point to non-internal
% parents.
for ii = 1:numel(ft)
    if isBlacklisted(ii)
        continue;
    end
    ft(ii).Parents(:, 1) = mapOldToNew(ft(ii).Parents(:, 1));
end

% Update the Children property of all non-blacklisted function table
% entries. This requires to accumulate all blacklisted Children tables into
% the one parent table above the blacklisted result.
for ii = 1:numel(outputParents)
    newParentIndex = outputParents(ii);
    
    isInGroup = (newIndex == newParentIndex);
    if sum(isInGroup) ~= 1
        children = vertcat(ft(isInGroup).Children);
        children(isBlacklisted(children(:, 1)), :) = [];
        if ~isempty(children)
            numChildren = max(children(:, 1), [], 1);
            children = [(1:numChildren)', ...
                accumarray(children(:, 1), children(:, 2), [numChildren, 1]), ...
                accumarray(children(:, 1), children(:, 3), [numChildren, 1])];
            children(sum(children(:, 2:3), 2) == 0, :) = [];
        end
        ft(newParentIndex).Children = children;
    end
    
    ft(newParentIndex).Children(:, 1) = mapOldToNew(ft(newParentIndex).Children(:, 1));
end
ft = ft(~isBlacklisted);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ft = iCombine(ft, other)
% Implementation of ProfileInfo/combine

% To combine two tables, we need to merge every entry that has the same
% complete name.
names = string({ft.CompleteName})';
otherNames = string({other.CompleteName})';
numOldNames = numel(names);
% This is stable to avoid having to remap the indexes of the first input
% that point to other entries in the table.
[names, ~, mapOtherToOut] = unique([names; otherNames], "Stable");
mapOtherToOut = mapOtherToOut(numOldNames + 1 : end);

% Handle each entry that exists in both. This needs to merge all properties
% correctly, as well as map indexes from other to other table entries to
% their new locations.
for otherIdx = 1:numel(mapOtherToOut)
    if mapOtherToOut(otherIdx) > numOldNames
        continue;
    end
    
    thisIdx = mapOtherToOut(otherIdx);
    
    % Children
    thisChildren = ft(thisIdx).Children;
    otherChildren = other(otherIdx).Children;
    otherChildren(:, 1) = mapOtherToOut(otherChildren(:, 1));
    ft(thisIdx).Children = iMergeSum(thisChildren, otherChildren);
    
    % Parents
    thisParents = ft(thisIdx).Parents;
    otherParents = other(otherIdx).Parents;
    otherParents(:, 1) = mapOtherToOut(otherParents(:, 1));
    ft(thisIdx).Parents = iMergeSum(thisParents, otherParents);
    
    % ExecutedLines
    thisExecutionLines = [zeros(0, 3); ft(thisIdx).ExecutedLines];
    otherExecutionLines = [zeros(0, 3); other(otherIdx).ExecutedLines];
    ft(thisIdx).ExecutedLines = iMergeSum(thisExecutionLines, otherExecutionLines);
    
    % Other
    ft(thisIdx).IsRecursive = ft(thisIdx).IsRecursive || other(otherIdx).IsRecursive;
    ft(thisIdx).TotalRecursiveTime = ft(thisIdx).TotalRecursiveTime + other(otherIdx).TotalRecursiveTime;
    ft(thisIdx).NumCalls = ft(thisIdx).NumCalls + other(otherIdx).NumCalls;
    ft(thisIdx).TotalTime = ft(thisIdx).TotalTime + other(otherIdx).TotalTime;
    
end

% Now handle all entries that only exist in other. This just needs to remap
% indexes to other entries to their new locations.
isAdditional = mapOtherToOut > numOldNames;
ft(end + 1 : numel(names)) = other(isAdditional);
for otherIdx = numOldNames + 1 : numel(names)
    % Children
    ft(otherIdx).Children(:, 1) = mapOtherToOut(ft(otherIdx).Children(:, 1));
    
    % Parents
    ft(otherIdx).Parents(:, 1) = mapOtherToOut(ft(otherIdx).Parents(:, 1));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ft = iMergeSum(ft, other)
% Apply accumarray like sum to a N x M matrix where the first column is the
% group IDs of each row.

% In the majority of cases, the two inputs have the same group IDs. It is
% faster to check and add elementwise than to always accumarray-like add.
if isempty(other)
    return;
elseif isempty(ft)
    ft = other;
    return;
elseif isequal(ft(:, 1), other(:, 1))
    ft(:, 2:end) = ft(:, 2:end) + other(:, 2:end);
    return;
end
maxId = max(max(ft(:, 1)), max(other(:, 1)));
out = zeros(maxId, size(ft, 2));
out(ft(:, 1), :) = ft;
out(other(:, 1), 1) = other(:, 1);
out(other(:, 1), 2:end) = out(other(:, 1), 2:end) + other(:, 2:end);
out(out(:, 1) == 0, :) = [];
ft = out;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ft, topStackIdx] = iBuildFunctionTableFromStack(stackTrace, timeTaken)
% Build function table entries from the given stack trace. This assumes
% there was a single call through the entire stack that takes the given
% time table.

% Each unique stack entry needs it's only function table entry.
template.CompleteName = '';
template.FunctionName = '';
template.FileName = '';
template.Type = 'M-method';
template.Children = zeros(0, 3);
template.Parents = zeros(0, 2);
template.ExecutedLines = zeros(0, 3);
template.IsRecursive = 0;
template.TotalRecursiveTime = 0;
template.PartialData = 0;
template.NumCalls = 0;
template.TotalTime = timeTaken;

[completeNames, functionNames, fileNames, lineNo] = arrayfun(...
    @describeStackEntry, stackTrace, "UniformOutput", false);
lineNo = [lineNo{:}]';

% As well as Parent/Child/Execution entries to link between entries.
[uniqueCompleteNames, iA, iC] = unique(completeNames);
ft(1:numel(uniqueCompleteNames)) = template;
topStackIdx = iC(1);
for ii = 1:numel(ft)
    ft(ii).CompleteName = uniqueCompleteNames{ii};
    ft(ii).FunctionName = functionNames{iA(ii)};
    ft(ii).FileName = fileNames{iA(ii)};
    
    idx = find(iC == ii);
    entryLineno = lineNo(idx);
    entryLineno = entryLineno(entryLineno ~= 0);
    ft(ii).ExecutedLines = [entryLineno, ones(size(entryLineno)), timeTaken*ones(size(entryLineno))];
    
    
    childIdx = idx - 1;
    childIdx(childIdx <= 0, :) = [];
    ft(ii).Children = [iC(childIdx), ones(size(childIdx)), timeTaken*ones(size(childIdx))];
    
    parentIdx = idx + 1;
    parentIdx(parentIdx > numel(ft), :) = [];
    ft(ii).Parents = [iC(parentIdx), zeros(size(parentIdx))];
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [completeName, functionName, fileName, lineNo] = describeStackEntry(stackEntry)
% Convert a stack trace entry into the name parameters needed for ProfileInfo.

fileName = stackEntry.file;
lineNo = stackEntry.line;
functionName = stackEntry.name;
if isempty(stackEntry.file)
    completeName = functionName;
else
    completeName = [stackEntry.file, '>', functionName];
    
    [~, name] = fileparts(stackEntry.file);
    if ~isequal(name, functionName)
        functionName = [name, '>', stackEntry.name];
    end
end
end
