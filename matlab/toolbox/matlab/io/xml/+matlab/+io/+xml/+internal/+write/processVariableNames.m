function [formattedVarNames, writeAttribute]= processVariableNames(...
    data, varNames, varTraits, AttributeSuffix)
    % PROCESSVARNAMES handles duplicating variable names for variables with
    % multiple columns, returns the variable names for a table without
    % multi-column variables.

    formattedVarNames = cell(size(varNames));
    writeAttribute = cell(size(varNames));
    for i = 1:length(formattedVarNames)
        % Validate variable name for XML specifications and determine whether
        % to write the variable as an attribute
        [validatedVarName, toWriteAttribute] = removeAttrFromVariableName(...
            varNames{i}, AttributeSuffix);

        % Get header for each variables
        formattedVarNames{i} = makeVariableNamesForMultiColumnVariable({validatedVarName}, varTraits.nVarFields{i}, toWriteAttribute);

        % populate writeAttribute vector
        writeAttribute{i} = repelem(toWriteAttribute, sum(varTraits.nVarFields{i}));
    end

    % Flatten the cell array containing the expanded variable names list and...
    % writeAttribute values(for multi-column table variables).
    if ~isempty(formattedVarNames)
        formattedVarNames = [formattedVarNames{:}];
        writeAttribute = [writeAttribute{:}];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function variableNames = makeVariableNamesForMultiColumnVariable(variableName, columnWidths, writeAttribute)
    % Create multiple output variable names for a multi-column variable
    % (e.g. a 2x2 cell variable) given the original name of the table variable.

    % The number of output variable names required for multi-column variables
    % should be equal to the sum of the "widths" of each column.
    %
    % Example:
    %
    % Given a 2 x 2 cell array:
    %
    %               { [ 1    ], [ 2 ];
    %                 [ 3, 4 ], [ 5 ] }
    %
    % ColumnWidths =  |   2  |  | 1 |
    %
    % The number of required output variable names
    % would be sum([2, 1]) = 3.
    %
    % When visualized as shown above, it is
    % possible to more easily see that the "total width" of the variable
    % can be considered 3 rather than 2 (the width of the outer cell array).
    numVariableNames = sum(columnWidths);
    if numVariableNames > 1
        if (writeAttribute)
            % Number the output variable names since XML attribute names must be unique.
            variableNames = matlab.internal.datatypes.numberedNames([variableName{1},'_'],1:numVariableNames);
        else
            variableNames = repmat(variableName, 1, numVariableNames);
        end
    else
        variableNames = variableName;
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [noAttr, isAttribute]= removeAttrFromVariableName(varName,...
                                                      AttributeSuffix)
    % REMOVEATTRFROMVARIABLENAME Erases AttributeSuffix from the variable name
    % and then verifies that the result follows XML specifications

    noAttr = varName;
    isAttribute = false;

    if strcmp(AttributeSuffix, "")
        % If AttributeSuffix is empty, then attributes should not be
        % written to the output file.
    else
        if all(~ismissing(AttributeSuffix)) && endsWith(noAttr, AttributeSuffix)
            endIdx = strlength(noAttr) - strlength(AttributeSuffix) + 1;
            noAttr = eraseBetween(noAttr, endIdx, strlength(noAttr));
            isAttribute = true;
        end

        if strlength(noAttr) == 0
            msgid = "MATLAB:io:xml:writetable:VariableCannotBeExactAttributeSuffixMatch";
            error(message(msgid, varName, AttributeSuffix));
        end

        matlab.io.xml.internal.write.validateNodeName(noAttr, "VariableNames", isAttribute);
    end
end

% Copyright 2020-2024 The MathWorks, Inc.
