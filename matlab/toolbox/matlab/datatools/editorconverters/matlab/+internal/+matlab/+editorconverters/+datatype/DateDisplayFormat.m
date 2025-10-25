classdef DateDisplayFormat
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018 The MathWorks, Inc.

    properties(Access = private)
        displayFormat;
    end
    
    methods
        function this = DateDisplayFormat(v)
            this.displayFormat = v;
        end
        
        function v = getDisplayFormat(this)
            v = this.displayFormat;
        end
    end
end
