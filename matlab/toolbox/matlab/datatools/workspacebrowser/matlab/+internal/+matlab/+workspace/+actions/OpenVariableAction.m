classdef OpenVariableAction < internal.matlab.variableeditor.Actions.struct.OpenAction    
    % Open selected variables in workspacebroswer
    
    % Copyright 2017-2024 The MathWorks, Inc. 
    
    properties (Constant)
        ActionType = 'WorkspaceBrowser.open'
    end
    
    methods
        function this = OpenVariableAction(props, manager)
            props.ID = internal.matlab.workspace.actions.OpenVariableAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.struct.OpenAction(props, manager);            
        end       
    end
    
    methods(Access = protected)
        % Open Variable and force command execution.
        function openVariable(this, ed, ~)
            arguments
                this
                ed = struct
                ~
            end
            this.openVariable@internal.matlab.variableeditor.Actions.struct.OpenAction(ed, true);
        end
            
        function [cmd, editorCmd]  = getOpenvarCommand(~, selectedField, ~)
            % pass in second argument as variable to openvar for objects
            % that have custom dialog/open behavior.
            openvarcmd = "openvar('%s', %s);";
            editorCmd = "";
            cmd = sprintf(openvarcmd, selectedField, selectedField);
        end
    end
end

