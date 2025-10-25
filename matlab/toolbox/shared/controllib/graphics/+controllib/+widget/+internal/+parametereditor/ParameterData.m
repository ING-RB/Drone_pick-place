classdef ParameterData < matlab.mixin.SetGet
    % ParameterData
    %   Class to manage parameter data (param.Continuous) and use with
    %   ParameterEditorPanel
    %    
    % Use a variable name and variable value, or a variable name and
    % workspace to construct the panel.
    %
    % Construction:
    %
    %   import controllib.widget.internal.parametereditor.*;
    %   data = ParameterData("G",param.Continuous('P',[0.00123 3.1212 5.23423 1.2323]));
    %   data = ParameterData("G","Workspace","base");
    %   data = ParameterData("G","Workspace",localWorkspaceObject);
    %
    % Update:
    %
    %   data.Value = [1 2 3];
    %   data.Minimum = [-Inf 0 -Inf];
    %   data.Maximum = [0 Inf Inf];
    %   data.Free = [true false true]

    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties(Dependent,SetObservable,AbortSet)
        % Name of variable being edited
        ParameterName
        % Name property of parameter
        Name
        % Value property of parameter
        Value
        % Minimum property of parameter
        Minimum
        % Maximum property of parameter
        Maximum
        % Scale property of parameter
        Scale
        % Free property of parameter
        Free
    end

    properties(GetAccess = public, SetAccess = protected)
        % Workspace where variable resides
        Workspace
        % WorkspaceType ("Local" | "Base" | "None")
        %   Indicates the type of workspace used by client. Changing
        %   variable value or name will also change the corresponding
        %   variable in the workspace
        WorkspaceType
    end

    properties(GetAccess = protected, SetAccess = protected)
        % Handle of the parameter variable being edited
        Parameter
        % Variable Name Internal
        VariableNameInternal
        % Base Workspace Listener
        BaseWorkspaceListener
    end

    events
        ParameterChanged
    end
    
    %% Public Methods
    methods
        function this = ParameterData(variableName,variableValue,optionalArguments)
            arguments
                variableName
                variableValue = []
                optionalArguments.Workspace = "base"
            end
            % Variable Name (assign to internal property)
            this.VariableNameInternal = string(variableName);
            if ~isempty(variableValue)
                % Create local workspace
                this.Workspace = matlab.internal.datatoolsservices.AppWorkspace;
                assignin(this.Workspace,variableName,variableValue);
                this.Parameter = variableValue;
                this.WorkspaceType = "None";
            else
                this.Workspace = optionalArguments.Workspace;
                if strcmpi(this.Workspace,"base")
                    this.WorkspaceType = "Base";
                else
                    this.WorkspaceType = "Local";
                end
            end
            % Assign parameter from variable name and workspace
            if strcmp(this.Workspace,"base")
                % From base workspace
                this.Parameter = evalin("base",this.ParameterName+";");
%                 addBaseWorkspaceListener(this);
            else
                % From local workspace
                this.Parameter = this.Workspace.(this.ParameterName);
            end
        end

        function delete(this)
            delete(this.BaseWorkspaceListener);
        end

        function name = getParameterName(this)
            name = this.Parameter.Name;
        end

        function value = getValue(this,what)
            %GETVALUE
            %
            %    value = getValue(obj,[field])
            %
            %    Return the value of the 'field' property of the edited
            %    parameter. If the optional 'field' is omitted the parameter
            %    is returned.
            

            if nargin < 2
                %Return the parameter object
                value = this.Parameter;
            else
                this.Parameter.(what);
            end
        end

        function setParameterField(this,what,value)
            %SETVALUE
            %
            %    setParameterField(obj,field,value)
            %
            %    Set the field property of ParameterEditorTC.Parameter to
            %    the specified value.
            %

            if isempty(this.Parameter)
                error(message('Controllib:general:UnexpectedError','SetValue cannot be used when there is no Parameter'))
            else
                this.Parameter.(what) = value;
            end
        end

        function Text = generateMATLABCode(this, default, variableName)
            arguments
                this
                default
                variableName char = ''
            end
            actual = getValue(this);
            Text = cell(0,1);
            ValueCode = getParameterFieldCode(this,'Value',variableName);
            Text = controllib.internal.codegen.appendMATLABCode(Text, ValueCode);
            if any(default.Minimum ~= actual.Minimum)
