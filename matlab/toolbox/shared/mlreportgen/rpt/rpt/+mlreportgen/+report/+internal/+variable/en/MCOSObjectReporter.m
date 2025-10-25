classdef MCOSObjectReporter< mlreportgen.report.internal.variable.StructuredObjectReporter
% MCOSObjectReporter Reports for a variable whose value is a MCOS
% object.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=MCOSObjectReporter
            % this = MCOSObjectReporter(reportOptions, varName, varValue)
            % creates a reporter for a MCOS object variable
            % varName/varValue.
        end

        function out=getObjectProperties(~) %#ok<STOUT>
            % Implementing the abstract method from the base class to
            % return the MCOS object's property names to report on.
        end

        function out=isFilteredProperty(~) %#ok<STOUT>
            % Overriding base class method to verify if the specified
            % property needs to be filtered based on the reporter's report
            % options
        end

    end
end
