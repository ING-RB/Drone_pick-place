classdef FontAngle < internal.matlab.editorconverters.datatype.BinaryStringEnumerationWithIcon
	% Used to show normal/italic font as an icon

	% Copyright 2017-2023 The MathWorks, Inc.

    properties(Constant)
        IconName = "italicTextUI";
        
        EnumeratedValues = {...
            'normal', ...
            'italic', ...
            }
    end
    
    properties
        Value
    end
    
    methods
        function this = FontAngle(val)
            if ismember(val,internal.matlab.editorconverters.datatype.FontAngle.EnumeratedValues)
                this.Value = val;
            end
        end
        
        function val = getValue(this)
            val = this.Value;
        end
    end
end
