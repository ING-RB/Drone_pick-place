classdef ModeCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn & ... 
    internal.matlab.variableeditor.FieldColumns.StatColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Mode" Statistical Column display for scalar struct view. 

    % Copyright 2020 The MathWorks, Inc.   

     methods
        function this = ModeCol()
            this@internal.matlab.variableeditor.FieldColumns.StatColumn;
            this.HeaderName = "Mode";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Mode'));
            this.Visible_I = false;
            this.ColumnIndex_I = 10;            
        end
        
        function fn = getShowNaNStatFunction(this)
          fn = this.getStatFunction();
         end
        
       function fn = getStatFunction(this)
           import internal.matlab.datatoolsservices.StatFunctionUtils;
           fn = @StatFunctionUtils.computeMode;
       end
    end
end