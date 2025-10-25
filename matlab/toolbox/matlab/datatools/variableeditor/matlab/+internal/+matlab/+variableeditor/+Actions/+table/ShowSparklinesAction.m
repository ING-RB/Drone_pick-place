classdef ShowSparklinesAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles grouping and ungrouping table column variables.

    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'ShowSparklines';
    end
    
    methods
        function this = ShowSparklinesAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.table.ShowSparklinesAction.ActionName;           
            props.Enabled = true;
            s = settings;
            areSparklinesEnabled = s.matlab.desktop.variables.sparklines.ShowSparklines.ActiveValue;
            props.Checked = jsonencode(struct('ShowSparklines', areSparklinesEnabled));
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Checked = jsonencode(struct('ShowSparklines', areSparklinesEnabled));
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
            areSparklinesEnabled = s.matlab.desktop.variables.sparklines.ShowSparklines.ActiveValue;
            areSparklinesEnabled = ~areSparklinesEnabled;
            s.matlab.desktop.variables.sparklines.ShowSparklines.PersonalValue = areSparklinesEnabled;
            this.Checked = jsonencode(struct('ShowSparklines', areSparklinesEnabled));
        end
    end
end


