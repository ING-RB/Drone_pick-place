classdef OpenSelectionAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles opening variableeditor on the current cell
    % selection for cell arrays.

    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'OpenSelection'
    end  
    
    methods
        function this = OpenSelectionAction(props, manager)            
           props.ID = internal.matlab.variableeditor.Actions.dataTypes.OpenSelectionAction.ActionName;           
           props.Enabled = true;
           this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
           this@internal.matlab.variableeditor.VEAction(props, manager);
        end
        
        % When there is a plaid selection with > 1 cells, do not enable
        % this action.
        function UpdateActionState(this)
            focusedDoc = this.Manager.FocusedDocument;
            if ~isempty(focusedDoc) && isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.ArrayViewModel')
                selection = focusedDoc.ViewModel.getSelection();
                this.Enabled = isscalar(unique(selection{1})) && ...
                    isscalar(unique(selection{2}));
            end
        end
    end
    
    methods(Access='protected')
        
        % Generates openvar command to open current cell selected and
        % executes the command directly without publishing codegen.
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, ~)
           selection = focusedDoc.ViewModel.getSelection;
           row = selection{1};
           col = selection{2};
           cmd = '';
           executionCmd = '';
           openvarCmd = sprintf('openvar %s{%d,%d};', focusedDoc.Name, row(1), col(2));
           this.executeCommand(openvarCmd);
        end
        
        function executeCommand(~, callbackCmd)            
            internal.matlab.variableeditor.Actions.ActionUtils.executeCommand(callbackCmd);
        end
    end
end

