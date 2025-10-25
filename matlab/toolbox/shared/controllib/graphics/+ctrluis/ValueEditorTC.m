classdef ValueEditorTC < ctrluis.component.AbstractTC
    %
    
    % VALUEEDITORTC  Edit a workspace variable
    %
    %    Tool component used to provide a 'rich' editor for workspace
    %    variables. The component stores the expression used to set the
    %    variable value. 
    %
    %    The tool component is paired with the ValueEditorGC graphical
    %    component.
    %
    
    % Copyright 2012-2023 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = protected)
        VarName     %Name of variable being edited
        Wksp        %Workspace where variable resides
        Expr        %Expression used to set the variable value
    end
    
    properties(Access = public)
        %VALUESETFCN Function to set the edited variable value
        %
        %    Function handle to set the edited variable value. The function
        %    handle must accept 3 input arguments, 
        %       - the workspace where the variable resides
        %       - the variable name
        %       - the value of the variable
        %
        %    The default ValueSetFcn is the static method
        %    ValueEditorTC.DefaultValueSetFcn
        %
        ValueSetFcn = @ctrluis.ValueEditorTC.DefaultValueSetFcn;
        
        %PARENT Parent of the tool component
        %
        Parent = [];
    end
    
    methods
        function obj = ValueEditorTC(varname,varargin)
            %VALUEEDITORTC Construct ValueEditor tool component
            %
            %    obj = ValueEditorTC(varname,[wksp],[expr])
            %   
            %    Inputs:
            %      varname - name of variable being edited
            %      wksp    - optional argument specifying the workspace where
            %                the edited variable resides, if omitted the default 
            %                'base' workspace is used
            %      expr    - optional argument specifying the expression
            %                used to set the edited variable's current
            %                value, if omitted the default '' is used
            %
            
            obj.VarName = varname;
            if numel(varargin) > 0
                obj.Wksp = varargin{1};
            else
                obj.Wksp = 'base';
            end
            if numel(varargin) > 1
                obj.Expr = varargin{2};
            else
                obj.Expr = '';
            end
        end
        function value = getValue(this)
            %GETVALUE Get variable value
            %
            %    value = getValue(this)
            %
            %    Return the value of the variable being edited by this
            %    component.
            
            if isempty(this.Parent)
                value = evalin(this.Wksp,this.VarName);
            else
                value = getValue(this.Parent,this.VarName);
            end
        end
        function setValue(this,value)
            %SEVALUE Set variable value
            %
            %    setValue(this,[value])
            %
            %    Set the value of the variable specified by the VarName
            %    property. If passed a value the method also updates the
            %    Expr property.
            %
            %    The method fires the tool-component update method.
            %
            %    Inputs
            %      value - Optional argument, can be a numeric value or an
            %              expression to be evaluated in the workspace
            %              defined by the Wksp property. If omitted the string
            %              specified by the Expr property is used to set the
            %              variable value
            %    
            
            useExpr = nargin == 1;
            if useExpr
                %Use expression property to update the variable value
                if iscell(this.Expr)
                    rhs = this.Expr{1};
                else
                    rhs = this.Expr;
                end
                try
                    value = evalin(this.Wksp,rhs);
                catch E
                    if ~ischar(this.Wksp) || ischar(this.Wksp) && ~strcmp(this.Wksp,'base')
                        %Try evaluation in base workspace
                        value = evalin('base',rhs);
                    else
                        throw(E)
                    end
                end
            else
                if isnumeric(value) || islogical(value)
                    rhs = mat2str(value);
                    if numel(rhs) > 50
                        rhs = '';
                    end
                elseif ischar(value)
                    rhs = value;
                    try
                        value = evalin(this.Wksp,value);
                    catch E
                        if ~ischar(this.Wksp) || ischar(this.Wksp) && ~strcmp(this.Wksp,'base')
                            %Try evaluation in base workspace
                            value = evalin('base',value);
                        else
                            throw(E)
                        end
                    end
                elseif isa(value,'timeseries')
                    rhs = '';
                else
                    error(message('Controllib:gui:errUnexpected','Bad ''Value'' argument type'))
                end
            end
            
            %Update workspace variable value
            this.ValueSetFcn(this.Wksp,this.VarName,value)
            
            if ~useExpr, setExpr(this,rhs); end 
            
            if isempty(this.Parent)
                update(this); %Notify listeners that we have new data
            else
                %Update our parent and let that notify clients that we
                %have new data
                setParameterField(this.Parent,this.VarName,value)
                update(this.Parent); %Calls our update
            end
        end
        function setExpr(this,newValue)
            %SETEXPR
            %
            %    setExpr(this,value)
            %
            %    Set the tool-component Expr property, the method does not
            %    update the tool-component.
            
            this.Expr = newValue;
        end
        function setVarName(this,varname)
            %SETVARNAME
            %
            
            if ischar(varname)
                this.VarName = varname;
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
            view = ctrluis.ValueEditorGC(this);
        end
    end
    methods(Access = protected)
        function mUpdate(this)  %#ok<MANU>
            %MUPDATE Perform subclass specific updates
            %
            
        end
    end
    
    methods(Static = true)
        function DefaultValueSetFcn(wksp,varname,value)
            %DEFAULTVALUESETFCN
            %
            %  ValueEditorTC.DefaultValueSetFcn(wksp,varname,value)
            %
            %  Static function to assign a value to a variable in a
            %  specified workspace.
            %
            % 
            
            %Assign value to temporary variable in the workspace
            tmpName = tempname;
            idx     = regexp(tempname,filesep);
            tmpName = tmpName(idx(end)+1:end);
            assignin(wksp,tmpName,value)
            
            try
                %Assign temporary variable to variable
                evalin(wksp,[varname,'=',tmpName,';']);
                %Remove temporary variable from workspace
                evalin(wksp,['clear ',tmpName]);
            catch E
                %Remove temporary variable from workspace
                evalin(wksp,['clear ',tmpName]);
                throw(E)
            end
        end
    end
end