classdef UDDObjectReporter< mlreportgen.report.internal.variable.StructuredObjectReporter
% UDDObjectReporter Reports on a variable whose value is a UDD object.

 
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=UDDObjectReporter
            % this = UDDObjectReporter(reportOptions, varName, varValue)
            % creates a reporter for a UDD object variable with
            % varName/varValue.
        end

        function out=getObjectProperties(~) %#ok<STOUT>
            % Implementing the abstract method from the base class to
            % return the UDD object's property names to report on.
        end

        function out=isFilteredProperty(~) %#ok<STOUT>
            % Overriding base class method to verify if the specified
            % property needs to be filtered based on the reporter's report
            % options
        end

    end
end
