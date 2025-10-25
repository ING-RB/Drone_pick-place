classdef Constants
    %CONSTANTS contains constant properties for the Write Section View and
    %Controller classes

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Constant)
        %% Columns
        % In general, a toolstrip column contains toolstrip UI elements
        % that are displayed one below the other (stacked vertically).

        % These column properties contain the width and alignment
        % information for each toolstrip column, which affects the
        % underlying UI elements' width and alignment.

        EmptyColumn = ...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareEmptyToolstripColumn()

        BufferColumn = ...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareToolstripColumn(4, "left")

        WriteColumn = [...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareToolstripColumn(70, "right"), ...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareToolstripColumn(80, "center"), ...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareToolstripColumn(100, "left"), ...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareToolstripColumn(200, "left"), ...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareToolstripColumn( ...
                matlabshared.transportapp.internal.toolstrip.Manager.ButtonWidth, ...
                matlabshared.transportapp.internal.toolstrip.Manager.ButtonAlignment) ...
            ]

        %% Precision Constants
        NumericPrecision = ["uint8", "int8", "uint16", "int16", "uint32", "int32", "uint64", "int64", "single", "double"]
        ASCIITerminatedPrecision = "string"
        AllPrecision = [matlabshared.transportapp.internal.toolstrip.write.Constants.NumericPrecision, ...
            "char", ...
            matlabshared.transportapp.internal.toolstrip.write.Constants.ASCIITerminatedPrecision]

        %% Section Names
        WriteSectionName = message("transportapp:toolstrip:write:WriteSectionName").getString

        %% Label Names
        DataFormatLabel = message("transportapp:toolstrip:write:DataFormatLabel").getString
        DataTypeLabel = message("transportapp:toolstrip:write:DataTypeLabel").getString
        CustomDataLabel = message("transportapp:toolstrip:write:CustomDataLabel").getString
        WorkspaceVariableLabel = message("transportapp:toolstrip:write:WorkspaceVariableLabel").getString
        WriteButtonLabel = message("transportapp:toolstrip:write:WriteButtonLabel").getString

        %% Tooltip Messages
        DataFormatTooltip = message("transportapp:toolstrip:write:DataFormatTooltip").getString
        DataTypeTooltip = message("transportapp:toolstrip:write:DataTypeTooltip").getString
        CustomDataTooltip = message("transportapp:toolstrip:write:CustomDataTooltip").getString
        WorkspaceVariableTooltip = message("transportapp:toolstrip:write:WorkspaceVariableTooltip").getString
        WriteButtonTooltip = message("transportapp:toolstrip:write:WriteButtonTooltip").getString

        %% Column1 Elements
        DataFormatLabelProps = struct("Text", matlabshared.transportapp.internal.toolstrip.write.Constants.DataFormatLabel, ...
            "Description", matlabshared.transportapp.internal.toolstrip.write.Constants.DataFormatTooltip)

        DataTypeLabelProps = struct("Text", matlabshared.transportapp.internal.toolstrip.write.Constants.DataTypeLabel, ...
            "Description", matlabshared.transportapp.internal.toolstrip.write.Constants.DataTypeTooltip)

        %% Column2 Elements
        DataFormatDropDownOptions = ["Binary", "ASCII-Terminated String"]
        DataFormatDropDown = struct("Value", matlabshared.transportapp.internal.toolstrip.write.Constants.DataFormatDropDownOptions(1), ...
            "Tag", 'WriteDataFormatDropDown')

        DataTypeDropDownOptions = matlabshared.transportapp.internal.toolstrip.write.Constants.AllPrecision;
        DataTypeDropDown = struct("Value", matlabshared.transportapp.internal.toolstrip.write.Constants.DataTypeDropDownOptions(1), ...
            "Description", matlabshared.transportapp.internal.toolstrip.write.Constants.DataTypeTooltip, ...
            "Tag", 'WriteDataTypeDropDown')

        %% Column3 Elements
        CustomDataButton = struct("Text", matlabshared.transportapp.internal.toolstrip.write.Constants.CustomDataLabel, ...
            "Value", true, ...
            "Description", matlabshared.transportapp.internal.toolstrip.write.Constants.CustomDataTooltip, ...
            "Tag", 'WriteEnterDataButton')

        WorkspaceVariableButton = struct("Text", matlabshared.transportapp.internal.toolstrip.write.Constants.WorkspaceVariableLabel, ...
            "Value", false, ...
            "Description", matlabshared.transportapp.internal.toolstrip.write.Constants.WorkspaceVariableTooltip, ...
            "Tag", 'WriteWorkspaceVarButton')

        %% Column4 Elements
        CustomDataEditField = struct("Description", matlabshared.transportapp.internal.toolstrip.write.Constants.CustomDataTooltip, ...
            "Tag", 'WriteEnterDataEditField')

        WorkspaceVariableDropdown = struct("Enabled", false, ...
            "Description", matlabshared.transportapp.internal.toolstrip.write.Constants.WorkspaceVariableTooltip, ...
            "Tag", 'WriteWorkspaceVarDropDown');
        WorkspaceVariableDropdownTypes = {["Char", "String", "Numeric"], ["Char", "String"]}

        %% Column5 Elements
        WriteButton = struct("Text", matlabshared.transportapp.internal.toolstrip.write.Constants.WriteButtonLabel, ...
            "Icon", matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("ict", "Write"), ...
            "Description", matlabshared.transportapp.internal.toolstrip.write.Constants.WriteButtonTooltip, ...
            "Enabled", true, ...
            "Tag", 'WriteButton')

        %% Other Constants
        WorkspaceCleared = "WORKSPACE_CLEARED"
        VariableDeleted = "VARIABLE_DELETED"
        VariableChanged = "VARIABLE_CHANGED"
        VariableAdded = "VARIABLE_ADDED"
    end
end
