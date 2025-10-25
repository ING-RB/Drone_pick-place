classdef DictionaryComparator < matlab.unittest.internal.constraints.ContainerComparator
    % DictionaryComparator - Comparator for dictionaries.
    %
    %   The DictionaryComparator compares dictionaries by iterating over each
    %   value. By default, a DictionaryComparator only supports uninitialized
    %   dictionaries. To compare initialized dictionaries, pass another
    %   comparator to the DictionaryComparator constructor.
    %
    %   DictionaryComparator methods:
    %       DictionaryComparator - Class constructor
    %
    %   DictionaryComparator properties:
    %       Recursive - Boolean indicating whether the instance operates recursively
    %
    %   See also:
    %       matlab.unittest.constraints.IsEqualTo

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant, Access=private)
        Catalog = matlab.internal.Catalog("MATLAB:unittest:DictionaryComparator");
    end

    methods (Hidden, Access=protected)
        function bool = supportsContainer(~, value)
            bool = builtin("isa", value, "dictionary");
        end

        function bool = containerSatisfiedBy(~, actualValue, expectedValue)
            bool = haveSameClass(actualValue, expectedValue) && ...
                haveSameKeyTypes(actualValue, expectedValue) && ...
                haveSameKeys(actualValue, expectedValue);
        end

        function subComparisons = getElementComparisons(comparator, comparison)
            import matlab.unittest.constraints.Comparison;

            actualDictionary = comparison.ActualValue;
            expectedDictionary = comparison.ExpectedValue;

            expectedEntries = expectedDictionary.entries("struct");
            expectedElementsCell = {expectedEntries.Value};

            % N.B.: actual and expected value keys might have different
            % orderings. Use expected value ordering to access values.
            actualElementsCell = cell(1, numel(expectedEntries));
            for idx = 1:numel(expectedEntries)
                actualElementsCell{idx} = actualDictionary(expectedEntries(idx).Key);
            end

            comparators = comparator.getComparatorsForElements(comparison);
            args = {actualElementsCell, expectedElementsCell, {comparators}};
            if comparison.IsUsingValueReference
                args{end+1} = generateSubReference(expectedEntries, comparison.ValueReference);
            end
            subComparisons = Comparison.fromCellArrays(args{:});
        end

        function conds = getContainerConditionsFor(comparator, actualValue, expectedValue)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.diagnostics.Diagnostic;
            import matlab.unittest.diagnostics.ConstraintDiagnostic;

            if ~haveSameClass(actualValue, expectedValue)
                conds = ConstraintDiagnosticFactory.generateClassMismatchDiagnostic(actualValue, expectedValue);
                return;
            end

            if ~haveSameKeyTypes(actualValue, expectedValue)
                conds = comparator.generateKeyTypeMismatchDiagnostic(actualValue, expectedValue);
                return;
            end

            extraKeys = getExtraKeys(actualValue, expectedValue);
            missingKeys = getMissingKeys(actualValue, expectedValue);

            if isempty(extraKeys) && isempty(missingKeys)
                conds = Diagnostic.empty(1,0);
                return;
            end

            conds = ConstraintDiagnostic;
            conds.DisplayDescription = true;
            conds.DisplayConditions = true;
            conds.Description = comparator.Catalog.getString("KeysMismatch");

            maxDisplayedKeys = 10;
            if ~isempty(extraKeys)
                conds.addCondition(comparator.getExtraKeyDiagnostic(extraKeys, maxDisplayedKeys));
            end
            if ~isempty(missingKeys)
                conds.addCondition(comparator.getMissingKeyDiagnostic(missingKeys, maxDisplayedKeys));
            end
        end
    end

    methods (Access=private)
        function diag = generateKeyTypeMismatchDiagnostic(comparator, actualValue, expectedValue)
            import matlab.unittest.diagnostics.ConstraintDiagnostic;

            diag = ConstraintDiagnostic;
            diag.DisplayDescription = true;
            diag.Description = comparator.Catalog.getString("TypesMismatch");

            diag.DisplayActVal = true;
            diag.ActValHeader = comparator.Catalog.getString("ActualKeyType");
            diag.ActVal = char(strtrim(formattedDisplayText(actualValue.types)));

            diag.DisplayExpVal = true;
            diag.ExpValHeader = comparator.Catalog.getString("ExpectedKeyType");
            diag.ExpVal = char(strtrim(formattedDisplayText(expectedValue.types)));
        end

        function diag = getExtraKeyDiagnostic(comparator, extraKeys, maxDisplayedKeys)
            header = string(comparator.Catalog.getString("ExtraKeys"));
            numExtra = numel(extraKeys);
            if numExtra > maxDisplayedKeys
                extraKeys = extraKeys(1:maxDisplayedKeys);
                header = string(comparator.Catalog.getString("ExtraKeysFirstN", maxDisplayedKeys, numExtra));
            end
            diag = header + newline + getIndentedKeyListString(extraKeys);
        end

        function diag = getMissingKeyDiagnostic(comparator, missingKeys, maxDisplayedKeys)
            header = string(comparator.Catalog.getString("MissingKeys"));
            numMissing = numel(missingKeys);
            if numMissing > maxDisplayedKeys
                missingKeys = missingKeys(1:maxDisplayedKeys);
                header = string(comparator.Catalog.getString("MissingKeysFirstN", maxDisplayedKeys, numMissing));
            end
            diag = header + newline + getIndentedKeyListString(missingKeys);
        end
    end
end

function bool = haveSameClass(actualValue, expectedValue)
bool = strcmp(class(actualValue), class(expectedValue));
end

function bool = haveSameKeyTypes(actualValue, expectedValue)
bool = isequaln(actualValue.types, expectedValue.types);
end

function bool = haveSameKeys(actualDictionary, expectedDictionary)
bool = isempty(getExtraKeys(actualDictionary, expectedDictionary)) && ...
    isempty(getMissingKeys(actualDictionary, expectedDictionary));
end

function extraKeys = getExtraKeys(actualDictionary, expectedDictionary)
extraKeys = keySetDifference(actualDictionary, expectedDictionary);
end

function missingKeys = getMissingKeys(actualDictionary, expectedDictionary)
missingKeys = keySetDifference(expectedDictionary, actualDictionary);
end

function keys = keySetDifference(firstDictionary, secondDictionary)
% Returns keys in firstDictionary but not in secondDictionary.

firstKeys = firstDictionary.keys("cell");

if secondDictionary.numEntries == 0
    keys = firstKeys;
    return;
end

keys = firstKeys(~cellfun(@(key)secondDictionary.isKey(key), firstKeys));
end

function subReference = generateSubReference(expectedEntries, valueReference)
import matlab.unittest.internal.getOneLineSummary;

keys = {expectedEntries.Key};
subReference = valueReference + "(" + cellfun(@getOneLineSummary, keys) + ")";
end

function str = getIndentedKeyListString(keys)
import matlab.unittest.internal.getOneLineSummary;
import matlab.unittest.internal.diagnostics.indent;

maxLength = Inf;
str = indent(join(cellfun(@(value)getOneLineSummary(value, maxLength), keys), newline));
end

% LocalWords:  conds
