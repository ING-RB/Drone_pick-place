classdef OpenvarAction < internal.matlab.variableeditor.VEAction
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles opening variable name sepcified in ActionInfo
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'VariableEditor.open'
    end  
    
    methods
        function this = OpenvarAction(props, manager)            
           props.ID = internal.matlab.variableeditor.Actions.dataTypes.OpenvarAction.ActionName;           
           props.Enabled = true;            
           this@internal.matlab.variableeditor.VEAction(props, manager);
           this.Callback = @this.handleOpenvar;

        end
        
        % The Action is always available, no need to update Enabled.
        function UpdateActionState(~)
        end
    end
    
    methods(Access='protected')
        
        % Generates openvar command to open document in variable editor. If
        % multiple variables exist, chain the openvar commands to open all
        % variables sequentially.
        function cmd = handleOpenvar(this, actionInfo)
           arguments
               this
               actionInfo = struct            
           end
           import internal.matlab.variableeditor.Actions.ActionUtils;
           if isfield(actionInfo, 'Name')
               varName =  actionInfo.Name;
           else
               varName = this.veManager.FocusedDocument.Name; 
           end
           % If delimiter is passed in, use that. We could have nested objs
           % and struct variables like <val1(1,1).prop1>
           delimiter = ',';
           if isfield(actionInfo, 'delimiter')
               delimiter = ', ';
           end
           varNamesList = strip(string(varName).split(delimiter));
           cmd = '';
           for i=1:length(varNamesList)
              cmd = [cmd sprintf('openvar(''%s'');', varNamesList(i))];
           end           
           internal.matlab.variableeditor.Actions.ActionUtils.executeCommand(cmd);
        end
    end
end

