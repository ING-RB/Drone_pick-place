classdef StructFieldSettings < handle
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This static handle class provides struct settings for Struct Field
    % columns. The value of these settings are up-to-date with user's
    % preferences.Settings being used: 
    % s.matlab.desktop.variables.statisticalcalculations
    % s.matlab.desktop.variables.structcolumns

    % Copyright 2024 The MathWorks, Inc.
    
    properties
        StatUseNaNs logical;
        StatNumelLimit double;
    end
    
    properties(Access='protected')
        SettingsRoot;
        StatSettingChangeListener;
    end

    properties(Access='private')
        ColumnWidths;
        ColumnOrder;
        ColumnVisible;
    end
    
     events
        StatSettingChange;  % Emitted whenever settings that affect stat columns change
     end
    
    methods
        function createSettingsCache(this)
            this.ColumnWidths = this.getColWidthSetting().ActiveValue;
            this.ColumnVisible = this.getColumnVisibleSetting().ActiveValue;
            this.ColumnOrder = this.getColumnOrderSetting().ActiveValue;
        end

        function visibleCols = getVisibleCols(this)
            visibleCols = this.ColumnVisible;
        end

        function useNanValue = getUseNanSetting(this)
            useNanValue = this.StatUseNaNs;
        end
        
        function numelLimit = getStatNumelLimitSetting(this)
            numelLimit = this.StatNumelLimit;
        end
        
        % Gets ColumnWidth from Settings 
        function colWidth = getColumnWidth(this, columnIndex)
            colWidth = this.ColumnWidths(columnIndex);
        end
        
        % Sets new columnWidth to 'ColumnWidths' settings
        function setColumnWidth(this, columnIndex, columnWidth)
            colWidthSettings = this.getColWidthSetting();
            if ~colWidthSettings.hasPersonalValue
                colWidthSettings.PersonalValue = colWidthSettings.ActiveValue;
            end
            colWidthSettings.PersonalValue(columnIndex) = columnWidth;
            this.ColumnWidths = colWidthSettings.PersonalValue;
        end
        
        % returns boolean based on whether the column (columnName) is visible or not by looking up
        % settings.
        function isVisible = getColumnVisibility(this, columnName)
            isVisible = any(strcmp(this.ColumnVisible, columnName));
        end
        
        % If column by columnName is already visible and isVisible= true, return. 
        % If isVisible, add to ColumnsShown settings. 
        % Else, remove from ColumnsShown settings
        function setColumnVisibility(this, columnName, isVisible)
            setting = this.getColumnVisibleSetting();
            if ~setting.hasPersonalValue
                setting.PersonalValue = setting.ActiveValue;
            end
            idx = strcmp(setting.ActiveValue, columnName);
            if isVisible
                % If visible is set again, ignore and return;
                if any(idx)
                    return;
                end
                setting.PersonalValue = [setting.PersonalValue columnName];
            else
                setting.PersonalValue(idx) = [];            
            end
            this.ColumnVisible = setting.PersonalValue;
        end
        
        % Gets the ColumnOrder for columnName in which the column is displayed
        function columnOrder = getColumnOrder(this, columnName)
            columnOrder = find(strcmp(this.ColumnOrder, columnName));
        end
        
        % For given columnName, re-order in the existing ColumnOrder. 
        function setColumnOrder(this, columnName, order)
            setting = this.getColumnOrderSetting();
            if ~setting.hasPersonalValue
                setting.PersonalValue = setting.ActiveValue;
            end
            val = setting.ActiveValue;
            val(strcmp(val, columnName)) = [];
            setting.PersonalValue = [val(1:order-1) columnName val(order:end)];
            this.ColumnOrder = setting.PersonalValue;
        end
    end
    
    methods(Access='protected')
        function this = StructFieldSettings()       
            this.initStatSettings();
            this.StatSettingChangeListener = message.subscribe('/StatsSettingChange', @(x)this.handleSettingsChanged(x), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
        end
        
        function initStatSettings(this)
            s = settings;
            this.SettingsRoot = s.matlab.desktop.variables;
            this.StatUseNaNs = this.SettingsRoot.statisticalcalculations.StatUseNaNs.ActiveValue; 
            this.StatNumelLimit = this.SettingsRoot.statisticalcalculations.StatNumelLimit.ActiveValue;
            this.StatSettingChangeListener = message.subscribe('/StatsSettingChange', @(x)this.handleSettingsChanged(x), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
        end
        
        function colWidthSetting = getColWidthSetting(this)
            colWidthSetting = this.SettingsRoot.structcolumns.ColumnWidths;
        end
        
        function visibilitySetting = getColumnVisibleSetting(this)
            visibilitySetting = this.SettingsRoot.structcolumns.ColumnsShown;
        end
        
        function columnOrder = getColumnOrderSetting(this)
            columnOrder = this.SettingsRoot.structcolumns.ColumnOrder;
        end
    end

    methods (Access=?matlab.unittest.TestCase)
        % Update settings based on incoming changes. NOTE: The settings API
        % already has validators for these settings.
        function handleSettingsChanged(this, event)
            propName = event.name;
            if (isprop(this, propName))
                this.(propName) = event.newValue;
                this.notify('StatSettingChange');
            end
        end
    end
    
    methods(Static)
        function obj = getInstance()
            mlock; % Keep persistent variables until MATLAB exits
            persistent settingsInstance;            
            if isempty(settingsInstance) || ~isvalid(settingsInstance)
                settingsInstance = internal.matlab.variableeditor.FieldColumns.StructFieldSettings;
                settingsInstance.createSettingsCache();
            end
            obj = settingsInstance;
        end
    end
end

