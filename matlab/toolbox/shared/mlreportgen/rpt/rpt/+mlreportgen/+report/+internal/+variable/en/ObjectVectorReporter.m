classdef ObjectVectorReporter< mlreportgen.report.internal.variable.VariableReporter
% ObjectVectorReporter Reports on a variable whose value is a vector of
% structure-like objects, e.g., MATLAB struct, MCOS, and UDD objects.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=ObjectVectorReporter
            % this = ObjectVectorReporter(reportOptions, varName, varValue)
            % creates a reporter for an object vector variable
            % varName/varValue.
        end

        function out=getLeftBracket(~) %#ok<STOUT>
            % Returns the left bracket for this vector to be displayed in
            % the report. Derived classes can override this method to
            % return its own left bracket string.
        end

        function out=getRightBracket(~) %#ok<STOUT>
            % Returns the right bracket for this vector to be displayed in
            % the report. Derived classes can override this method to
            % return its own right bracket string.
        end

        function out=getTextualContent(~) %#ok<STOUT>
            % Override the base class method to provide the textual content
            % to be reported
        end

        function out=getVectorElement(~) %#ok<STOUT>
            % Returns the vector element value at the specified index.
            % Derived classes can override this method to get the element
            % value.
        end

        function out=makeAutoReport(~) %#ok<STOUT>
            % content = makeAutoReport(this) reports on the variable as a
            % paragraph
        end

        function out=makeTabularReport(~) %#ok<STOUT>
            % baseTable = makeTabularReport(this) generates a table
            % that contains entries for the variable value and the
            % variable's data type.
        end

    end
end
