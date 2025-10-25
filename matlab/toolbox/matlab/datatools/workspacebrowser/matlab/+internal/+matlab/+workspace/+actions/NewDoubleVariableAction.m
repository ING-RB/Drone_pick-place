classdef NewDoubleVariableAction < internal.matlab.variableeditor.VEAction
    % NewDoubleVariableAction
    % Create a new unnamed variable in workspacebroswer
    
    % Copyright 2017-2025 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'WorkspaceBrowser.new'
    end
    
    methods
        function this = NewDoubleVariableAction(props, manager)
            props.ID = internal.matlab.workspace.actions.NewDoubleVariableAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.NewDoubleVariable;
        end
        
        function NewDoubleVariable(this)
            % get the right variable name that we can use
            % create a new variable with the right name we get
            s = evalin("debug", "who");
            cmd = this.getCommandForNewDouble(s);
            this.executeInWebWorker(cmd);
        end
        
        function cmd = getCommandForNewDouble(~, fields)
            defaultvalue = 0;
            newUniqueName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName('unnamed', fields);
            newcmd = "eval(['%s' ' = " + defaultvalue + ";']);";
            cmd = sprintf(newcmd, newUniqueName);
        end
        
        function UpdateActionState(~)
        end
    end
    
    methods(Access = protected)
        function executeInWebWorker(~, cmd)
            internal.matlab.datatoolsservices.executeCmd(cmd);
        end
    end
end

