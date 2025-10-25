function T = buildSelected(obj, varargin)
%TableBuilder.buildSelected   Construct a table from the current TableBuilder options.
%
%   Unlike TableBuilder.build(), you only have to specify selected
%   variables in the input to this function.
%
%   So the number of input variables should match the number of
%   SelectedVariableNames/SelectedVariableIndices.
%
%   NOTE: SelectedVariableIndices isn't necessarily in ascending order!
%   Make sure that your inputs are in the same order as
%   SelectedVariableIndices.

%   Copyright 2022 The MathWorks, Inc.

    % Verify that we don't need to print a warning here.
    assert(~obj.Options.WarnOnNormalizationDuringBuild);

    % The number of variables passed in must match the number of selected variable names in
    % the TableBuilder.
    Nexpected = numel(obj.SelectedVariableIndices);
    Nactual = numel(varargin);
    if Nexpected ~= Nactual
        msgid = "MATLAB:io:common:builder:IncorrectNumberOfVariablesForBuild";
        error(message(msgid, "buildSelected", "SelectedVariableIndices", Nactual, Nexpected));
    end

    % Verify that the heights of all input variables are consistent.
    import matlab.io.internal.common.builder.TableBuilder.validateConsistentVariableHeights
    heights = validateConsistentVariableHeights(varargin{:});

    % Perform the type check if there are nonmissing VariableTypes.
    import matlab.io.internal.common.builder.TableBuilder.checkVariableTypes
    checkVariableTypes(obj.Options, true, varargin{:});

    % table.init needs numVars and numRows.
    numSelectedVars = numel(varargin);
    numRows = heights;

    % Construct the table.
    selectedVarNames = obj.SelectedVariableNames;
    dimNames = obj.Options.DimensionNames;
    T = table.init(varargin, numRows, {}, numSelectedVars, selectedVarNames, dimNames);

    % Populate VariableDescriptions if the OriginalSelectedVariableNames differ
    % from the normalized SelectedVariableNames.
    assert(obj.Options.SaveOriginalVariableNamesInVariableDescriptions);
    if ~isempty(obj.SelectedVariableDescriptions)
        % Only populate VariableDescriptions when necessary. This allows
        % the default VariableDescriptions to match table's default, which
        % is a 0x0 empty cell.
        T.Properties.VariableDescriptions = obj.SelectedVariableDescriptions;
    end

    % Apply the RowFilter constraint if one is present.
    % This will error if the RowFilter constraint uses a variable that is not on the
    % generated table.
    if ~obj.IsTrivialFilter && (numel(constrainedVariableNames(obj.OriginalRowFilter)) > 0)
        T = filter(obj.RowFilter, T);
    end
end
