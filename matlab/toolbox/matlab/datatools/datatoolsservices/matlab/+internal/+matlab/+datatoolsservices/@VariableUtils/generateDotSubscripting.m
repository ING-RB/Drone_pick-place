% returns the dot subscripting sctring given the table name and the variable
% name. The utility is needed since the subscripting is different based on the
% format of the variable name Ex: tableName = 't', varName = 'col', result =
% t.col tableName = 't',varName = 'col 1', result = t.('col 1')

% Copyright 2020-2022 The MathWorks, Inc.

function result = generateDotSubscripting(tableName, varName, tableData)
    if isvarname(varName)
        % This is a valid variable name, index like:  t.A
        varIndex = varName;
    elseif isempty(find((char(varName)<=31 | char(varName)==127), 1))
        % This is an arbitrary variable name, but has printable characters, so
        % index like:  t.('#')
        varIndex = "('" + varName + "')";
    else
        % This is an arbitrary variable name, but has unprintable characters.
        % Index like:  t.(2)
        colNum = find(contains(tableData.Properties.VariableNames, varName));
        varIndex = "(" + colNum + ")";
    end
    result = tableName + "." + varIndex;
end