%   GENERATEVARIABLENAMEASSIGNMENTSTRING generates a variable name assignment In
%   most cases the RHS is the same as the input string but for cases where there
%   are control characters or quotes the output name will be formatted into
%   valid MATLAB syntax

% Copyright 2015-2023 The MathWorks, Inc.

function [varNameExpr, subsExpr, validRHS] = generateVariableNameAssignmentStringDataset(t, subs, vname, tname)
    arguments
        t
        subs
        vname string
        tname
    end
    varNameExpr = tname;

    tempTable = internal.matlab.datatoolsservices.VariableUtils.convertDatasetToTable(t);
    ind = subscripts2indices(tempTable,subs,'assignment','varDim');

    if ~isscalar(ind)
        error(message('MATLAB:tabular:MultipleSubscripts'));
    end

    % Escape any "" as this will generate string syntax
    validRHS = strrep(vname, '"', '""');
    validRHS = """" + validRHS; % Wrap in quotes for RHS assignment

    hasControlChars = find((char(vname)<=31 | char(vname)==127), 1);
    if ~isempty(hasControlChars)
        charRHS = char(validRHS);
        controlChars = (char(validRHS)<=31 | char(validRHS)==127);
        intControlChars = int64(unique(charRHS(controlChars)));
        for i=1:length(intControlChars)
            if char(intControlChars(i)) == newline
                validRHS = strrep(validRHS, char(intControlChars(i)), """ + newline + """);
            else
                validRHS = strrep(validRHS, char(intControlChars(i)), """ + char(" + intControlChars(i) + ") + """);
            end
            validRHS = strrep(validRHS, char(intControlChars(i)), """ + newline + """);
        end
    end
    validRHS = validRHS + """";
    % return validRHS in char
    validRHS = char(validRHS);
    subsExpr = ['.Properties.VarNames{' num2str(ind) '}'];
    varNameExpr = [char(varNameExpr) subsExpr ' = ' validRHS];
end
