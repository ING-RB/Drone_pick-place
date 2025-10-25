classdef MATLABTableReporter< mlreportgen.report.internal.variable.VariableReporter
% MATLABTableReporter Reports on MATLAB table objects.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=MATLABTableReporter
            % this = MATLABTableReporter(reportOptions, varName, varValue)
            % creates a reporter for the MATLAB table variable
            % varName/varValue.
        end

        function out=makeAutoReport(~) %#ok<STOUT>
            % content = makeAutoReport(this) reports on the variable in a
            % tabular form
        end

        function out=makeTabularReport(~) %#ok<STOUT>
            % content = makeTabularReport(this) generates a table using
            % the DOM MATLABTable. If the input MATLAB table object is
            % empty, it returns a paragraph with note to notify to the
            % user.
        end

    end
end
