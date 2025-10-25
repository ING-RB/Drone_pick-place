classdef StringReporter< mlreportgen.report.internal.variable.VariableReporter
% StringReporter Reports on character or string data type variables

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=StringReporter
            % this = StringReporter(reportOptions, varName, varValue)
            % creates a reporter for the string variable varName/varValue.
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
