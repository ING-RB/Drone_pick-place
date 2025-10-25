classdef ObjectArrayReporter< mlreportgen.report.internal.variable.ArrayReporter
% ObjectArrayReporter Reports on array of objects like structures, MCOS
% objects, or UDD objects.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=ObjectArrayReporter
            % this = ObjectArrayReporter(reportOptions, varName, varValue)
            % creates a reporter for an object array variable
            % varName/varValue.
        end

        function out=getArrayElement(~) %#ok<STOUT>
            % Returns the object array element at the specified row and
            % column index. Derived classes can override this method to get
            % the element value.
        end

        function out=getLeftBracket(~) %#ok<STOUT>
            % Returns the left bracket for this array to be displayed in
            % the report. Derived classes can override this method to
            % return its own left bracket string.
        end

        function out=getRightBracket(~) %#ok<STOUT>
            % Returns the right bracket for this array to be displayed in
            % the report. Derived classes can override this method to
            % return its own right bracket string.
        end

        function out=getTableContent(~) %#ok<STOUT>
            % Implement the base class abstract method to return a DOM
            % Table consisting of the object array values.
        end

        function out=getTextValue(~) %#ok<STOUT>
            % Overriding the method to convert each logical value in the
            % array to a string value for reporting
        end

        function out=makeParaReport(~) %#ok<STOUT>
            % Reports on object array variable in a paragraph form.
        end

    end
end
