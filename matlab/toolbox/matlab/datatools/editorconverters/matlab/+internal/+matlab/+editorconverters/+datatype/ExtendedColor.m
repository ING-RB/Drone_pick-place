classdef ExtendedColor
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2017-2018 The MathWorks, Inc.

    properties(Access = private)
        Color;
    end
    
    methods
        function this = ExtendedColor(v)
            this.Color = v;
        end
        
        function v = getColor(this)
            v = this.Color;
        end
    end
end
