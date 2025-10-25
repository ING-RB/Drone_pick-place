classdef Discrete < param.Tunable
   %Construct a discrete parameter
   %
   %    Discrete parameters are parameters that can take on any value from
   %    a specified set of values. The parameter can be scalar- or
   %    matrix-valued.  Discrete parameters are typically used to
   %    parameterize a model and then tuned to optimize the behavior of the
   %    model.
   %
   %    Example:
   %      p = param.Discrete('R',20);
   %      p.ValueSet = [20 22 24 27 30];

   % Copyright 2009-2023 The MathWorks, Inc.
   
   properties(Dependent)
      %VALUE Parameter value
      %
      %    The Value property is a read-write property. The Value property must
      %    be an allowable value specified by the ValueSet property.
      Value
   end % Implemented superclass abstract properties
   
   properties(Dependent)
      %VALUESET Set of allowable parameter values
      %
      %    The ValueSet property specifies the allowable values for a parameter. 
      ValueSet
      
      %FREE Tunable state of the parameter
      %
      %    The Free property specifies whether the parameter is tunable or not.
      %    The dimension of the Free property matches the dimension of the
      %    Value property. The default value is true.
      Free
   end % dependent properties
   
   properties(Hidden = true, GetAccess = protected, SetAccess = protected)
      ValueSet_
      Free_
   end % dependent properties
   
   methods (Access = public)
      function this = Discrete(name, value, valueset)
         %DISCRETE Construct a param.Discrete object
         %
         %    The param.Discrete constructor supports various input argument
         %    signatures
         %      p = param.Discrete
         %      p = param.Discrete(name, [value], [valueset])
         %
         %    Use param.Discrete to construct an unnamed parameter object
         %    with allowable values of 0, and its Value property set to 0.
         %
         %    Use param.Discrete(name) to construct a named parameter object
         %    with allowable values of 0, and its Value property set to 0.
         %
         %    Use param.Discrete(name,value) to construct a named parameter
         %    object with its Value property set to a specified value and the
         %    allowable values set to the specified value.
         %
         %    Use param.Discrete(name,value,valueset) to construct a named
         %    parameter object with its Value property set to a specified
         %    value and the allowable values set to a specified value.
         
         % Undocumented constructors:
         %   p = param.Discrete(id, [value], [valueset])
         %   p = param.Discrete(value, [valueset]) value is numeric to distinguish from Discrete(name)
         
         ni = nargin;
         if (ni > 0)
            narginchk(1,3)
            
            % Default arguments
            if (ni < 2), value = 0; end
            if (ni < 3), valueset = lFormatValueset(value); end
            
            % Parse first input argument.
            if ischar(name) || isstring(name) && isscalar(name)
               ID = paramid.Variable(char(name));
            elseif isa(name, 'paramid.ID')
               ID = name;
            elseif ni <= 2
               if ni == 2
                  valueset = lFormatValueset(value);
               else
                  valueset = lFormatValueset(name);
               end
               value = name;
               ID = [];
            else
               error(message('Controllib:modelpack:InvalidArgument', 'NAME/ID'))
            end
         else
            % Properties for no-argument constructor.
            ID       = [];
            value    = 0;
            valueset = lFormatValueset(0);
         end
         
         %Check that the value and valueset arguments  are valid, need to
         %do this check here as can't use property set methods during
         %construction
         if iscell(valueset) || isempty(valueset)
            error(message('Controllib:modelpack:errValueSetProperty'))
         end
         if ~param.Discrete.isValid(value,valueset)
            error(message('Controllib:modelpack:errNotValidValue'))
         end
         
         % Call superclass constructor.
         this = this@param.Tunable(ID);
         
         %Set parameter dimensions, do this before setting actual value to
         %avoid dimension check
         if param.Discrete.isValidElement(value,valueset)
            sz = [1 1];
         else
            %Must be array of elements, would not have passed isValid
            %check above otherwise.
            sz = size(value);
         end
         this.Size_ = sz;
         % Set valid set of discrete values first and then set value
         this.ValueSet       = valueset;
         this.Value          = value;
      end
   end % public methods
   
   methods
      %Get/Set methods for implemented abstract dependent Value property
      function this = set.Value(this,newvalue)
         try
            if ~param.Discrete.isValid(newvalue,this.ValueSet_)
               error(message('Controllib:modelpack:errNotValidValue'))
            end
            %Value cannot change dimension
            oldSize = this.Size_; 
            if param.Discrete.isValidElement(newvalue,this.ValueSet_)
               newSize = [1 1];
            else
               %Must be array of elements, would not have passed isValid
               %check above otherwise.
               newSize = size(newvalue);
            end
            if isequal(oldSize,newSize)
               this.Value_ = newvalue;
            else
               error(message('Controllib:modelpack:CannotFormatValueToSize','Value'));
            end
         catch E
            throwAsCaller(E)
         end
      end
      function val = get.Value(this)
         val = this.Value_;
      end
      %Get/Set methods for dependent ValueSet property
      function this = set.ValueSet(this,newvalue)
          %Check input type
          ok = isnumeric(newvalue)  ||  islogical(newvalue)  ||  isstring(newvalue);
          if ~ok
              error(message('Controllib:modelpack:errValueSetProperty'));
          end
          try
              if ~iscell(newvalue) && ~isempty(newvalue)
                  newvalue = lFormatValueset(newvalue);
                  this.ValueSet_ = newvalue;
                  if ~param.Discrete.isValid(this.Value_,this.ValueSet_)
                      %The current Value property is not an element of
                      %ValueSet, change it to an element
                      if isequal(this.Size_,[1 1])
                          this.Value_ = newvalue(1);
                      else
                          this.Value_ = repmat(newvalue(1), this.Size_);
                      end
                  end
              else
                  error(message('Controllib:modelpack:errValueSetProperty'))
              end
          catch E
              throwAsCaller(E)
          end
      end
      function val = get.ValueSet(this)
         val = this.ValueSet_;
      end
      %Get/Set methods for dependent Free property
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
   end % property methods
   
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
            value = logical(value);
         catch 
            error(message('Controllib:modelpack:LogicalArrayProperty', prop));
         end
         value = this.checkLogicalValue(value, prop);
         if isequal(value, default(ones(this.Size_)))
            value = [];
         end
      end
      function value = checkLogicalValue(this, value, prop)
         % Delegate method for subclass participation in logical value validation.
         value = this.formatValueToSize(value, prop);
      end
   end %sealed protected methods
   
   methods(Hidden = true, Static, Sealed, Access = protected)
       function b = isValidElement(value,valueset)
           %Checks that value is an element of valueset

           %Value cannot be empty
           if isempty(value)
               b = false;
               return
           end

           %Value must be same class as valueset
           if ~strcmp(class(value), class(valueset))
               b = false;
               return
           end

           if ~isscalar(value)
               b = false;
               return
           end

           b = ismember(value,valueset);
       end
      
      function b = isValid(value,valueset)
         %Checks that value is either an element from valueset or an array
         %of elements from value set
         
         b = false;
         for ct = 1:numel(value)
             val = value(ct);
             b = param.Discrete.isValidElement(val,valueset);
             if ~b
                 break
             end
         end
      end
   end % static sealed protected methods

   methods (Access = protected)
       function index = allowed2Index(this,x)
           %ALLOWED2INDEX Find index for allowed values
           index = NaN(size(x));   %preallocate
           for ct = 1:numel(index)
               index(ct) = find(x(ct) == this.ValueSet);
           end
       end

       function value = index2allowed(this,index)
           %INDEX2ALLOWED Find allowed value for indices

           %Preallocate
           if isnumeric(this.ValueSet)
               value = NaN(size(index));
           elseif isstring(this.ValueSet)
               value = strings(size(index));
           else
               error('sldo:general:errUnexpected','Unrecognized type of ValueSet')
           end

           %Convert from index to allowed value
           for ct = 1:numel(value)
               value(ct) = this.ValueSet(index(ct));
           end
       end
   end

   %API methods for param.Tunable
   methods (Access = protected)
       function [value,free] = vecElement(this)
           %VECELEMENT Get values in vector form
           %    The parameter object must be scalar
           %
           arguments
               this (1,1)
           end

           value = allowed2Index(this, this.Value);
           free  = this.Free;
       end

       function this = setPVecElement(this,pv)
           %SETPVECELEMENT Set parameter value, given a vector
           %   The parameter object should be sclar
           %
           arguments
               this (1,1)
               pv
           end

           this.Value(:) = index2allowed(this,pv); % Reshaped in set.Value
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

           %Map from value set to indices
           x = this.Value(this.Free);
           x = allowed2Index(this,x);
           oneVec = ones(numel(this.Free), 1);

           %Assign outputs
           x0       = x(:);
           xMin     = oneVec;
           xMax     = numel(this.ValueSet) * oneVec;
           xTypical = x0;
           xScale   = oneVec;
       end

       function p = vecToParForOptim(this,index)
           %VECTOPARFOROPTIM Convert vector to parameter for optimization
           %    Inputs
           %        this  - A scalar parameter object
           %        index - Vector of values for the parameter.  Should
           %                have number of elements = sum(this.Free).
           %
           arguments
               this (1,1)
               index
           end

           %Check that number of indices matches number of free elements
           if numel(index) ~= sum(this.Free)
               error(message('Controllib:modelpack:errVectorLengthIndex'));
           end

           %Set the parameter values
           p = setPVec(this,index,'free');
       end
   end

   methods (Hidden)
       function tf = isDiscrete(this) %#ok<MANU> 
           %ISDISCRETE Return whether object is discrete
           %    The parameter object must be scalar
           arguments
               this (1,1)
           end

           tf = true;
       end
   end
end % classdef

function valueset = lFormatValueset(valueset)
% Format valueset, making sure each element is unique

%Check valueset
lCheckValueset(valueset);

%Make value a row with unique elements
valueset = reshape(valueset,1,[]);
valueset = unique(valueset,'stable');
end

function lCheckValueset(valueset)
if iscell(valueset) || isempty(valueset)
    error(message('Controllib:modelpack:errValueSetProperty'))
end
end