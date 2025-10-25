function S = readtable(nodeVector, opts)
% Based on XML, output should be a scalar struct with fields:
% - Data: 1 x NumVariables cell array, each containing NumRows x 1
%         string vectors or NumRows x M strings if
%         RepeatedNodeRule="addcol" applied.
% - Counts: 1 x NumVariables integer cell array, matrix indicating num elements
%           per row, for each variable
% - RowNames: NumRows x 1 string vector, empty if not required
% - RowNamesCounts: NumRows x 1 integer vector, indicating num elements per
%                   row
% - Units: 1 x NumVariables string vector, empty if not required
% - Descriptions: 1 x NumVariables string vector, empty if not required

%   Copyright 2024 The MathWorks, Inc.
    import matlab.io.json.internal.NodeVector;
    import matlab.io.json.internal.NodeVectorData;
    import matlab.io.json.internal.JSONNodeType;

    nodeVectorTable = nodeVector.getChildrenAtSelector(opts.TableSelector);

    % Only step into rows if table node type is an array.
    if (nodeVectorTable.NodeVector.Types == JSONNodeType.Array)
        nodeVectorRows = nodeVectorTable.NodeVector.Children;
    else
        nodeVectorRows = nodeVectorTable.NodeVector;
    end

    numVariables = numel(opts.SelectedVariableIndices);

    S.Data = cell(1, numVariables);
    S.Counts = cell(1, numVariables);

    selectedVariableSelectors = opts.VariableSelectors(opts.SelectedVariableIndices + 1);

    if opts.RepeatedNodeRule == "addcol"
        for i = 1:numel(selectedVariableSelectors)
            variableSelectorsResult = nodeVectorRows.getChildrenAtSelectorExhaustive(selectedVariableSelectors(i));

            S.Data{1, i} = variableSelectorsResult.NodeVector.Data;
            S.Counts{1, i} = variableSelectorsResult.Counts;
        end
    elseif opts.RepeatedNodeRule == "ignore"

    else
        % RepeatedNodeRule = "error"
    end

    % Doesn't support RepeatedNodeRule
    % for i = 1:numel(selectedVariableSelectors)
    %     getChildrenAtSelectorResult = nodeVectorRows.getChildrenAtSelector(selectedVariableSelectors(i));
    %
    %     selectedChildren = getChildrenAtSelectorResult.NodeVector.Data;
    %     nodeVectorVariables{1, i} = selectedChildren;
    %
    %     nodeVectorMissings{1, i} = getChildrenAtSelectorResult.Missing;
    % end

    % Set RowNames if RowNameSelector is supplied
    S.RowNames = {};
    S.RowNamesCounts = {};
    if ~ismissing(opts.RowNamesSelector)
        RowNamesNodeVector = nodeVectorRows.getChildrenAtSelectorExhaustive(opts.RowNamesSelector);
        S.RowNames = RowNamesNodeVector.NodeVector.Data;
        S.RowNamesCounts = RowNamesNodeVector.Counts;
    end

    % VariableUnitsSelector and VariableDescriptionsSelector are relative
    % to the root of the file. Units and descriptions data may or may not
    % be included under the table selector.
    S.Units = {};
    if ~ismissing(opts.VariableUnitsSelector)
        S.Units = getFlatDataAtAbsoluteSelector(nodeVector, opts.VariableUnitsSelector);
    end

    S.Descriptions = {};
    if ~ismissing(opts.VariableDescriptionsSelector)
        S.Descriptions = getFlatDataAtAbsoluteSelector(nodeVector, opts.VariableDescriptionsSelector);
    end
end

% ------------------ Helper Functions -------------------
function flatData = getFlatDataAtAbsoluteSelector(nodeVector, selector)
    matchedNodeVectorResult = nodeVector.getChildrenAtSelector(selector);
    matchedNodeTypes = matchedNodeVectorResult.NodeVector.Types;

    % Error if the JSON pointer does not match any nodes
    if isempty(matchedNodeTypes)
        error(message("MATLAB:io:json:common:UnmatchedJSONPointer", selector));
    end

    % Only the first matched node's children
    if is_nested(matchedNodeTypes)
        % Get types of nodes under matched node.
        matchedNodeChildrenTypes = matchedNodeVectorResult.NodeVector.Children.Types;

        if is_nested(matchedNodeChildrenTypes)
            error(message("MATLAB:io:json:readtable:SelectorContainsNestedNodes", selector));
        end

        % TODO: Verify that the keys of this data are in the same order as
        % the variables? how about for array?
        flatData = matchedNodeVectorResult.NodeVector.Children.Data;
    else
        flatData = matchedNodeVectorResult.NodeVector.Data;
    end
end

function tf = is_nested(nodeTypes)
    import matlab.io.json.internal.JSONNodeType;

    tf = any(nodeTypes == JSONNodeType.Array) ...
         || any(nodeTypes == JSONNodeType.Object);
end
% -------------------------------------------------------------
