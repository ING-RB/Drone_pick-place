classdef Continuous < param.Tunable
   %Construct a continuous parameter
   %
   %    Continuous parameters are numeric parameters that can take on any
   %    value in a specified interval. The parameter can be scalar- or
   %    matrix-valued. Parameters are typically used to create parametric
   %    models and to estimate or tune the free parameters in such models.
   %
   %    Example:
   %      p = param.Continuous('K',eye(2));
   %      p.Free = [true false; false true];
            
   % Copyright 2009-2025 The MathWorks, Inc.
   
   properties(Dependent)
      %VALUE Parameter value
      %
      %    Specify a scalar- or matrix- value for the parameter. The
      %    dimension of the Value property is fixed on construction.
      Value
   end %Implemented superclass abstract properties
   
   properties(Dependent)
      %MINIMUM Lower bound for the parameter value
      %
      %    Specify a lower bound for the parameter. The Minimum property
      %    must have the same dimension as the Value property. The default
      %    value is -inf.
      %
      %    For matrix-valued parameters you can specify lower bounds on
      %    individual matrix elements, e.g.,
      %      p= param.Continuous('K',eye(2));
      %      p.Minimum([1 4]) = -5;
      %
      %    You can use scalar expansion to set the lower bound for all
      %    matrix elements, e.g.,
      %      p= param.Continuous('K',eye(2));
      %      p.Minimum = -5;
      Minimum;
      
      %MAXIMUM Upper bound for the parameter value
      %
      %    Specify an upper bound for the parameter. The Maximum property
      %    must have the same dimension as the Value property. The default
      %    value is +inf.
      %
      %    For matrix-valued parameters you can specify upper bounds on
      %    individual matrix elements, e.g.,
      %      p= param.Continuous('K',eye(2));
      %      p.Maximum([1 4]) = 5;
      %
      %    You can use scalar expansion to set the upper bound for all
      %    matrix elements, e.g.,
      %      p= param.Continuous('K',eye(2));
      %      p.Maximum = 5;
      Maximum;
      
      %FREE Flag specifying whether the parameter is tunable or not
      %
      %    Specify whether the parameter is tunable or not. Set the Free
      %    property to true for tunable parameters and false for fixed
      %    parameters. The Free property must have the same dimension as
      %    the Value property. The default value is true.
      %
      %    For matrix-valued parameters you can fix individual matrix
      %    elements, e.g.,
      %      p= param.Continuous('K',eye(2));
      %      p.Free([2 3]) = false;
      %
      %    You can use scalar expansion to fix all matrix elements, e.g.,
      %      p= param.Continuous('K',eye(2));
      %      p.Free = false;
      Free;
      
      %SCALE Scaling factor used to normalize the parameter value
      %
      %    Specify a normalization value for the parameter. The Scale
      %    property must have the same dimension as the Value property. The
      %    default value is 1.
      %
      %    For matrix-valued parameters you can specify scaling for individual
      %    matrix elements, e.g.,
      %      p= param.Continuous('K',2*eye(2));
      %      p.Scale([1 4]) = 1;
      %
      %    You can use scalar expansion to set the scaling for all matrix
      %    elements, e.g.,
      %      p= param.Continuous('K',eye(2));
      %      p.Scale = 1;
      Scale;
   end % dependent properties
   
   properties(Hidden = true, Access = protected)
      Minimum_
      Maximum_
      Free_
      Scale_
   end % protected properties

   properties(Access = protected)
	  %RETAINDATATYPE Flag to indicate whether the datatype of the parameter 
	  %				  should be preserved.
	  %
	  %    Specify a logical value for this property. The default value is false(0).
      RetainDatatype (1,1) logical
   end
   
   methods (Access = public)
       function this = Continuous(name, value, options)
         %CONTINUOUS Construct a param.Continuous object.
         %
         %    Construct a param.Continuous object:
         %       p = param.Continuous
         %       p = param.Continuous(value)
         %       p = param.Continuous(name, [value])
         %
         %    Use param.Continuous to construct an unnamed scalar parameter
         %    with its Value property set to zero.
         %
         %    Use param.Continuous(value) to construct an unnamed parameter
         %    with its Value property set to a specific value.
         %
         %    Use param.Continuous(name) to construct a named scalar
         %    parameter with its Value property set to zero.
         %
         %    Use param.Continuous(name,value) to construct a named
         %    parameter with its Value property set to a specific value.
         %
         
         % Undocumented constructors:
         %    param.Continuous(id, [value])
         arguments
             name = ''
             value = 0
             options.retainDatatype = false;
         end

         ni = nargin;
         if ni==0
            % Properties for no-argument constructor.
            ID = [];
            
         % Parse first input argument.
         elseif ischar(name) || isStringScalar(name)
             ID = paramid.Variable(char(name));
         elseif isa(name, 'paramid.ID')
             ID = name;
         elseif isnumeric(name)  &&  (ni == 1)
             ID = [];
             value = name;
         else
             error(message('Controllib:modelpack:InvalidArgument', 'NAME/ID'))
         end
                
         % Call superclass constructor first.
         this = this@param.Tunable(ID);
         
         %Set parameter dimensions, do this before setting actual value to
         %avoid dimension check
         this.Size_ = size(value);

         %g3445836: Set whether we want to retain the datatype of the
         %parameter values. Do this before setting the actual value to
         %avoid datatype mismatch.
         this.RetainDatatype = options.retainDatatype;

         %Set value property
         this.Value = value;
      end
      function b = isreal(this)
         %ISREAL True for a real parameter
         %
         % Returns true if the Value, Minimum, and Maximum properties of a
         % param.Continuous object are all real.
         %
         b = false(size(this));
         for ct=1:numel(this)
             b(ct) = isreal(this(ct).Value_) && ...
                 isreal(this(ct).Minimum_) && isreal(this(ct).Maximum_);
         end
      end
   end % public methods

   methods(Hidden = true)
      function pNew = catParameter(dim,this,p,name)
         % CATPARAMETER creates a new parameter by concatenating two parameter objects
         %
         % Pnew = catParameter(dim,p1,p2,[name])
         %
         % Concatenate the properties of this object with p along the
         % dimension specified.
         %
         % Inputs:
         %   dim   - dimension along which to concatenate, dim=1 performs 
         %           vertical concatenation, dim=2 performs horizontal 
         %           concatenation, etc.
         %   p1,p2 - the param.Continuous objects to concatenate
         %   name  - an optional character vector argument with the name of
         %           the new parameter, if omitted the name of this object
         %           is reused.
         %
         
         %Check for correct number of arguments
         narginchk(3,4)
         
         %Process inputs
         if ~(isnumeric(dim) && isscalar(dim) && isfinite(dim))
            error(message('Controllib:modelpack:InvalidArgumentForCommand', 'dim', 'catParameter'))
         end
         if ~isa(this,'param.Continuous')
             if all(size(this)==0)
                 this = repmat(p,0,0);
             else
                 error(message('Controllib:modelpack:InvalidArgumentForCommand', 'p1', 'catParameter'))
             end
         end
         if ~isa(p,'param.Continuous')
             if all(size(p)==0)
                 p = repmat(this,0,0);
             else
                 error(message('Controllib:modelpack:InvalidArgumentForCommand', 'p2', 'catParameter'))
             end
         end
         if nargin < 4
            noID = (numel(this)==0) || isempty(this.getID);
            if ~noID
                name = this.Name;
            end
         else
            if ~(ischar(name) || isstring(name) && isscalar(name))
               error(message('Controllib:modelpack:InvalidArgumentForCommand', 'name', 'catParameter'))
            end
            name = char(name);
            noID = isempty(name);
         end
         
         %Concatenate value property and create new parameter object
         try
            newValue = cat(dim,this.Value,p.Value);
         catch E
            throw(E)
         end
         
         if noID
            pNew = param.Continuous(newValue);
         else
            pNew = param.Continuous(name,newValue);
         end
         
         %Concatenate ancillary properties
         if numel(this) && numel(p) > 0 
             %Neither are nx0 objects
             pNew = catAncillaryProps(this,p,dim,pNew);
         end
      end
      function pNew = subsrefParameter(this,idx,name)
         % SUBSREFPARAMETER create a new parameter by sub-indexing into a parameter
         %
         % pNew = subsrefParameter(p,idx,[name])
         % pNew = subsrefParameter(p,{idx1,....,idxN},[name])
         %
         % Create a new parameter object from the elements of this parameter
         % object. Element values to use for the new parameter are specified by 
         % the index argument, see subsref for more information on indexing. 
         %
         % Inputs:
         %   idx  - a logical array, an array of ordinal indices, or a cell 
         %          array of coordinate indices. Wildcards, ':', and index
         %          ranges, '5:11', are supported.
         %   name - an optional character vector argument with the name of 
         %          the new parameter, if omitted the name of this object
         %          is reused.
         %
         % See also subsref, param.Continuous.subsasgnParameter
         %
         
         %Check for correct number of arguments
         narginchk(2,3)
         
         %Process inputs
         if ~iscell(idx), idx = {idx}; end
         if nargin < 3
            noID = isempty(this.getID);
            name = this.Name;
         else
            if ~(ischar(name) || isstring(name) && isscalar(name))
               error(message('Controllib:modelpack:InvalidArgumentForCommand', 'name', 'subsrefParameter'))
            end
            name = char(name);
            noID = isempty(name);
         end
            
         %Construct a new parameter object from the elements of this object
         try
            NewValue = this.Value(idx{:});
         catch E
            throw(E)
         end
         if noID
            pNew = param.Continuous(NewValue);
         else
            pNew = param.Continuous(name,NewValue);
         end
         
         %Copy ancillary properties
         pNew = subsrefAncillaryProps(this,pNew,idx);
      end
      function this = subsasgnParameter(this,idx,p)
         % SUBSASGNPARAMETER set the elements of a parameter object from another parameter
         %
         % p = subsasgnParameter(p,idx,p1);
         % p = subsasgnParameter(p,{idx1,...,idxN},p1);
         %
         % Set the elements of this parameter object using the properties 
         % of the passed parameter object. Elements to set are specified by the
         % index argument. The size of the passed parameter object must match 
         % the size implied by the passed index.
         %
         % Inputs:
         %   idx  - a logical array, an array of ordinal indices, or a cell 
         %          array of coordinate indices. Wildcards, ':', and index
         %          ranges, '5:11', are supported.
         %   p1   - a param.Continuous object from which element values
         %          are copied
         %
         % See also subsasgn, param.Continuous.subsrefParameter
         %
         
         %Check for correct number of arguments
         narginchk(3,3)
         
         %Process inputs
         if ~isa(p,'param.Continuous')
            error(message('Controllib:modelpack:InvalidArgumentForCommand', 'p', 'subsasgnParameter'))
         end
         if ~iscell(idx), idx = {idx};  end
         
         %Assign the value property
         try
            v = this.Value(idx{:});
            v(:) = p.Value(:);
            this.Value(idx{:}) = v;
         catch E
            throw(E)
         end
         
         %Copy ancillary properties
         this = subsasgnAncillaryProps(this,p,idx);
      end
      
      function this = renameParam(this,NewName)
         % Needed to handle side effects of PRISM property renaming.
         this.pID.Name = NewName;
      end
   end % hidden public methods
   
   methods
      %Get/Set methods for implemented abstract dependent Value property
      function this = set.Value(this, value)
         try
            this.Value_ = this.formatNumericValue(value,'Value');
         catch E
            throwAsCaller(E)
         end
      end
      function val = get.Value(this)
         val = this.Value_;
      end
      %Get/Set methods for dependent Minimum property
      function this = set.Minimum(this, value)
         try
            this.Minimum_ = this.formatNumericValue(value,'Minimum',-inf);
         catch E
            throwAsCaller(E)
         end
      end
      function val = get.Minimum(this)
         if isempty(this.Minimum_)
            %Property has not been initialized, return default
            val = -inf(this.Size_);
         else
            val = this.Minimum_;
         end
      end
      %Get/set methods for dependent Maximum property
      function this = set.Maximum(this, value)
         try
            this.Maximum_ = this.formatNumericValue(value,'Maximum',inf);
         catch E
            throwAsCaller(E)
         end
      end

      function val = get.Maximum(this)
         if isempty(this.Maximum_)
            %Property has not been initialized, return default
            val = inf(this.Size_);
         else
            val = this.Maximum_;
         end
      end
      %Get/set methods for dependent Free property
      function this = set.Free(this, value)
         try
            this.Free_ = this.formatLogicalValue(value,'Free',true);
         catch E
            throwAsCaller(E)
         end
      end
      function val = get.Free(this)
         if isempty(this.Free_)
            %Property has not been initialized, return default
            val = true(this.Size_);
         else
            val = this.Free_;
         end
      end
      %Get/set methods for dependent Scale property
      function this = set.Scale(this, value)
         try
            this.Scale_ = this.formatNumericValue(value,'Scale',1);
         catch E
            throwAsCaller(E)
         end
      end
      function val = get.Scale(this)
         if isempty(this.Scale_)
            %Property has not been initialized, return default
            val = ones(this.Size_,'like',this.Value);
         else
            val = this.Scale_;
         end
      end
   end % property get/set methods
      
   methods(Hidden = true, Access = protected)
      function value = formatNumericValue(this, value, prop, default)
         % Convenience method to move numerical property checks out of set methods.
         %
         % Returns [] if the new property value is the same as the default
         % property value. This is for performance and to ensure correct
         % isequal results when comparing against a default object.

         %Validate attributes according to the property
         if strcmp(prop,'Scale')
             attrib = {'real'};
         else
             attrib = {};
         end
         validateattributes(value,{'numeric'},attrib,'',strcat('"',prop,'" property'));
 
         value = this.formatDatatype(value, prop);
         value = this.formatValueToSize(value,prop);
         if (nargin>=4) && isequal(value, default(ones(this.Size_)))
            value = [];
         end
      end
      
      function bool = isDefaultValue(this, prop)
         % Method to determine whether a property value has been modified
         % from it's default value. Returns true if the property is
         % unmodified false otherwise.
         %
         % bool = isDefaultValue(this, prop)
         %
         % Inputs:
         %   prop - one of {'Minimum','Maximum','Free','Scale'}
         %
         
         allProp = {'Minimum','Maximum','Free','Scale'};
         if any(strcmp(allProp,prop))
            %Default value indicated by empty private property
            bool = (numel(this)==0) || isempty(this.(strcat(prop,'_')));
         else
            try 
               %Call parent class method
               bool = isDefaultValue@param.Parameter(this,prop);
            catch 
               error(message('Controllib:modelpack:InvalidArgumentForCommand', prop, 'isDefaultValue'))
            end
         end
      end
      
      function pNew = catAncillaryProps(this,p,dim,pNew)
         % Convenience method to copy concatenated property values to a
         % parameter object. Called by catParameter method. 
         %
         % This method is separated from catParameter so that subclasses
         % can call it in overloaded catParameter methods.
         
         %Parent class does not support concatenation but there is an Info
         %prop on the parent class that we need to cat, do that directly here
         if ~(isDefaultValue(this,'Info') && isDefaultValue(p,'Info'))
            pNew.Info = cat(dim,this.Info,p.Info);
         end
      
         %Concatenate rest of the ancillary properties. 
         %
         %For performance reasons call this.Minimum_ directly instead of 
         %using isDefaultValue. Use p.isDefaultValue as need access to
         %private property.
         if ~(isempty(this.Minimum_) && isDefaultValue(p,'Minimum'))
            pNew.Minimum = cat(dim,this.Minimum,p.Minimum);
         end
         if ~(isempty(this.Maximum_) && isDefaultValue(p,'Maximum'))
            pNew.Maximum = cat(dim,this.Maximum,p.Maximum);
         end
         if ~(isempty(this.Free_) && isDefaultValue(p,'Free'))
            pNew.Free = cat(dim,this.Free,p.Free);
         end
         if ~(isempty(this.Scale_) && isDefaultValue(p,'Scale'))
            pNew.Scale = cat(dim,this.Scale,p.Scale);
         end
      end
      
      function pNew = subsrefAncillaryProps(this,pNew,idx)
         % Convenience method to copy indexed property values to a new
         % parameter object. Called by subsrefParameter. 
         %
         % This method is separated from subsrefParameter so that subclasses
         % can call it in overloaded subsrefParameter methods.
         
         %Parent class does not support subsref but there is an Info
         %prop on the parent class that we need to subsref, do that directly here
         if ~isDefaultValue(this,'Info')
            pNew.Info = this.Info(idx{:});
         end
         
         %If they are not default copy ancillary properties
         if ~isempty(this.Minimum_)
            pNew.Minimum = this.Minimum(idx{:});
         end
         if ~isempty(this.Maximum_)
            pNew.Maximum = this.Maximum(idx{:});
         end
         if ~isempty(this.Free_)
            pNew.Free = this.Free(idx{:});
         end
         if ~isempty(this.Scale_)
            pNew.Scale = this.Scale(idx{:});
         end
      end
      
      function this = subsasgnAncillaryProps(this,p,idx)
         % Convenience method to assign indexed elements of this object from
         % a passed parameter object. Called by subsasgnParameter
         %
         % This method is separated from subsasgnParameter so that subclasses
         % can call it in overloaded subsasgnParameter methods.
         
         %Parent class does not support subsasgn but there is an Info
         %prop on the parent class that we need to subsasgn, do that directly here
         %
         %For performance reasons call this.Info_ directly instead of
         %using isDefaultValue. Use p.isDefaultValue as need access to
         %private property.
         if ~(isempty(this.Info_) && isDefaultValue(p,'Info'))
            v = this.Info(idx{:});
            v(:) = p.Info(:);
            this.Info(idx{:}) = v;
         end
         if ~(isempty(this.Minimum_) && isDefaultValue(p,'Minimum'))
            v = this.Minimum(idx{:});
            v(:) = p.Minimum(:);
            this.Minimum(idx{:}) = v;
         end
         if ~(isempty(this.Maximum_) && isDefaultValue(p,'Maximum'))
            v = this.Maximum(idx{:});
            v(:) = p.Maximum(:);
            this.Maximum(idx{:}) = v;
         end
         if ~(isempty(this.Free_) && isDefaultValue(p,'Free'))
            v = this.Free(idx{:});
            v(:) = p.Free(:);
            this.Free(idx{:}) = v;
         end
         if ~(isempty(this.Scale_) && isDefaultValue(p,'Scale'))
            v = this.Scale(idx{:});
            v(:) = p.Scale(:);
            this.Scale(idx{:}) = v;
         end
      end
   end % protected methods
   
   methods (Hidden = true, Sealed, Access = protected)
      
      function value = formatLogicalValue(this, value, prop, default)
         % Convenience method to move logical property checks out of set methods.
         %
         % Returns [] if the new property value is the same as the default
         % property value. This is for performance and to ensure correct
         % isequal results when comparing against a default object.
         if ~(islogical(value) || isnumeric(value))
            error(message('Controllib:modelpack:LogicalArrayProperty', prop));
         end
         try
            value = full(logical(value));
         catch
            error(message('Controllib:modelpack:LogicalArrayProperty', prop));
         end
         value = this.formatValueToSize(value,prop);
         if isequal(value, default(ones(this.Size_)))
            value = [];
         end
      end
 
      function value = formatDatatype(this, value, prop)
          %Helper function to manage the datatype of the properties.
          %(g3445836).
          value = full(value);
          if(~this.RetainDatatype)
              %Typecast property value to double
              value = double(value);
          elseif any(strcmp(prop,["Minimum","Maximum","Scale"]))
              %Typecast other properties to the datatype of Value property
              value = cast(value,"like",this.Value);
          end
      end
   end % sealed protected methods

   %API methods for param.Tunable
   methods (Access = protected)
       function [value,free] = vecElement(this)
           %VECELEMENT Get values in vector form
           %    The parameter object must be scalar
           %
           arguments
               this (1,1)
           end

           value = this.Value;
           free  = this.Free;
       end

       function this = setPVecElement(this,pv)
           %SETPVECELEMENT Set parameter value, given a vector
           %   The parameter object should be scalar
           %
           arguments
               this (1,1)
               pv
           end

           this.Value(:) = pv; % Reshaped in set.Value
       end
   end

   %API methods for param.Tunable
   methods (Hidden)
       function [x0,xMin,xMax,xTypical,xScale] = parToVecForOptim(this)
           %PARTOVECFOROPTIM Convert parameter to vector for optimization
           %   The parameter object must be scalar
           %
           arguments
               this (1,1)
           end

           idx = this.Free;
           s = abs(this.Scale(idx));
           s(s==0) = 1;
           %Get scaled decision vector values
           v   = this.Value(idx);
           v   = v ./ s;
           lb  = this.Minimum(idx);
           lb  = lb ./ s;
           ub  = this.Maximum(idx);
           ub  = ub ./ s;
           %Set typical value (used to determine perturbation size). Use
           %scale to determine typical value, if scale == 1 typical value
           %is current value else typical value is scale/scale=1
           tv = v;
           tv(s~=1) = 1;
           tv(tv<sqrt(eps)) = 1;   %TODO: what about when tv is negative?

           %Assign outputs
           x0       = v(:);
           xMin     = lb(:);
           xMax     = ub(:);
           xTypical = tv(:);
           xScale   = s(:);
       end

       function p = vecToParForOptim(this,x)
           %VECTOPARFOROPTIM Convert vector to parameter for optimization
           %    Inputs
           %        this - A scalar parameter object
           %        x    - Vector of values for the parameter.  Should have
           %               number of elements = sum(this.Free).
           %
           arguments
               this (1,1)
               x
           end

           idx = this.Free;
           if numel(x) ~= sum(idx,'all')
               error(message('Controllib:modelpack:errVectorLengthX'));
           end
           s = abs(this.Scale(idx));
           s(s==0) = 1;
           xScale = s(:);
           p = setPVec(this, x .* xScale, 'free');
       end
   end
end % classdef
