classdef Parameter < matlab.mixin.Heterogeneous
    %Abstract parent class for all parameter objects
    %
    %    Parameter objects are typically used to create parametric models and
    %    to estimate or tune the free parameters in such models.
    
    % Copyright 2009-2016 The MathWorks, Inc.
    
    properties (Hidden = true, GetAccess = protected, SetAccess = protected)
        %SIZE_ Dimension of parameter value and dependent properties
        %
        %    Size of the parameter should not change after construction
        %
        Size_  = [0 0];    
        
        %VALUE_ Parameter value
        %
        Value_ = [];
        
        %PID ParameterID object defining the parameter type
        %
        pID = [];
    end % protected properties
    
    properties (Abstract = true, Dependent)
        %VALUE Parameter value
        %
        %    The Value property specifies a value for the parameter. The
        %    dimension of the Value property is fixed on construction.
        Value;
    end % abstract properties
    
    properties(Dependent)
        %NAME Parameter name
        %
        %    The Name property is a read-only character vector that is set 
        %    on object construction.
        Name;
        
        %INFO Structure array specifying parameter units and labels
        %
        %    The Info property is a structure array with Label and Unit fields.
        %    The array dimension matches the dimension of the Value property.
        %
        %    Use the Info property to store parameter units and labels that
        %    describe the parameter, e.g.,
        %      p = param.Continuous('K',eye(2));
        %      p.Info(1,1).Unit  = 'N/m';
        %      p.Info(1,1).Label = 'spring constant';
        Info;
    end %Public dependent properties
    
    properties (Hidden = true, GetAccess = protected, SetAccess = protected)
        Version = param.version;
        Info_   = [];
    end % protected properties
    
    %Interface methods for matlab.mixin.Heterogeneous
    methods(Sealed, Static, Access = 'protected')
        function obj = getDefaultScalarElement
            obj = param.Continuous;
        end
    end
    
    methods (Hidden = true, Access = protected)
        function this = Parameter(ID)
            % Constructor
            %
            % param.Value(name)
            % param.Value(id)
            ni = nargin;
            if ni > 0
                narginchk(1, 1)
                
                % Parse first input argument.
                if ischar(ID) || isstring(ID) && isscalar(ID)
                    ID = paramid.Variable(char(ID));
                elseif ~(isa(ID, 'paramid.ID') || isempty(ID))
                    error(message('Controllib:modelpack:InvalidArgument', 'NAME/ID'))
                end
            else
                % Properties for no-argument constructor.
                ID = [];
            end
            
            % Set properties, using scalar expansion if necessary.
            this.pID         = ID;
        end
        
        function bool = isDefaultValue(this,prop)
            %ISDEFAULTVALUE Check whether a property is the default value
            %
            %    Determine whether a property value has been modified
            %    from it's default value. Returns true if the property is
            %    unmodified, false otherwise.
            %
            %    bool = isDefaultValue(this, prop)
            %
            %    Inputs:
            %      prop - one of {'Info'}
            %
            
            if strcmp(prop,'Info')
                %Protect against case where this = [];
                bool = (numel(this)==0) || isempty(this.Info_);
            else
                error(message('Controllib:modelpack:InvalidArgument', prop))
            end
        end
    end % hidden protected methods
    
    methods(Hidden = true, Sealed = true)
        function disp(this)
            %
            
            paramid.array_display(this);
        end
        function display(this)
            %
            
            paramid.array_display(this, inputname(1));
        end
    end
    
    methods(Hidden = true)
        function ID = getID(this)
            %GETID Return the private parameter ID property
            %
            ID = this.pID;
        end
        function sz = getSize(this)
            %GETSIZE Return the size of the value property
            %
            sz = this.Size_;
        end
        function props = properties(this)
            %
            
            %Make sure Name property appears as first in property list
            props = properties(class(this));
            idx = strcmp(props,'Name');
            props = [props(idx); props(~idx)];
        end
        function this = changeName(this,name)
            %CHANGENAME Modify the name property
            %
            %    Replace the parameter ID property with a new parameter ID.
            %    The new parameter ID assumes that the passed new name is
            %    for a workspace variable of the same name. Changing the
            %    parameter ID property of a parameter object may cause
            %    unexpected results. 
            %
            %    Example:
            %      p = param.Continuous('A',1);
            %      p = changeName(p,'B');
            %    
            
            warning(message('Controllib:modelpack:warnChangeParameterName'))
            this.pID = paramid.Variable(name);
        end
    end % Hidden public methods
    
    methods
        %Get/set methods for dependent Name property
        function name = get.Name(this)
            ID = this.pID;
            if isempty(ID)
                name = '';
            else
                name = getFullName(ID);
            end
        end
        function this = set.Name(this,value)
            try
                this = pSetName(this,value);
            catch E
                throwAsCaller(E)
            end
        end
        %Get/set methods for dependent Info property
        function this = set.Info(this,value)
            try
                if isempty(value)
                    this.Info_ = [];
                elseif isstruct(value) && isfield(value,'Label') && isfield(value,'Unit')
                    if isequal(size(value), this.Size_)
                        cData = struct2cell(value);
                        %Convert any string field values to character
                        %arrays
                        for ct=1:numel(value)
                            tmp = value(ct).Label;
                            if isstring(tmp) && isscalar(tmp)
                                value(ct).Label = char(tmp);
                            end
                            tmp = value(ct).Unit;
                            if isstring(tmp) && isscalar(tmp)
                                value(ct).Unit = char(tmp);
                            end
                        end
                        if ~iscellstr({value.Label}) || ~iscellstr({value.Unit})
                            error(message('Controllib:modelpack:errInfoProperty'))
                        end
                        if all(strcmp(cData(:),''))
                            %Data is same as default
                            this.Info_ = [];
                        else
                            this.Info_ = value;
                        end
                    else
                        error(message('Controllib:modelpack:CannotFormatValueToSize','Info'))
                    end
                else
                    error(message('Controllib:modelpack:errInfoProperty'))
                end
            catch E
                throwAsCaller(E)
            end
        end
        function value = get.Info(this)
            if isempty(this.Info_)
                %Property has not been initialized, return default
                sz = this.Size_;
                if prod(sz) == 0
                    %Quick return as no elements in Value property
                    value = repmat(struct('Label','','Unit',''),sz);
                    return
                end
                %Set Unit/Label to empty for each element
                lbl = {''};
                vUnit = lbl(ones(sz));
                value = struct('Label',vUnit,'Unit',vUnit);
            else
                value = this.Info_;
            end
        end
    end % property methods
    
    methods (Hidden = true, Access = protected)
        function this = pSetName(this,value) %#ok<INUSD>
            error(message('Controllib:modelpack:errReadOnlyProperty','Name',class(this)));
        end
    end % Hidden protected methods
    
    methods (Hidden = true, Sealed, Access = protected)
        function value = formatValueToSize(this, value, prop)
            % Formats the value to match the size of the variable.
            sz = this.Size_;
            % Reshape value if needed.
            if ~isequal(size(value), sz)
                if isscalar(value)
                    % Scalar expansion.
                    value = value(ones(sz));
                elseif isvector(value) && length(value) == prod(sz)
                    % Vector with same number of elements, but possibly different orientation.
                    value = reshape(value, sz);
                else
                    error(message('Controllib:modelpack:CannotFormatValueToSize', prop))
                end
            end
        end
    end % hidden sealed protected methods
    
end % classdef
