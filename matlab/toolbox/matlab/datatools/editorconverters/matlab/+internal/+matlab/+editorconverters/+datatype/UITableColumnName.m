classdef UITableColumnName 
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2017 The MathWorks, Inc.

    properties
       ColumnName;
    end
    
    methods
        function this = UITableColumnName(v)
            this.ColumnName = v;
        end
        
        function v = getName(this)
            v = this.ColumnName;
        end
    end
end
