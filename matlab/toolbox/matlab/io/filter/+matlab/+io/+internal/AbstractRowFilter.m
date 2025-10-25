classdef (Abstract) AbstractRowFilter < matlab.mixin.internal.Scalar ...
                                      & matlab.mixin.CustomDisplay ...
                                      & matlab.mixin.internal.indexing.RedefinesDot ...
                                      & matlab.mixin.internal.indexing.OverridesPublicDotMethodCall ...
                                      & matlab.io.internal.filter.util.OverloadRelationalOperators ...
                                      & matlab.io.internal.filter.util.OverloadBinaryOperators

%AbstractRowFilter    Abstract superclass for RowFilter objects.
%
%   Subclasses need to define three methods: filterIndices, traverse, and
%       constrainedVariableNames.
%
%   See also: rowfilter

%   Copyright 2021-2022 The MathWorks, Inc.

    methods (Hidden)
        function [T, idx] = filter(obj, T)
            arguments
                obj (1, 1) matlab.io.internal.AbstractRowFilter
                T {matlab.io.internal.filter.validators.validateTabular}
            end

            idx = filterIndices(obj, T);

            T = T(idx, :);
        end
    end

    % The "Properties" property is protected so that it doesn't interfere
    % with variable names on the filter object.
    % Use the setProperties and getProperties methods to access/set it.
    properties (Access = protected)
        Properties (1, 1) matlab.io.internal.filter.properties.Properties = matlab.io.internal.filter.properties.MissingRowFilterProperties(string.empty(0, 1));
    end

    properties (Hidden, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of RowFilter in R2022a.
        ClassVersion(1, 1) double = 1;
    end

    methods (Hidden)
        function props = getProperties(obj)
            props = obj.Properties;
        end

        function obj = setProperties(obj, props)
            arguments
                obj   (1, 1) matlab.io.internal.AbstractRowFilter
                props (1, 1) matlab.io.internal.filter.properties.Properties
            end
            obj.Properties = props;
        end
    end

    methods (Abstract, Hidden)
        %filterIndices   Returns an h-by-1 logical column vector describing
        %   whether each row of the input table/timetable is satisfied by
        %   this filtering criterion.
        %
        %   Subclasses should also test with edge-cases from empty
        %   table/timetable inputs.
        tf = filterIndices(obj, T);

        %traverse   A "visitor" pattern implementation for RowFilter
        %   subclasses.
        %
        %   FUN should be a function_handle accepting one input (a subclass
        %   of matlab.io.AbstractRowFilter) and returning one output (also a
        %   matlab.io.AbstractRowFilter object).
        %
        %   The order of traversal is intended to be a depth-first and
        %   "in-order" (as opposed to pre-order/post-order):
        %
        %   - 0 child filters: Just visit the filter itself.
        %   - 1 child filter : Visit the child of the filter, then visit
        %                      the filter itself.
        %   - 2 child filters: Visit the left child, then visit the filter,
        %                      then visit the right child.
        %
        %   Some traversal functions may modify the input object. Since
        %   matlab.io.AbstractRowFilter is now a value object, modifications to the
        %   input object will only persist if the same object is returned
        %   as an output.
        obj = traverse(obj, fun);

        %constrainedVariableNames   Return the list of variable names that 
        %   actually have constraints defined on them.
        %
        %   This is used later in parquetread to make sure that statistics
        %   metadata is only read for specific variables.
        variableNames = constrainedVariableNames(obj);
    end

    methods (Hidden)
        function obj = replaceVariableNames(obj, oldVariableNames, newVariableNames)
            arguments
                obj (1, 1) matlab.io.internal.AbstractRowFilter
                oldVariableNames (1, :) string {mustBeNonmissing}
                newVariableNames (1, :) string {mustBeNonmissing}
            end

            % Replace variable names on the Properties object.
            obj.Properties = replaceVariableNames(obj.Properties, oldVariableNames, newVariableNames);
        end

        function newFilter = applyRelationalOperator(~, ~, ~)
            % Relational operator method must be overloaded. Error if this
            % isn't implemented in the subclass.
            error(message("MATLAB:io:filter:filter:InvalidRowFilterForRelationalOperator"));
        end
    end

    methods (Access = protected)
        function varargout = dotReference(obj, indexingOperation)
            arguments
                obj (1, 1) matlab.io.internal.AbstractRowFilter
                indexingOperation (1, :) matlab.internal.indexing.IndexingOperation
            end

            variableName = validateDotIndexing(indexingOperation);
            possibleVariableNames = getProperties(obj).VariableNames;

            variableNameIndex = find(possibleVariableNames == variableName, 1);
            if isempty(variableNameIndex)
                % This is a design choice. Error for now.
                if isempty(possibleVariableNames)
                    % Needs to be handled separately since join() will
                    % error otherwise.
                    varNamesString = "";
                else
                    varNamesString = join(possibleVariableNames, ", ");
                end
                error(message("MATLAB:io:filter:filter:InvalidDotIndexingVariableNames", varNamesString));
            end

            % Create a RowFilter object out of these variable names.
            varargout{1} = buildUnconstrainedFilter(obj, variableName, possibleVariableNames);
        end

        function rf = buildUnconstrainedFilter(obj, variableName, possibleVariableNames)
            import matlab.io.internal.filter.UnconstrainedRowFilter;
            import matlab.io.internal.filter.UnconstrainedEventFilter;
            import matlab.io.internal.filter.properties.UnconstrainedRowFilterProperties;

            props = UnconstrainedRowFilterProperties(variableName, possibleVariableNames);
            rf = UnconstrainedRowFilter(props);
           
        end

        function obj = dotAssign(~, ~, ~)
            % Dot assignment is currently unsupported.
            error(message("MATLAB:io:filter:filter:UnsupportedDotAssignment"));
        end

        function n = dotListLength(~, ~, ~)
            n = 1;
        end
    end

    methods (Hidden)
        function props = properties(obj)
        % Get the existing list of properties.
            props = string(builtin("properties", obj));

            % Add any known possible variable names at the end of the properties list.
            props = [props; getProperties(obj).VariableNames'];
            props = cellstr(unique(props, 'stable'));
        end

        % Saveobj is shared, but loadobj is distributed to each individual
        % subclass since they need to know how to construct from their
        % Properties objects.
        function S = saveobj(rf)
            % Store save-load metadata.
            S = struct("EarliestSupportedVersion", 1);
            S.ClassVersion = rf.ClassVersion;

            % Private properties.
            S.Properties = rf.Properties;
        end
    end

    methods (Abstract, Hidden)
        s = formatDisplayHeader(obj, classname);
        s = formatDisplayBody(obj);
    end

    methods (Access = protected)
        function displayScalarObject(obj)
            % Just display the header, body, and footer.
            classname = string(matlab.mixin.CustomDisplay.getClassNameForHeader(obj));

            disp("  " + formatDisplayHeader(obj, classname) + newline);
            disp("    " + formatDisplayBody(obj) + newline);
            disp("  " + formatDisplayFooter(obj) + newline);
        end

        function s = formatDisplayFooter(obj)
            varNames = obj.Properties.VariableNames;

            if isempty(varNames)
                % Don't even display the footer in this case.
                s = string.empty(0, 1);
            else
                s = message("MATLAB:io:filter:display:VariableNamesFooter").getString();
                s = s + " " + join(varNames, ", ");

                % Use truncateLine (source in the ioWrapString function
                % in matlab/src/services/io/iofun.cpp.) to truncate based
                % on display window width.
                % Also, replace the special characters in VariableNames:
                % Newline with knuckle "return arrow ↵",
                % CR with "backarrow ←" ("ellipsis ..." for both in nodesktop),
                % and tab with "right arrow →".
                s = matlab.internal.display.truncateLine(s);
            end
        end
    end
end

function input = validateDotIndexing(indexingOperation)
    arguments
        indexingOperation (1, :) matlab.internal.indexing.IndexingOperation
    end

    % Error if a user performs multi-level indexing or non-dot
    % indexing.
    isMultiLevelIndexing = numel(indexingOperation) > 1;
    isDotIndexing = all([indexingOperation.Type] == matlab.indexing.IndexingOperationType.Dot);
    if isMultiLevelIndexing || ~isDotIndexing
        error(message("MATLAB:io:filter:filter:InvalidIndexingOperation"));
    end

    % Verify that all input indices are char vectors or strings.
    inputs = cell(1, numel(indexingOperation));
    [inputs{1:numel(indexingOperation)}] = convertCharsToStrings(indexingOperation.Name);

    if any(~cellfun(@isStringScalar, inputs))
        error(message("MATLAB:io:filter:filter:InvalidDotIndexingInput"));
    end

    % Return just the first string.
    input = inputs{1};
end

