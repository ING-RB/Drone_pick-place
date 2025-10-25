classdef ScaleDirection < internal.matlab.editorconverters.datatype.StringEnumerationWithIcon
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Data Type for 'ScaleDirection' of Gauges
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Constant)
        IconNames = ["rotateClockwise", "rotateCounterclockwise"];
        
        EnumeratedValues = {...
            'clockwise', ...
            'counterclockwise' ...
            }
    end
    
    properties(Access = private)
        Value
    end
    
    methods
        function this = ScaleDirection(val)
            if ismember(val, inspector.internal.datatype.ScaleDirection.EnumeratedValues)
                this.Value = val;
            end
        end
        
        function val = getValue(this)
            val = this.Value;
        end
    end
end