classdef VEUtils
    % VEUtils Helper functions to be used by the Variable Editor
    %
    % g3128711: You will see VEUtils used across StructureTreeViewModel.m,
    % StructureTreeDataModel.m, and RemoteStructureTreeViewModel.m a lot
    % for dealing with row IDs.
    %
    % Prior to the geck, row IDs were delimited with ".". For example,
    % a struct with a table would have IDs like "structName.tableName.colName".
    % This however caused an issue; since R2019b, MATLAB table variable names
    % support all of unicode, including periods. If a table variable name
    % had a period, the Variable Editor struct tree view would break.
    %
    % In other words, more generally, if any table variable name contained
    % a substring that matched our delimiter of choice, rendering broke.
    % This was not a problem when the tree view was only strictly for structs;
    % this became a problem when we supported showing tables that were children
    % of the structs.
    %
    % To fix this issue, we had to change the delimiter to an obscure combination
    % of ASCII characters that will likely never be used by users.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties(Constant)
        DELIMITER = "@#@#";
        DOT_SEPARATOR = ".";
    end

    methods(Static)
        % Check if the given string has the delimiter.
        function hasDelimiter = idHasCustomDelimiter(id)
            arguments
                id (1,1) string
            end
            hasDelimiter = contains(id, internal.matlab.variableeditor.VEUtils.DELIMITER);
        end

        % Prepend the delimiter to a given rowId.
        function newRowId = prependRowDelimiter(rowId)
            arguments
                rowId (1,1) string
            end
            newRowId = strcat(internal.matlab.variableeditor.VEUtils.DELIMITER, rowId);
        end

        % Append the delimiter to a given rowId.
        function newRowId = appendRowDelimiter(rowId)
            arguments
                rowId (1,1) string
            end
            newRowId = strcat(rowId, internal.matlab.variableeditor.VEUtils.DELIMITER);
        end
        

        % Split a given row ID. For now, we split using a period;
        % this is subject to change.
        function splitId = splitRowId(rowId)
            arguments
                rowId (1,1) string
            end
            splitId = strsplit(rowId, internal.matlab.variableeditor.VEUtils.DELIMITER);
        end

        % Join the passed in string array using the delimiter to create
        % the full row ID.
        function joinedId = joinRowId(rowIdParts)
            arguments
                rowIdParts (:,1) string
            end
            joinedId = strjoin(rowIdParts, internal.matlab.variableeditor.VEUtils.DELIMITER);
        end

        % Join the passed in string array using the delimiter to create
        % the full row ID.
        function joinedId = joinRowIdWithDotSeparator(rowIdParts)
            arguments
                rowIdParts (:,1) string
            end
            joinedId = strjoin(rowIdParts, internal.matlab.variableeditor.VEUtils.DOT_SEPARATOR);
        end

        % There are instances where we wish to use row IDs within code so we can
        % execute it within a workspace (see DeleteAction.m).
        % Assume our delimiter is "#". We could, for example, reference a struct
        % field with "structureName#fieldName". We need to change "#" to "." in order to reference it in code.
        % If substitutePeriod = false, this will only make the arbitrary var names executable and leave the delimiters in.
        function executableRowIds = getExecutableRowIdVersion(rowId, substitutePeriod)
            arguments
                rowId (:,1) string
                substitutePeriod (1,1) logical = true
            end
            if all(strcmp(rowId, "")) || isempty(rowId)
                executableRowIds = "";
                return;
            end
            validRowIds = arrayfun(@internal.matlab.variableeditor.VEUtils.convertToExecutableVarNames, rowId);
            executableRowIds = validRowIds;
            if substitutePeriod
                executableRowIds = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(validRowIds);
            end
        end

        function periodDelimitedId = getPeriodDelimitedRowIds(rowId)
            arguments
                rowId (:,1) string
            end
            periodDelimitedId = strrep(rowId, internal.matlab.variableeditor.VEUtils.DELIMITER, ".");
        end


        % Converts table variable names that can be part of fields to be executable in case they are arbitrary
        % If fieldName is ["s@#@#x.r*andomName","s@#@#mj"] convertToExecutableVarNames
        % will return executableField as ["s@#@#("x.r*andomName")","s@#@#mj"].
        function executableField = convertToExecutableVarNames(fieldName)
            arguments
                fieldName (:,1) string
            end
            import internal.matlab.variableeditor.VEUtils;
            executableField = fieldName;
            splitFields = VEUtils.splitRowId(fieldName);
            invalidVarNameIndices = ~(arrayfun(@isvarname, splitFields));
            if any(invalidVarNameIndices)
                invalidVarNames = splitFields(invalidVarNameIndices);
                validVarNames = arrayfun(@VEUtils.getValidVarNameString, invalidVarNames);
                splitFields(invalidVarNameIndices) = validVarNames;
                executableField = VEUtils.joinRowId(splitFields);
            end
        end

        function validName = getValidVarNameString(arbitraryName)
            validName = arbitraryName;
            if strcmp(arbitraryName, "")
                return;
            end
            [~,~,validName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(arbitraryName, '', NaN);
            validName = compose("(%s)", validName);
        end

        % The inverse of "getExecutableRowIdVersion()".
        %
        % NOTE: Use this function only if we know we don't have to deal with arbitrary variable names.
        % passing along results of getExecutableRowIdVersion here might
        % replace any valid presence of '.' with delimiter @#@# which can never be translated back to executable code.
        function customDelimitedId = getCustomDelimitedRowIdVersion(rowId)
            arguments
                rowId (:,1) string
            end
            customDelimitedId = strrep(rowId, ".", internal.matlab.variableeditor.VEUtils.DELIMITER);
        end

        % Given a row ID, get its parent field ID.
        % Assume our delimiter is ".". Example: "s.t.Column" -> "s.t"
        function parentFieldId = getParentFieldIds(rowIds)
            arguments
                rowIds (:,1) string
            end

            delim = internal.matlab.variableeditor.VEUtils.DELIMITER;

            % The regex essentially:
            % 1. Matches the delimeter.
            % 2. Matches proceeding characters that aren't the delimiter until
            %    the end of the string.
            %    - If a delimiter is encountered while going to the end of
            %      the string, the match is broken.
            %
            % Example: Assume the delimiter is "#".
            %          s#t#a -> the regex would match "#a" and replace it with "".
            regexString = sprintf("(%s)(?:.(?!(%s)))+$", delim, delim);
            parentFieldId = regexprep(rowIds, regexString, "");
        end
    end
end
