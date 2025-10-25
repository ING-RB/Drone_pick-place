classdef HolesInfo < handle
    %HolesInfo Contains template holes info
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
   properties (Dependent)
      Ids
   end
    
    methods
        function this = HolesInfo()
            this.map = containers.Map;    
            this.keys = {};
        end
            function ids = get.Ids(self)
            ids = self.keys;
        end
        
        function add(self, holeInfo)
            self.map(holeInfo.HoleId) = holeInfo;
            self.keys{end+1} = holeInfo.HoleId;
        end        
        
        function iskey = isKey(self, key)
            iskey = self.map.isKey(key);
        end
        
        function hole = getHole(self,id)
            hole = self.map(id);
        end
    end
    
    properties (Access = private)        
        map = containers.Map;    
        keys = {};
    end
    
end

