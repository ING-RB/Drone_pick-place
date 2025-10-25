classdef VarCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn & ... 
    internal.matlab.variableeditor.FieldColumns.StatColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Var" Statistical Column display for scalar struct view. 

    % Copyright 2020 The MathWorks, Inc.   

     methods
        function this = VarCol()
            this@internal.matlab.variableeditor.FieldColumns.StatColumn;
            this.HeaderName = "Var";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Var'));            
            this.Visible_I = false;
            this.ColumnIndex_I = 11;                      
        end      
      
        
        function fn = getShowNaNStatFunction(this)
          fn = this.getStatFunction();
         end
        
       function fn = getStatFunction(this)           
           fn = @var;
       end
    end
end