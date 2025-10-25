function [varNameExpr, subsExpr, validRHS] = generateVariableNameAssignmentString(t, subs, vname, tname)
%   GENERATEVARIABLENAMEASSIGNMENTSTRING generates a variable name assignment
%   In most cases the RHS is the same as the input string but for cases
%   where there are control characters or quotes the output name will be
%   formatted into valid MATLAB syntax

%   Copyright 2019-2024 The MathWorks, Inc.
arguments
    t
    subs
    vname string
    tname char
end
    varNameExpr = tname;

    if ~isa(t,'tabular')
        error(message('MATLAB:tabular:InvalidInput'))
    end

    ind = subscripts2indices(t,subs,'assignment','varDim');
    if ~isscalar(ind)
        error(message('MATLAB:tabular:MultipleSubscripts'));
    end

    oldName = t.Properties.VariableNames(ind);
    oldName = getValidCommandLineName(oldName);
    newName = getValidCommandLineName(vname);

    validRHS = "renamevars(" + varNameExpr + ", " + oldName + ", " + newName + ")";
    subsExpr = newName;
    varNameExpr = varNameExpr + " = " + validRHS;

    varNameExpr = char(varNameExpr);
end


function cmdName = getValidCommandLineName(vname)
    % Escape any "" as this will generate string syntax
    cmdName = strrep(vname, '"', '""');
    cmdName = """" + cmdName; % Wrap in quotes for RHS assignment    

    hasControlChars = find((char(vname)<=31 | char(vname)==127), 1);
    if ~isempty(hasControlChars)
       charRHS = char(cmdName);
       controlChars = (char(cmdName)<=31 | char(cmdName)==127);
       intControlChars = int64(unique(charRHS(controlChars)));
       for i=1:length(intControlChars)
           if char(intControlChars(i)) == newline                    
                cmdName = strrep(cmdName, char(intControlChars(i)), """ + newline + """);                      
           else
                cmdName = strrep(cmdName, char(intControlChars(i)), """ + char(" + intControlChars(i) + ") + """);
           end
           cmdName = strrep(cmdName, char(intControlChars(i)), """ + newline + """); 
       end
    end
    cmdName = cmdName + """";
    % return validRHS in char
    cmdName = char(cmdName);
end