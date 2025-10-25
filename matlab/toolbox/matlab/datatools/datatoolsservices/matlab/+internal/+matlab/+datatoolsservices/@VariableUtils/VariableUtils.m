classdef VariableUtils
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % VariableUtils is internal class that provides variable utility APIs
    % for datatools related UIs

    % Copyright 2020-2025 The MathWorks, Inc.

    properties (Constant)
        PREDEFINED_WORKSPACE_NAMES = ["base", "caller", "debug"];
        MAX_STR_LENGTH_FOR_MESSAGE = 60;
    end

    methods(Static)
        channel = createCodePublishingChannel(namespace, channelSuffix);
        createUniqueVariable(workspace);
        tb = convertDatasetToTable(ds);
        result = generateDotSubscripting(tableName, varName, tableData);
        new = generateUniqueName(varName, variableNameList, prefixName);
        startColumnIndexes = getColumnStartIndicies(data);
        [saveFileName, filterIndex] = getSaveVarsFileName();
        truncID = getTruncatedIdentifier(id);
        new = getVarNameForCopy(varname, fields);
        isOfType = isContainerType(data);
        result = isCustomCharWorkspace(ws);
        isTrue = isNumericObject(val);
        isTrue = isPrimitiveNumeric(val);
        result = localAlreadyExists(name, who_output);
        saveWorkspace();
        b = variablesExistInWorkspace(varNames);
    end
end

