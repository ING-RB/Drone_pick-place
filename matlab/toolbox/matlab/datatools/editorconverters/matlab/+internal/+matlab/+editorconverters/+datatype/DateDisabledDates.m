classdef DateDisabledDates
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018 The MathWorks, Inc.

    properties(Access = private)
        DisabledDates;
    end
    
    methods
        function this = DateDisabledDates(v)
            this.DisabledDates = v;
        end
        
        function v = getDisabledDates(this)
            v = this.DisabledDates;
        end
    end
end
