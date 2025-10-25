classdef LogicalArrayReporter< mlreportgen.report.internal.variable.ArrayReporter
% LogicalArrayReporter Reports on a variable whose value is an array of
% logical (true/false) values.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=LogicalArrayReporter
            % this = LogicalArrayReporter(reportOptions, varName, varValue)
            % creates a reporter for logical array variable
            % varName/varValue.
        end

        function out=getTableContent(~) %#ok<STOUT>
            % Implement the base class abstract method to return a DOM
            % Table consisting of the logical array values as text, i.e.,
            % "true" or "false".
        end

        function out=getTextValue(~) %#ok<STOUT>
            % Overriding the method to convert each logical value in the
            % array to a string value for reporting
        end

        function out=makeParaReport(~) %#ok<STOUT>
            % Reports on logical array variable in a paragraph form.
        end

    end
end
