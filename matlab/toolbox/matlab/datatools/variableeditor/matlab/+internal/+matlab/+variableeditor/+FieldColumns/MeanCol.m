classdef MeanCol <  internal.matlab.variableeditor.FieldColumns.StatColumn & ...
    internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Mean" Statistical Column display for scalar struct view. 

    % Copyright 2020 The MathWorks, Inc.   

     methods
        function this = MeanCol()
            this@internal.matlab.variableeditor.FieldColumns.StatColumn;
            this.HeaderName = "Mean";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Mean'));           
            this.Visible_I = false;
            this.ColumnIndex_I = 8;
        end       
      
        
       function fn = getShowNaNStatFunction(this)           
           fn = @mean;
         end
        
       function fn = getStatFunction(this)
           import internal.matlab.datatoolsservices.StatFunctionUtils;
           fn = @StatFunctionUtils.computeNaNMean;
       end
    end
end