classdef RangeCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn & ... 
    internal.matlab.variableeditor.FieldColumns.StatColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Range" Statistical Column display for scalar struct view. 

    % Copyright 2020 The MathWorks, Inc.   

     methods
        function this = RangeCol()
            this@internal.matlab.variableeditor.FieldColumns.StatColumn;
            this.HeaderName = "Range";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Range'));            
            this.Visible_I = false;
            this.ColumnIndex_I = 7;            
        end      
        
        function fn = getShowNaNStatFunction(this)
           import internal.matlab.datatoolsservices.StatFunctionUtils;
           fn = @StatFunctionUtils.computeRange;
       end
        
       function fn = getStatFunction(this)
           import internal.matlab.datatoolsservices.StatFunctionUtils;
           fn = @StatFunctionUtils.computeNaNRange;
       end
    end
end