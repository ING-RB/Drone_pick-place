classdef StdCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn & ... 
    internal.matlab.variableeditor.FieldColumns.StatColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Std" Statistical Column display for scalar struct view. 

    % Copyright 2020 The MathWorks, Inc.   

     methods
        function this = StdCol()
            this@internal.matlab.variableeditor.FieldColumns.StatColumn;
            this.HeaderName = "Std";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Std'));            
            this.Visible_I = false;
            this.ColumnIndex_I = 12;                       
        end      
        
        function fn = getShowNaNStatFunction(this)
          fn = @std;
         end
        
       function fn = getStatFunction(this)
           import internal.matlab.datatoolsservices.StatFunctionUtils;
           fn = @StatFunctionUtils.computeNaNStd;
       end
    end
end