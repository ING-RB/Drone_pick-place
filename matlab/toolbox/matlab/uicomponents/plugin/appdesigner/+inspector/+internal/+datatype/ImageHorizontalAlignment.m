classdef ImageHorizontalAlignment < internal.matlab.editorconverters.datatype.StringEnumerationWithIcon
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Constant)
        IconNames = ["alignLeft", "alignHorizontalCenter", "alignRight"];
        
        EnumeratedValues = {...
            'left', ...
            'center' ...
            'right' ...
            }
    end
    
    properties(Access = private)
        Value
    end
    
    methods
        function this = ImageHorizontalAlignment(val)
            if ismember(val, inspector.internal.datatype.ImageHorizontalAlignment.EnumeratedValues)
                this.Value = val;
            end
        end
        
        function val = getValue(this)
            val = this.Value;
        end
    end
end
