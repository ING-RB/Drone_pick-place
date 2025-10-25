classdef ShowStatisticsAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles grouping and ungrouping table column variables.

    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'ShowStatistics';
    end
    
    methods
        function this = ShowStatisticsAction(props, manager)           
            props.ID = internal.matlab.variableeditor.Actions.table.ShowStatisticsAction.ActionName;           
            props.Enabled = true;
            s = settings;
            areStatisticsEnbled = s.matlab.desktop.variables.statistics.ShowStatistics.ActiveValue;
            props.Checked = jsonencode(struct('ShowStatistics', areStatisticsEnbled));
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Checked = jsonencode(struct('ShowStatistics', areStatisticsEnbled));
        end           
    end
    
    methods(Access='protected')       
       
        % This action is only supported for consecutive groupable columns
        % or a single ungroupable column. In addition to codegen, selection
        % is updated asynchronously once the table is grouped/ungrouped.
        function [cmd, callbackCmd] = generateCommandForAction(this, ~, ~)
            cmd = string.empty;
            callbackCmd = string.empty;
            s = settings;
            areStatisticsEnbled = s.matlab.desktop.variables.statistics.ShowStatistics.ActiveValue;
            areStatisticsEnbled = ~areStatisticsEnbled;
            s.matlab.desktop.variables.statistics.ShowStatistics.PersonalValue = areStatisticsEnbled;
            this.Checked = jsonencode(struct('ShowStatistics', areStatisticsEnbled));
        end
    end
end
