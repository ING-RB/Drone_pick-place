classdef DateDisabledDaysOfWeek
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018 The MathWorks, Inc.

    properties(Access = private)
        disabledDaysOfWeek;
    end
    
    methods
        function this = DateDisabledDaysOfWeek(v)
            this.disabledDaysOfWeek = v;
        end
        
        function v = getDisabledDaysOfWeek(this)
            if isnumeric(this.disabledDaysOfWeek)
                v = this.disabledDaysOfWeek;
            else
                v = str2num(this.disabledDaysOfWeek); %#ok<ST2NM>
            end
        end
    end
end
