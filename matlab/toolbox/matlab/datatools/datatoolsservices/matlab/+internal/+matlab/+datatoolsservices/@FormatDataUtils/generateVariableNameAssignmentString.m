% Replicate the logic in
% matlab.internal.tabular.generateVariableNameAssignmentString until this
% function is available.  Allows calling the method without an actual table,
% as one will be created temporarily for it. NOTE: this API will by default
% generate code with strings.

% Copyright 2015-2023 The MathWorks, Inc.

function [varNameExpr, subsExpr, validRHS] = generateVariableNameAssignmentString(vname, tname, ind)
    arguments
        % The Variable (column) Name in the table
        vname (1,1) string

        % The table name
        tname (1,1) string

        % The column index.  If ~isnan, a table will be created up to this
        % index.  Be aware if calling from code on a critical performance path.
        ind (1,1) double
    end

    varNameExpr = [];

    if ~isnan(ind)
        % Only attempt to create a table if we have a valid index
        l = lasterror; %#ok<*LERR>
        try
            t = table('Size', [1, ind], 'VariableTypes', repmat({'double'}, 1, ind));
            [varNameExpr, subsExpr, validRHS] = ...
                matlab.internal.tabular.generateVariableNameAssignmentString(t, ind, vname, tname);
            varNameExpr = string(varNameExpr);
            subsExpr = string(subsExpr);
            validRHS = string(validRHS);
        catch
        end
        lasterror(l);
    end

    if isempty(varNameExpr)
        varNameExpr = tname;
        validRHS = strrep(vname, '"', '""');
        validRHS = """" + validRHS; % Wrap in quotes for RHS assignment
        % If the varname has control characters, separate the code with
        % <varnameparts> + char(<controlChar>) + <varnameparts> For newlines.
        % just use the ML keyword newline.
        hasControlChars = find((char(vname)<=31 | char(vname)==127), 1);

        if ~isempty(hasControlChars)
            charRHS = char(validRHS);
            controlChars = (charRHS <= 31 | charRHS == 127);
            intControlChars = int64(unique(charRHS(controlChars)));
            for i=1:length(intControlChars)
                if char(intControlChars(i)) == newline
                    validRHS = strrep(validRHS, char(intControlChars(i)), """ + newline + """);
                else
                    validRHS = strrep(validRHS, char(intControlChars(i)), """ + char(" + intControlChars(i) + ") + """);
                end
            end
        end
        validRHS = validRHS + '"';
        subsExpr = ".Properties.VariableNames(" + num2str(ind) + ")";
        varNameExpr = varNameExpr + subsExpr + " = " + validRHS;
    end
end
