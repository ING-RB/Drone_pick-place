classdef(Hidden = true) ID
   %
   
   % ID abstract parent class for all parameter identifier classes
   %
   
   % Copyright 2009-2014 The MathWorks, Inc.
   
  properties
      Name = '';
      Path = '';
   end %public  properties
   
   properties (GetAccess = protected, SetAccess = protected)
      Version = param.version;
   end % protected properties
      
   methods (Access = protected)
      function this = ID(name, path)
         % Constructor
         %
         % paramid.ID(name, [path])
         ni = nargin;
         if ni > 0
            narginchk(1,2)
             
            % Default arguments
            if (ni < 2 || isempty(path)), path = ''; end
            
            % Set properties.
            this.Name = name;
            this.Path = path;
         end
      end
      
   end %protected methods
   
   methods (Access = public)
      function name = getFullName(this)
         % Returns the unique full name of the variable identified by object.
         name = this.Name;
         path = this.Path;
         if ~isempty(path)
             if iscellstr(path)
                 allPath = path;
                 path = allPath{1};
                 for ct = 1:numel(allPath)-1
                     path = sprintf('%s|%s',path,allPath{ct+1});
                 end
             end
             % Prefix non-empty path.
             name = sprintf('%s:%s', path, name);
         end
      end
      function disp(this)
         paramid.array_display(this);
      end
      function display(this)
         paramid.array_display(this, inputname(1));
      end
   end %public methods
   
   methods
      function this = set.Name(this, value)
         if ~ischar(value)
            ctrlMsgUtils.error('Controllib:modelpack:StringProperty','Name')
         end
         this.Name = value;
      end
      function this = set.Path(this, value)
         if ischar(value) || iscellstr(value)
            this.Path = value;
         else
            ctrlMsgUtils.error('Controllib:modelpack:StringArrayProperty','Path')
         end
      end
   end % property methods
   
end % classdef
