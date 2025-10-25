function indices = validateSelectedVariableNames(opts, ...
                                                 SelectedVariableNames, ...
                                                 UseOriginalVariableNames)
%validateSelectedVariableNames   Verifies that SelectedVariableNames is a
%   unique subset of VariableNames.
%
%   If UseOriginalVariableNames is set to true, then the supplied
%   SelectedVariableNames are validated against OriginalVariableNames
%   If UseOriginalVariableNames is false, then they are validated against
%   VariableNames instead.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts
        SelectedVariableNames (1, :)
        UseOriginalVariableNames (1, 1) logical
    end

    SelectedVariableNames = convertCharsToStrings(SelectedVariableNames);
    validateattributes(SelectedVariableNames, ["string" "char" "cellstr"], string([]), string(missing), "SelectedVariableNames");

    if any(ismissing(SelectedVariableNames))
        error(message("MATLAB:io:common:builder:SelectedVariableNamesMustBeNonmissing"));
    end

    % Decide whether to use normalized or non-normalized variable
    % names for validation.
    if UseOriginalVariableNames
        varNames = opts.OriginalVariableNames;
    else
        varNames = opts.VariableNames;
    end

    % SelectedVariableNames must be a subset of VariableNames.
    [isfound, indices] = ismember(SelectedVariableNames, varNames);

    % Don't do any further validation if SelectedVariableNames is empty.
    if isempty(SelectedVariableNames)
        return;
    end

    if ~all(isfound)
        padding = newline + "    ";
        msgstr = newline + padding + join(varNames, padding);
        error(message("MATLAB:io:common:builder:SelectedVariableNamesInvalid", msgstr));
    end

    if numel(unique(indices)) == numel(indices)
        % No duplicates, so we can exit early.
        return;
    end

    % If SelectedVariableNames have duplicate values, then de-duplicate
    % them and set duplicate indices if necessary.
    % Duplicate names are only possible when matching against
    % OriginalVariableNames since VariableNames are already unique-ified.
    [isfound, indices] = matlab.io.internal.common.builder.TableBuilder.ismember(SelectedVariableNames, varNames);
    if ~all(isfound)
        throwTooManyDuplicatesError(isfound, varNames, SelectedVariableNames);
    end
end

function throwTooManyDuplicatesError(isfound, variableNames, selectedVariableNames)
    svnIndex = find(~isfound, 1, "first");
    duplicateName = selectedVariableNames(svnIndex);
    maxNumDuplicates = sum(duplicateName == variableNames);
    specifiedNumDuplicates = sum(duplicateName == selectedVariableNames);

    msgid = "MATLAB:io:common:builder:TooManyDuplicateSelectedVariableNames";
    error(message(msgid, duplicateName, specifiedNumDuplicates, maxNumDuplicates));
end