%                 MinCode = [sprintf('%s.Minimum',this.ParameterName) ' = ', mat2str(MetaData.Minimum), ';'];
                MinCode = getParameterFieldCode(this,'Minimum',variableName);
                Text = controllib.internal.codegen.appendMATLABCode(Text, MinCode);
            end
            if any(default.Maximum ~= actual.Maximum)
                MaxCode = getParameterFieldCode(this,'Maximum',variableName);
                Text = controllib.internal.codegen.appendMATLABCode(Text, MaxCode);
            end
            if any(default.Scale ~= actual.Scale)
                ScaleCode = getParameterFieldCode(this,'Scale',variableName);
                Text = controllib.internal.codegen.appendMATLABCode(Text, ScaleCode);
            end
            if any(default.Free ~= actual.Free)
                FreeCode = getParameterFieldCode(this,'Free',variableName);
                Text = controllib.internal.codegen.appendMATLABCode(Text, FreeCode);
            end
        end

        function MetaData = getMetaData(this)
            MetaData.Value = this.Value;
            if isempty(MetaData.Value)
                MetaData.Value = mat2str(this.Parameter.Value);
            end
            MetaData.Minimum = this.Minimum;
            if isempty(MetaData.Minimum)
                MetaData.Minimum = mat2str(this.Parameter.Minimum);
            end
            MetaData.Maximum = this.Maximum;
            if isempty(MetaData.Maximum)
                MetaData.Maximum = mat2str(this.Parameter.Maximum);
            end
            MetaData.Scale = this.Scale;
            if isempty(MetaData.Scale)
                MetaData.Scale = mat2str(this.Parameter.Scale);
            end
            MetaData.Free = this.Free;
            if isempty(MetaData.Free)
                MetaData.Free = mat2str(this.Parameter.Free);
            end
        end

        function setVarName(this,varname)
            this.ParameterName = varname;
        end
    end
    
    %% Set/Get for dependent properties
    methods % set/get
        % Variable Name
        function variableName = get.ParameterName(this)
            variableName = this.VariableNameInternal;
        end

        function set.ParameterName(this,variableName)
            arguments
                this
                variableName string
            end
            % Create new variable in workspace and clear old variable
            updateVariableNameInWorkspace(this,variableName);
        end

        % Name
        function name = get.Name(this)
            name = this.Parameter.Name;
        end

        % Value
        function value = get.Value(this)
            value = this.Parameter.Value;
        end

        function set.Value(this,value)
            this.Parameter.Value = value;
            updateVariableValueInWorkspace(this);
        end

        % Minimum
        function minimum = get.Minimum(this)
            minimum = this.Parameter.Minimum;
        end

        function set.Minimum(this,minimum)
            this.Parameter.Minimum = minimum;
            updateVariableValueInWorkspace(this);
        end

        % Maximum
        function maximum = get.Maximum(this)
            maximum = this.Parameter.Maximum;
        end

        function set.Maximum(this,maximum)
            this.Parameter.Maximum = maximum;
            updateVariableValueInWorkspace(this);
        end

        % Free
        function free = get.Free(this)
            free = this.Parameter.Free;
        end

        function set.Free(this,free)
            this.Parameter.Free = free;
            updateVariableValueInWorkspace(this);
        end

        % Scale
        function scale = get.Scale(this)
            scale = this.Parameter.Scale;
        end

        function set.Scale(this,scale)
            this.Parameter.Scale = scale;
            updateVariableValueInWorkspace(this);
        end
    end
    
    %% Private methods
    methods (Access = private)
        function updateVariableValueInWorkspace(this,variableValue)
            arguments
                this
                variableValue = this.Parameter
            end
            % Update workspace
            assignin(this.Workspace,this.ParameterName,variableValue);
            notify(this,'ParameterChanged');
        end

        function updateVariableNameInWorkspace(this,variableName)
            if ~isempty(this.Workspace)
                % Add variable with new variable name and clear old
                % variable
                assignin(this.Workspace,variableName,this.VariableValue);
                evalin(this.Workspace,"clear " + this.ParameterName);
                this.VariableNameInternal = variableName;
            end
        end

        function addBaseWorkspaceListener(this)
            this.BaseWorkspaceListener = ...
                controllib.widget.internal.variableeditor.BaseWorkspaceListener(this);
        end

        function code = getParameterFieldCode(this,parameterField,variableName)
            arguments
                this
                parameterField char
                variableName char = ''
            end
            MetaData = getMetaData(this);
            code = [sprintf('%s.%s',this.ParameterName,parameterField) ' = ', ...
                mat2str(MetaData.(parameterField)), ';'];
            if ~isempty(variableName)
                code = [variableName,'.',code];
            end
        end
    end
end

