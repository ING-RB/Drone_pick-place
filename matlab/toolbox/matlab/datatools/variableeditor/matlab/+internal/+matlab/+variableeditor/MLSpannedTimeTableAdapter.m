classdef MLSpannedTimeTableAdapter < internal.matlab.variableeditor.MLTimeTableAdapter
    %MLSpannedTableAdapter
    %   MATLAB Table Variable Editor Mixin
    
    % Copyright 2023 The MathWorks, Inc.
    
    
    methods
        function view = createView(this)
            view = internal.matlab.variableeditor.SpannedTimeTableViewModel(this.DataModel);
        end
    end
    
    methods(Static)
        function c = getClassType()
            c = internal.matlab.variableeditor.MLTimeTableDataModel.ClassType;
        end
    end
end

