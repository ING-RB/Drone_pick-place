classdef BlockParameter < paramid.ID
   % BLOCKPARAMETER parameter identifier for a Simulink block
   
   % Copyright 2009 The MathWorks, Inc.
  
   methods (Access = public)
      function this = BlockParameter(name, path)
         % Constructor
         %
         % paramid.BlockParameter(name, [path])
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
      end %BlockParameterID
   end % public methods
   
end % classdef
