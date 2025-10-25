classdef(Hidden = true) String < param.Parameter
   %
   
   % Construct a string parameter
   %
   
   % Copyright 2009-2016 The MathWorks, Inc.
   
   properties(Dependent)
      Value
   end % Implemented superclass abstract properties
   
   methods (Access = public)
      function this = String(name, value)
         % Construct a param.String object
         %
         % param.String(name, [value])
         % param.String(id, [value])
         % param.String(value) value must be cell to distinguish from String(name)
         % param.String
         ni = nargin;
         if (ni > 0)
            narginchk(1,2)
            
            % Default arguments
            if (ni < 2), value = ''; end
            
            % Parse first input argument.
            if ischar(name) || isstring(name) && isscalar(name)
               ID = paramid.Variable(char(name));
            elseif iscellstr(name) || isstring(name) || ...
                    iscell(name) && all(cellfun(@(x)isstring(x),name))
               ID = [];
               if isstring(name)
                   name = cellstr(name);
               end
               if numel(name) == 1
                  value = name{1};
               else
                  value = name;
               end
            elseif isa(name, 'paramid.ID')
               ID = name;
            else
               error(message('Controllib:modelpack:InvalidArgument', 'NAME/ID'))
            end
         else
            % Properties for no-argument constructor.
            ID = [];
            value = '';
         end
         
         % Call superclass constructor first.
         this = this@param.Parameter(ID);
         
         %Set parameter dimensions, do this before setting actual value to
         %avoid dimension check
         if iscellstr(value) || ...
                 iscell(value) && all(cellfun(@(x)isstring(x)&&isscalar(x),value))
            sz = size(value);
         else
            sz = [1 1];
         end
         this.Size_ = sz;
         % Set value property
         this.Value  = value;
      end
   end % public methods
   
   methods
      %Get/Set methods for implemented abstract dependent Value property
      function this = set.Value(this,newvalue)
         try
            %Value must be a string or cell array of strings
            if isstring(newvalue)
                if isscalar(newvalue)
                    newvalue = char(newvalue);
                else
                    newvalue = cellstr(newvalue);
                end
            end
            if iscell(newvalue)
                if all(cellfun(@(x) isstring(x)&&isscalar(x),newvalue))
                    for ct=1:numel(newvalue)
                        newvalue{ct} = char(newvalue{ct});
                    end
                end
            end
            if ~ischar(newvalue) &&  ~iscellstr(newvalue)
               error(message('Controllib:modelpack:StringArrayProperty','Value'))
            end
            %Value cannot change dimension
            if iscellstr(newvalue)
               newSize = size(newvalue);
            else
               newSize = [1 1];
            end
            if isequal(this.Size_,newSize)
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
   end % property methods
end
