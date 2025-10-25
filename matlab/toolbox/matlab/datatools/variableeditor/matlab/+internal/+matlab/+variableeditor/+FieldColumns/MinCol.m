classdef MinCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn & ... 
    internal.matlab.variableeditor.FieldColumns.StatColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Min" Statistical Column display for scalar struct view. 

    % Copyright 2020 The MathWorks, Inc.

     methods
        function this = MinCol()
            this.HeaderName = "Min";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Min'));            
            this.Visible_I = false;
            this.ColumnIndex_I = 5;            
        end  
       
        
       function fn = getShowNaNStatFunction(this)
           import internal.matlab.datatoolsservices.StatFunctionUtils;
           fn = @StatFunctionUtils.computeMin;
       end
        
       function fn = getStatFunction(this, data)
           fn = @min;
       end
    end
end

