classdef MaxCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn & ... 
    internal.matlab.variableeditor.FieldColumns.StatColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Max" Statistical Column display for scalar struct view. 

    % Copyright 2020 The MathWorks, Inc.   

     methods
        function this = MaxCol()
            this.HeaderName = "Max";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Max'));            
            this.Visible_I = false;
            this.ColumnIndex_I = 6;                      
        end     
        
         function fn = getShowNaNStatFunction(this)
           import internal.matlab.datatoolsservices.StatFunctionUtils;
           fn = @StatFunctionUtils.computeMax;
         end
        
       function fn = getStatFunction(this, data)
           fn = @max;
       end
    end
end

