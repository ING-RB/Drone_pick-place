classdef(Hidden = true) Port < param.Continuous
   % 
   
   % Construct a model port parameter
   
   % Copyright 2009-2014 The MathWorks, Inc.
   
   methods (Access = public)
      function this = Port(ID, value)
         % Construct a param.Port object
         %
         % param.Port(id, [value])
         % param.Port
         ni = nargin;
         if (ni > 0)
            narginchk(1,2)
            
            % Default arguments
            if (ni < 2), value = 0; end
            
            % Make sure ID property is for a port
            if ~isa(ID, 'paramid.Port')
               ctrlMsgUtils.error('Controllib:modelpack:InvalidArgument', 'NAME/ID')
            end
         else
            % Properties for no-argument constructor.
            ID = paramid.Port;
            value = 0;
         end
         
         % Call superclass constructor first.
         this = this@param.Continuous(ID, value);
      end
   end % public methods
   
end % classdef
