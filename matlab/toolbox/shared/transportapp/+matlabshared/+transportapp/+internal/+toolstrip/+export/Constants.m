classdef Constants
    %CONSTANTS contains View and Controller constant properties for the
    %toolstrip Export section

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

        ExportColumns = [...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareToolstripColumn(110, "left"), ...
            matlabshared.transportapp.internal.toolstrip.Manager.prepareToolstripColumn( ...
                matlabshared.transportapp.internal.toolstrip.Manager.ButtonWidth, ...
                matlabshared.transportapp.internal.toolstrip.Manager.ButtonAlignment) ...
            ]

        %% Section Names
        ExportSectionName = message("transportapp:toolstrip:export:ExportSectionName").getString

        %% Label Names
        WorkspaceVariableLabel = message("transportapp:toolstrip:export:WorkspaceVariableLabel").getString
        ExportButtonLabel = message("transportapp:toolstrip:export:ExportButtonLabel").getString
        ExportSelectedRowLabel = message("transportapp:toolstrip:export:SelectedRowButtonLabel").getString
        ExportCommLogLabel = message("transportapp:toolstrip:export:CommTableButtonLabel").getString
        ExportCodeLabel = message("transportapp:toolstrip:export:MatlabCodeButtonLabel").getString

        %% Description
        WorkspaceVariableTooltip = message("transportapp:toolstrip:export:WorkspaceVariableTooltip").getString
        ExportButtonDescription = message("transportapp:toolstrip:export:ExportButtonTooltip").getString
        ExportSelectedRowDescription = message("transportapp:toolstrip:export:SelectedRowButtonDescription").getString
        ExportCommLogDescription = message("transportapp:toolstrip:export:CommTableButtonDescription").getString
        ExportCodeDescription = message("transportapp:toolstrip:export:MatlabCodeButtonDescription").getString

        %% Column1 Elements
        WorkspaceVariableLabelProps = struct("Text", matlabshared.transportapp.internal.toolstrip.export.Constants.WorkspaceVariableLabel, ...
            "Description", matlabshared.transportapp.internal.toolstrip.export.Constants.WorkspaceVariableTooltip)

        WorkspaceVariableEditFieldProps = ...
            struct("Description", matlabshared.transportapp.internal.toolstrip.export.Constants.WorkspaceVariableTooltip, ...
            "Tag", 'ExportWSVar')

        %% Column2 Elements
        ExportButtonProps = struct("Text", matlabshared.transportapp.internal.toolstrip.export.Constants.ExportButtonLabel, ...
            "Icon", matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("ict", "ExportButton"), ...
            "Description", matlabshared.transportapp.internal.toolstrip.export.Constants.ExportButtonDescription, ... 
            "Enabled", true, ...
            "Tag", 'ExportButton')

        ExportSelectedRowListProps = struct("Text", matlabshared.transportapp.internal.toolstrip.export.Constants.ExportSelectedRowLabel, ...
            "Icon", matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("ict", "ExportRow"), ...
            "Description", matlabshared.transportapp.internal.toolstrip.export.Constants.ExportSelectedRowDescription, ... 
            "Enabled", true, ...
            "Tag", 'ExportRowButton')

        ExportCommLogListProps = struct("Text", matlabshared.transportapp.internal.toolstrip.export.Constants.ExportCommLogLabel, ...
            "Icon", matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("ict", "ExportTable"), ...
            "Description", matlabshared.transportapp.internal.toolstrip.export.Constants.ExportCommLogDescription, ...
            "Enabled", true, ...
            "Tag", 'ExportCommLogButton')

        ExportCodeListProps = struct("Text", matlabshared.transportapp.internal.toolstrip.export.Constants.ExportCodeLabel, ...
            "Icon", matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("ict", "ExportScript"), ...
            "Description", matlabshared.transportapp.internal.toolstrip.export.Constants.ExportCodeDescription, ...
            "Enabled", true, ...
            "Tag", 'ExportCodeLogButton')

        %% Other Constants
        WorkspaceCleared = "WORKSPACE_CLEARED"
        VariableDeleted = "VARIABLE_DELETED"
        VariableChanged = "VARIABLE_CHANGED"
        VariableAdded = "VARIABLE_ADDED"

        VariableNameSuffix = "_data"
    end
end
