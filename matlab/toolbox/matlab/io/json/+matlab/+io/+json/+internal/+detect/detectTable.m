function result = detectTable(nv, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.JSONNodeType;

    % Detect TableSelector, VariableSelectors, VariableNames,
    % VariableTypes, and TableDetected.

    % Apply TableNodeName or TableSelector if supplied.
    if ~ismissing(opts.TableNodeName)
        tableSelector = nv.resolveNodeNameToSelector(opts.TableNodeName);

        if ismissing(tableSelector)
            error(message("MATLAB:io:xml:common:NonexistentNode", opts.TableNodeName, opts.Filename, "TableNodeName"));
        end

        searchResult = nv.getChildrenAtSelector(tableSelector);
        nv = searchResult.NodeVector;
        result.TableSelector = tableSelector;

    elseif ~ismissing(opts.TableSelector)
        searchResult = nv.getChildrenAtSelector(opts.TableSelector);

        if searchResult.Missing
            error(message("MATLAB:io:xml:detection:TableSelectorInvalidSelection"));
        end

        nv = searchResult.NodeVector;
        result.TableSelector = opts.TableSelector;
    else
        % Use a heuristic to find the biggest table in the file.
        result.TableSelector = matlab.io.json.internal.detect.findTableNode(nv);
        nv = nv.getChildrenAtSelector(result.TableSelector).NodeVector;
    end

    if nv.Types == JSONNodeType.Array % Multi-row table.
        rowNodes = nv.Children; % Get row nodes.
    else
        rowNodes = nv;
    end

    if ~isscalar(opts.VariableNodeNames) || ~ismissing(opts.VariableNodeNames)
        % Resolve VariableNodeNames to VariableSelectors.

        variableSelectors = strings(1, numel(opts.VariableNodeNames));
        for i=1:numel(opts.VariableNodeNames)
            nodeName = opts.VariableNodeNames(i);
            selector = rowNodes.resolveNodeNameToSelector(nodeName);
            if ismissing(selector)
                error(message("MATLAB:io:xml:detection:VariableNodeNamesNonexistentNode", nodeName, opts.Filename));
            else
                variableSelectors(i) = selector;
            end
        end
        result.VariableSelectors = variableSelectors;

    elseif ~isscalar(opts.VariableSelectors) || ~ismissing(opts.VariableSelectors)
        % Apply VariableSelectors on the rows.
        result.VariableSelectors = opts.VariableSelectors;
    else
        result.VariableSelectors = matlab.io.json.internal.detect.generateVariableSelectors(nv);
    end

    result.VariableNames = extractVariableNames(result.VariableSelectors);
    result.VariableTypes = detectTypes(rowNodes, result.VariableSelectors, opts);

    tableNotDetected = (ismissing(result.TableSelector) || strlength(result.TableSelector) == 0) && ...
        isscalar(result.VariableSelectors) && (strlength(result.VariableSelectors) == 0);
    result.TableDetected = ~tableNotDetected;
end

function name = extractVariableName(selector)
    if strlength(selector) == 0
        name = "Var1";
        return;
    end

    selector = char(selector);
    pos = find(selector == '/', 1, 'last');
    if isempty(pos)
        name = string(selector);
    else
        name = string(extractAfter(selector, pos));
    end
end

function names = extractVariableNames(selectors)
    if isempty(selectors)
        names = string.empty(1, 0);
        return;
    end
    names = arrayfun(@extractVariableName, selectors);
end

function type = detectType(nv, selector, opts)
    import matlab.io.json.internal.JSONNodeType;

    % Evaluate the selector.
    searchResult = nv.getChildrenAtSelectorExhaustive(selector);
    if all(searchResult.Counts == 0)
        % Check if the selector can't be resolved at all.
        existenceSearchResult = nv.getChildrenAtSelector(selector);
        if all(existenceSearchResult.Missing)
            % Does not exist in the file at all.
            error(message("MATLAB:io:xml:detection:VariableSelectorsInvalidSelection"));
        end

        % Nothing to detect if there's no data. Default to "double" type.
        type = "double";
        return;
    end
    nv = searchResult.NodeVector;

    types = nv.Types;

    % Check if all true/false. This becomes a logical variable. All other
    % cases get promoted to string or double.
    if all(types == JSONNodeType.False | types == JSONNodeType.True)
        type = "logical";
        return;
    end

    % nulls, objects, and arrays don't count in further type resolution.
    types(types == JSONNodeType.Null) = [];
    types(types == JSONNodeType.Object) = [];
    types(types == JSONNodeType.Array) = [];

    % Logical is treated as number for subsequent steps.
    types(types <= JSONNodeType.True) = JSONNodeType.Number;

    % Count the number of strings and numbers.
    numStrings = sum(types == JSONNodeType.String);
    numNumbers = sum(types == JSONNodeType.Number);

    if numStrings > numNumbers
        type = "string";

    elseif numNumbers > numStrings
        type = "double";

    else % numNumbers == numStrings
         % Tie-break based on order of types.
        if isempty(types) || (types(1) == JSONNodeType.Number)
            type = "double";
        else
            type = "string";
        end
    end

    % If string type was detected, refine further by time type.
    if type == "string"
        % Only get at most 256 rows of strings.
        nv = nv.subset(0x0u64:min(numel(types)-1, 256));
        strs = nv.Data.Strings;
        timeTypes = matlab.io.json.internal.detectTimeTypes(strs, opts.DateLocale);
        if isempty(strs)
            type = "string";
        elseif all(timeTypes == 1) % datetime
            type = "datetime";
        elseif all(timeTypes == 2) % duration
            type = "duration";
        end % Otherwise just read in as string.
    end
end

function types = detectTypes(nv, selectors, opts)
    if isempty(selectors)
        % Empty table detected.
        types = string.empty(1, 0);
        return;
    end

    types = arrayfun(@(selector) detectType(nv, selector, opts), selectors);
end
