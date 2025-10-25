% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for if no unimportable rules are supported

% Copyright 2022 The MathWorks, Inc.

classdef NoRulesStrategy < handle
    methods
        function generateExclusionMaps(this, data, raw, dateData, ...
                trimNonNumericCols, startRow, endRow, startColumn, endColumn, ...
                selRows, selCols, columnClasses) %#ok<*INUSD>
        end

        function r = getRuleReplacementValue(this) %#ok<*MANU>
            r = NaN;
        end

        function v = getExclusionType(this, row, col, currType)
            v = currType;
        end

        function setFileImporterState(this, state)
        end

        function rules = getRulesList(this)
            rules = [];
        end
    end
end