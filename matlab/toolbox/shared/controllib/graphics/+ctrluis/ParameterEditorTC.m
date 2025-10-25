classdef ParameterEditorTC < toolpack.AtomicComponent
    % 
    
    % PARAMETEREDITORTC Edit a workspace parameter
    %
    %    Tool component for editing a workspace variable that defines a
    %    parameter.
    %
    
    % Copyright 2012-2023 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = protected)
        VarName    %Name of parameter variable being edited
        Wksp       %Workspace where variable resides
        ValueTC    %ValueEditor tool component to edit the parameter Value property
        MinTC      %ValueEditor tool component to edit the parameter Minimum property (for continuous parameter)
        MaxTC      %ValueEditor tool component to edit the parameter Maximum property (for continuous parameter)
        ScaleTC    %ValueEditor tool component to edit the parameter Scale property (for continuous parameter)
        ValueSetTC %ValueEditor tool component to edit the parameter ValueSet property (for discrete parameter)
        FreeTC     %ValueEditor tool component to edit the parameter Free property
    end
    
    properties(GetAccess = public, SetAccess = public)
        Parent  %Parent of the tool component
    end
    
    properties(GetAccess = protected, SetAccess = protected)
        Parameter %Copy of the parameter variable being edited
    end
    
    methods
        function obj = ParameterEditorTC(varname,varargin)
            %PARAMETEREDITORTC Construct ParameterEditor tool component
            %
            %    obj = ParameterEditorTC(varname,[wksp])
            %
            %    Inputs:
            %      varname - name of parameter variable being edited
            %      wksp    - optional argument specifying the workspace
            %                where the variable resides, if omitted the
            %                default 'base' workspace is used
            %
            
            obj.VarName = varname;
            if numel(varargin) > 0
                obj.Wksp = varargin{1};
            else
                obj.Wksp = 'base';
            end
            
            %Create tool components to edit the Parameter properties
            obj.ValueTC    = ctrluis.ValueEditorTC(strcat(varname,'.Value'),    obj.Wksp);
            obj.MinTC      = ctrluis.ValueEditorTC(strcat(varname,'.Minimum'),  obj.Wksp);
            obj.MaxTC      = ctrluis.ValueEditorTC(strcat(varname,'.Maximum'),  obj.Wksp);
            obj.ScaleTC    = ctrluis.ValueEditorTC(strcat(varname,'.Scale'),    obj.Wksp);
            obj.ValueSetTC = ctrluis.ValueEditorTC(strcat(varname,'.ValueSet'), obj.Wksp);
            obj.FreeTC     = ctrluis.ValueEditorTC(strcat(varname,'.Free'),     obj.Wksp);
        end
        function name = getParameterName(this)
            %GETPARAMETERNAME
            %
            name = evalin(this.Wksp, strcat(this.VarName,'.Name'));
        end
        function value = getValue(this,what)
            %GETVALUE
            %
            %    value = getValue(obj,[field])
            %
            %    Return the value of the 'field' property of the edited
            %    parameter. If the optional 'field' is omitted the parameter
            %    is returned.
            %
            
            if nargin < 2
                %Return the parameter object
                if isempty(this.Parameter)
                    value = evalin(this.Wksp,this.VarName);
                else
                    value = this.Parameter;
                end
            else
                %Return a field of the parameter object
                if isempty(this.Parameter)
                    value = evalin(this.Wksp, what);
                else
                    n     = numel(this.VarName);
                    value = this.Parameter.(what(n+2:end));
                end
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
                n = numel(this.VarName);
                this.Parameter.(what(n+2:end)) = value;
            end
        end
        function setComponentParents(this,parent)
            %SETCOMPONENTPARENTS
            %
            %    setComponentParents(obj,[parent])
            %
            %    Set the Parent property of all ParameterEditorTC
            %    sub-components. If the optional 'parent' argument is
            %    omitted 'obj' is used as the parent.
            %
            
            if nargin < 2
                parent = this;
            end
            this.ValueTC.Parent = parent;
            this.MinTC.Parent   = parent;
            this.MaxTC.Parent   = parent;
            this.ScaleTC.Parent = parent;
            this.ValueSetTC.Parent = parent;
            this.FreeTC.Parent  = parent;
        end
        
        function Text = generateMATLABCode(this, default)
            MetaData = getMetaData(this);
            actual = getValue(this);
            Text = cell(0,1);

            %Generate code for the value
            ValueCode = [sprintf('%s.Value',this.VarName) ' = ', MetaData.Value, ';'];
            Text = controllib.internal.codegen.appendMATLABCode(Text, ValueCode);

            switch getMode(this)
                case 'continuous'
                    %Generate code specific to continuous parameters
                    if any(default.Minimum ~= actual.Minimum)
                        MinCode = [sprintf('%s.Minimum',this.VarName) ' = ', MetaData.Minimum, ';'];
                        Text = controllib.internal.codegen.appendMATLABCode(Text, MinCode);
                    end
                    if any(default.Maximum ~= actual.Maximum)
                        MaxCode = [sprintf('%s.Maximum',this.VarName) ' = ', MetaData.Maximum, ';'];
                        Text = controllib.internal.codegen.appendMATLABCode(Text, MaxCode);
                    end
                    if any(default.Scale ~= actual.Scale)
                        ScaleCode = [sprintf('%s.Scale',this.VarName) ' = ', MetaData.Scale, ';'];
                        Text = controllib.internal.codegen.appendMATLABCode(Text, ScaleCode);
                    end
                case 'discrete'
                    %Generate code specific to discrete parameters
                    if any(default.ValueSet ~= actual.ValueSet)
                        ValueSetCode = [sprintf('%s.Valueseet',this.VarName) ' = ', MetaData.ValueSet, ';'];
                        Text = controllib.internal.codegen.appendMATLABCode(Text, ValueSetCode);
                    end
            end
            
            %Generate code for whether the parameter is free to be varied
            if any(default.Free ~= actual.Free)
                FreeCode = [sprintf('%s.Free',this.VarName) ' = ', MetaData.Free, ';'];
                Text = controllib.internal.codegen.appendMATLABCode(Text, FreeCode);
            end
        end
            
        function MetaData = getMetaData(this)

            %Metadata for the value of the parameter
            MetaData.Value = this.ValueTC.Expr;
            if isempty(MetaData.Value)
                MetaData.Value = mat2str(this.Parameter.Value);
            end

            switch getMode(this)
                case 'continuous'
                    %Metadata specific to continuous parameters
                    MetaData.Minimum = this.MinTC.Expr;
                    if isempty(MetaData.Minimum)
                        MetaData.Minimum = mat2str(this.Parameter.Minimum);
                    end
                    MetaData.Maximum = this.MaxTC.Expr;
                    if isempty(MetaData.Maximum)
                        MetaData.Maximum = mat2str(this.Parameter.Maximum);
                    end
                    MetaData.Scale = this.ScaleTC.Expr;
                    if isempty(MetaData.Scale)
                        MetaData.Scale = mat2str(this.Parameter.Scale);
                    end
                case 'discrete'
                    %Metadata specific to discrete parameters
                    MetaData.ValueSet = this.ValueSetTC.Expr;
                    if isempty(MetaData.ValueSet)
                        MetaData.ValueSet = mat2str(this.Parameter.ValueSet);
                    end
            end

            %Metadata for whether the parameter is free to be varied
            MetaData.Free = this.FreeTC.Expr;
            if isempty(MetaData.Free)
                MetaData.Free = mat2str(this.Parameter.Free);
            end
        end
        function setVarName(this,varname)
            %SETVARNAME
            %
           
            if ischar(varname)
                %Change VarName
                this.VarName = varname;
                
                %Change VarName of contained components
                setVarName(this.ValueTC,sprintf('%s.Value',varname))
                setVarName(this.MinTC,sprintf('%s.Minimum',varname))
                setVarName(this.MaxTC,sprintf('%s.Maximum',varname))
                setVarName(this.ScaleTC,sprintf('%s.Scale',varname))
                setVarName(this.ValueSetTC,sprintf('%s.ValueSet',varname))
                setVarName(this.FreeTC,sprintf('%s.Free',varname))
            else
                error(message('Controllib:gui:errUnexpected','The ''varname'' argument must be a string'))
            end
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            %CREATEVIEW Construct graphical component for the tool component
            %
            if ~strcmp('continuous', getMode(this))
                error(message('Controllib:gui:errUnexpected', 'The parameter must be continuous to use the createView method'))
            end
            
            view = ctrluis.ParameterEditorGC(this);
        end
    end
    methods(Access = protected)
        function mUpdate(this)
            %MUPDATE Perform subclass specific updates
            %
            
            %Update our local copy of the parameter 
            this.Parameter = evalin(this.Wksp, this.VarName);

            %Trigger update of contained tool components
            update(this.ValueTC);
            switch getMode(this)
                case 'continuous'
                    update(this.MinTC);
                    update(this.MaxTC);
                    update(this.ScaleTC);
                case 'discrete'
                    update(this.ValueSetTC);
            end
            update(this.FreeTC);
        end
        function mode = getMode(this)
            %Determine whehter parameter is continuous or discrete

            %The mode can change during object lifecycle
            var = evalin(this.Wksp, this.VarName);
            if isDiscrete(var)
                mode = 'discrete';
            else
                mode = 'continuous';
            end
        end
    end
end