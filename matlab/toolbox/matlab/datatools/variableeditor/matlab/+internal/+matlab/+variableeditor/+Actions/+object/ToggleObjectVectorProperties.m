classdef ToggleObjectVectorProperties < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles showing and hinding all properties in an object vector display.

    % Copyright 2023 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'ShowAllProperties';
    end
    
    methods
        function this = ToggleObjectVectorProperties(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.object.ToggleObjectVectorProperties.ActionName;           
            props.Enabled = true;
            props.CheckedActionEnabled = jsonencode(struct('ShowAllProperties', false));
            areAllPropertiesVisible = true;
            focusedDoc = manager.FocusedDocument;
            if ~isempty(focusedDoc) && ~isempty(focusedDoc.DataModel) && isprop(focusedDoc.DataModel, 'ShowAllProperties')
                areAllPropertiesVisible = focusedDoc.DataModel.ShowAllProperties;
            end
            props.Checked = jsonencode(struct('ShowAllProperties', areAllPropertiesVisible));
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Checked = jsonencode(struct('ShowAllProperties', areAllPropertiesVisible));
        end

        function toggleEnabledState(this, isEnabled)   
            focusedDoc = this.Manager.FocusedDocument;
            if ~isempty(focusedDoc) && ~isempty(focusedDoc.DataModel) && isprop(focusedDoc.DataModel, 'ShowAllProperties')
                totalPropertyCount = height(properties(focusedDoc.DataModel.Data));
                visiblePropertyCount = height(focusedDoc.DataModel.getProperties(focusedDoc.DataModel.Data, false));

                areAllPropertiesVisible = focusedDoc.DataModel.ShowAllProperties || totalPropertyCount == 1;
                this.Checked = jsonencode(struct('ShowAllProperties', areAllPropertiesVisible));

                enabled = isEnabled && (totalPropertyCount ~= visiblePropertyCount);
            else
                enabled= false;
            end

            this.Enabled = enabled;
            this.CheckedActionEnabled = jsonencode(struct('ShowAllProperties', enabled));
        end
    end
    
    methods(Access='protected')       
       
        % This action is only supported for consecutive groupable columns
        % or a single ungroupable column. In addition to codegen, selection
        % is updated asynchronously once the table is grouped/ungrouped.
        function [cmd, callbackCmd] = generateCommandForAction(this, ~, ~)
            cmd = "";
            callbackCmd = "";
            focusedDoc = this.Manager.FocusedDocument;
            if ~isempty(focusedDoc) && ~isempty(focusedDoc.DataModel) && isprop(focusedDoc.DataModel, 'ShowAllProperties')
                areAllPropertiesVisible = ~focusedDoc.DataModel.ShowAllProperties;
                focusedDoc.DataModel.ShowAllProperties = areAllPropertiesVisible;
                this.Checked = jsonencode(struct('ShowAllProperties', areAllPropertiesVisible));
                focusedDoc.ViewModel.setSelection([],[]);
            end
        end
    end
end


