classdef FontWeight < internal.matlab.editorconverters.datatype.BinaryStringEnumerationWithIcon
	% Used to show normal/bold font as an icon

	% Copyright 2017-2023 The MathWorks, Inc.

    properties(Constant)
        IconName = "boldTextUI";
        
        EnumeratedValues = {...
            'normal', ...
            'bold', ...
            }
    end
    
    properties
        Value
    end
    
    methods
        function this = FontWeight(val)
            if ismember(val,internal.matlab.editorconverters.datatype.FontWeight.EnumeratedValues)
                this.Value = val;
            end
        end
        
        function val = getValue(this)
            val = this.Value;
        end
    end
end
