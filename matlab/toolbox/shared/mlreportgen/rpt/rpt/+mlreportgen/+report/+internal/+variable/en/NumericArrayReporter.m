classdef NumericArrayReporter< mlreportgen.report.internal.variable.ArrayReporter
% NumericArrayReporter Reports on a variable whose value is a numeric
% array.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=NumericArrayReporter
            % this = NumericArrayReporter(reportOptions, varName, varValue)
            % creates a reporter for numeric array variable
            % varName/varValue.
        end

        function out=getTableContent(~) %#ok<STOUT>
            % Implement the base class abstract method to return a DOM
            % Table consisting of the numeric array values.
        end

        function out=getTextualContent(~) %#ok<STOUT>
            % Override the base class method to return the textual content.
            % Get textual content by calling the base class method and then
            % normalize the content string. Normalizing the content string
            % is done to remove any unnecessary line breaks in the content
            % after each row in the array.
        end

        function out=makeParaReport(~) %#ok<STOUT>
            % Reports on numeric array variable in a paragraph form.
        end

    end
end
