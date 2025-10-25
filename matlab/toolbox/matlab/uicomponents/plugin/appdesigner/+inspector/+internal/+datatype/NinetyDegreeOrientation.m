classdef NinetyDegreeOrientation  < internal.matlab.editorconverters.datatype.StringEnumerationWithIcon
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Constant)
        IconNames = ["northwestOrientationUI", ...
            "northeastOrientationUI", ...
            "southeastOrientationUI", ...
            "southwestOrientationUI"];
        
        EnumeratedValues = {...
            'northwest', ...
            'northeast', ...
            'southwest', ...
            'southeast' ...
            }
    end
    
    properties(Access = private)
        Value
    end
    
    methods
        function this = NinetyDegreeOrientation(val)
            if ismember(val, inspector.internal.datatype.NinetyDegreeOrientation.EnumeratedValues)
                this.Value = val;
            end
        end
        
        function val = getValue(this)
            val = this.Value;
        end
    end
end
