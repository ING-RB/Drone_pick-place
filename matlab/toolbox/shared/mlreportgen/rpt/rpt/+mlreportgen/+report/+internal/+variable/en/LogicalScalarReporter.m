classdef LogicalScalarReporter< mlreportgen.report.internal.variable.StringReporter
% LogicalScalarReporter Reports on a variable whose value is a logical
% scalar

     
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=LogicalScalarReporter
            % this = LogicalScalarReporter(reportOptions, varName, varValue)
            % creates a reporter for a logical scalar variable
            % varName/Value.
        end

        function out=getTextValue(~) %#ok<STOUT>
            % Overriding the method to return string value for the
            % variable's logical value
        end

    end
end
