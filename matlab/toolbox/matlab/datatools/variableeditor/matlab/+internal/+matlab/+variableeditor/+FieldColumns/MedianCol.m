classdef MedianCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn & ... 
    internal.matlab.variableeditor.FieldColumns.StatColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Median" Statistical Column display for scalar struct view. 

    % Copyright 2020 The MathWorks, Inc.      

     methods
        function this = MedianCol()
            this@internal.matlab.variableeditor.FieldColumns.StatColumn;
            this.HeaderName = "Median";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Median'));            
            this.Visible_I = false;
            this.ColumnIndex_I = 9;            
        end    
        
        function fn = getShowNaNStatFunction(this)           
           fn = @median;
         end
        
       function fn = getStatFunction(this, data)
           import internal.matlab.datatoolsservices.StatFunctionUtils;
           fn = @StatFunctionUtils.computeNaNMedian;
       end
    end
end