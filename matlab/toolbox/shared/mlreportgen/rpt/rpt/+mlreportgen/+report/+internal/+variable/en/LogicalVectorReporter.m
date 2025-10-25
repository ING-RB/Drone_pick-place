classdef LogicalVectorReporter< mlreportgen.report.internal.variable.StringReporter
% LogicalVectorReporter Reports on a variable whose value is a 1D array
% of logical values

     
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=LogicalVectorReporter
            % this = LogicalVectorReporter(reportOptions, varName, varValue)
            % creates a reporter for a logical vector variable
            % varName/Value.
        end

        function out=getTextValue(~) %#ok<STOUT>
            % Overriding the method to convert each logical value in the
            % vector to a string value for reporting
        end

    end
end
