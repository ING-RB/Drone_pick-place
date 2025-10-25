classdef TransposeAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles transpose action on datatypes.

    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'Transpose'
    end  
    
    methods
        function this = TransposeAction(props, manager)            
           props.ID = internal.matlab.variableeditor.Actions.dataTypes.TransposeAction.ActionName;           
           props.Enabled = true;
           this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
           this@internal.matlab.variableeditor.VEAction(props, manager);
           this.SupportedInInfintieGrid = true;
        end
        
        % Turn transposeAction on only when there is a numeric view on the
        % FocusedDocument.
        function toggleEnabledState(this, isEnabled)
            if isEnabled
                focusedDoc = this.Manager.FocusedDocument;
                data = focusedDoc.DataModel.Data;
                if isprop(focusedDoc.DataModel, 'DataI')
                    data = focusedDoc.DataModel.DataI;
                end
                isEnabled = ~isa(data, 'table') && ~isa(data, 'timetable') && ~isa(data, 'dataset') && ismatrix(data) && ...
                ~(isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.ObjectViewModel'));
            end
            this.Enabled = isEnabled;
        end
    end
    
    methods(Access='protected')
        
        % generates command for transpose action. This code is common for
        % all supported array like types
        % Supported types: numeric/ logical/ cell arrays/ nxn struct arrays
        % and nxn object arrays.
        function [cmd, executionCmd] = generateCommandForAction(~, focusedDoc, ~) 
           executionCmd = '';
           cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorTransposeCode(...
                focusedDoc.Name);
        end
    end
end

