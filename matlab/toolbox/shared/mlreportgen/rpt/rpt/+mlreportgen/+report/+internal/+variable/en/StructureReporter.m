classdef StructureReporter< mlreportgen.report.internal.variable.StructuredObjectReporter
% StructureReporter Reports on a variable whose value is a MATLAB
% struct object.

     
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=StructureReporter
            % this = StructureReporter(reportOptions, varName, varValue)
            % creates a reporter for a MATLAB struct variable
            % varName/varValue.
        end

        function out=getObjectProperties(~) %#ok<STOUT>
            % Implementing the abstract method from the base class to
            % return the struct field names to report on.
        end

        function out=getTableHeader(~) %#ok<STOUT>
            % Overriding the base class method to return the header row
            % when the variable is reported in tabular form.
        end

    end
end
