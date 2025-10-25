classdef WorkspaceFieldSettings < internal.matlab.variableeditor.FieldColumns.StructFieldSettings
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This static handle class provides workspacebrowser settings for
    % columns. Settings being used: 
    % s.matlab.desktop.workspace.statisticalcalculations
    % s.matlab.desktop.workspace.columns

    % Copyright 2020 The MathWorks, Inc.
   
    properties
        WorkspaceBrowserUseNaNs logical;
        WorkspaceBrowserStatNumelLimit double;
    end
    
    methods
        function useNanValue = getUseNanSetting(this)
            useNanValue = this.WorkspaceBrowserUseNaNs;
        end
        
        function numelLimit = getStatNumelLimitSetting(this)
            numelLimit = this.WorkspaceBrowserStatNumelLimit;
        end
    end
    
    methods(Access='protected')
         function initStatSettings(this)
            s = settings;
            this.SettingsRoot = s.matlab.desktop.workspace;
            this.WorkspaceBrowserUseNaNs = this.SettingsRoot.statisticalcalculations.WorkspaceBrowserUseNaNs.ActiveValue; 
            this.WorkspaceBrowserStatNumelLimit = this.SettingsRoot.statisticalcalculations.WorkspaceBrowserStatNumelLimit.ActiveValue;
         end
        
        function colWidthSetting = getColWidthSetting(this)
            colWidthSetting = this.SettingsRoot.columns.ColumnWidths;
        end
        
        function visibilitySetting = getColumnVisibleSetting(this)
            visibilitySetting = this.SettingsRoot.columns.ColumnsShown;
        end
        
        function columnOrder = getColumnOrderSetting(this)
            columnOrder = this.SettingsRoot.columns.ColumnOrder;
        end
    end
    
    methods(Static)
        function obj = getInstance()
            mlock; % Keep persistent variables until MATLAB exits
            persistent wsbsettingsInstance;            
            if isempty(wsbsettingsInstance) || ~isvalid(wsbsettingsInstance)
                wsbsettingsInstance = internal.matlab.desktop_workspacebrowser.FieldColumns.WorkspaceFieldSettings;
                wsbsettingsInstance.createSettingsCache();
            end
            obj = wsbsettingsInstance;
        end
    end
end

