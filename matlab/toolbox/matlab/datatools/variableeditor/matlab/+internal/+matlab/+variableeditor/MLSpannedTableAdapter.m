classdef MLSpannedTableAdapter < internal.matlab.variableeditor.MLTableAdapter
    %MLSpannedTableAdapter
    %   MATLAB Table Variable Editor Mixin
    
    % Copyright 2023 The MathWorks, Inc.
    
    
    methods
        function view = createView(this)
            view = internal.matlab.variableeditor.SpannedTableViewModel(this.DataModel);
        end
    end
    
    methods(Static)
        function c = getClassType()
            c = internal.matlab.variableeditor.MLTableDataModel.ClassType;
        end
    end
end

