classdef State < paramid.ID
   % STATE parameter identifier for a state
   
   % Copyright 2009-2020 The MathWorks, Inc.
   
   properties (GetAccess = public, SetAccess = public)
      Ts = 0;
   end % properties
   
   methods (Access = public)
      function this = State(name, path, Ts)
         % Constructor
         %
         % paramid.State(name, [path], [Ts])
         ni = nargin;
         
         % Superclass constructor arguments.
         args = {};
         if (ni == 1)
            args{1} = name;
         elseif (ni >= 2)
            args{1} = name;
            args{2} = path;
         end
         this = this@paramid.ID(args{:});
         
         if (ni > 0)
            narginchk(1, 3)
            
            % Default arguments
            if (ni < 3), Ts = 0; end
            
            % Set properties, using scalar expansion if necessary.
            this.Ts = Ts;
         end
      end
      
      function name = getFullName(this)
         % Returns the unique full name of the variable identified by object.
         
         % Construct the full name
         if isempty(this.Name)
             name = this.Path;
         else
            name = sprintf('%s:%s', this.Path, this.Name);
         end
      end
   end % public methods
   
   methods
      function this = set.Ts(this, value)
         if (~isnumeric(value) || ~isreal(value) || any(value<0) ...
               || any(isnan(value)) || ~all(isfinite(value)) ) && ...
               ~iscell(value)   % Ts may be a cell, g2251633
            error(message('Controllib:modelpack:NonNegativeReal','Ts'))
         end
         this.Ts = value;
      end
      function value = properties(this) %#ok<MANU>
         value = properties('paramid.ID');
         value = [value; 'Ts'];
      end
   end % property methods
   
end % classdef
