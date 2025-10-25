classdef ImageVerticalAlignment < internal.matlab.editorconverters.datatype.StringEnumerationWithIcon
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Constant)
        IconNames = ["alignTop", "alignVerticalCenter", "alignBottom"];
        
        EnumeratedValues = {...
            'top', ...
            'center' ...
            'bottom' ...
            }
    end
    
    properties(Access = private)
        Value
    end
    
    methods
        function this = ImageVerticalAlignment(val)
            if ismember(val, inspector.internal.datatype.ImageVerticalAlignment.EnumeratedValues)
                this.Value = val;
            end
        end
        
        function val = getValue(this)
            val = this.Value;
        end
    end
end
