classdef EnumerationReporter< mlreportgen.report.internal.variable.VariableReporter
% EnumerationReporter Reports on an enumerated value of a variable
% this = EnumerationReporter(reportOptions,varName,varValue) creates a
% reporter that reports on the value (varValue) of the MATLAB variable varName.
% The specified value is assumed to be an instance of an enumeration class.

     
    % Copyright 2020 The MathWorks, Inc.

    methods
        function out=EnumerationReporter
        end

        function out=makeAutoReport(~) %#ok<STOUT>
            % content = makeAutoReport(this) reports on the variable as a
            % paragraph or a table depending on whether the enumeration
            % class defines properties for member data. If the enumeration
            % class defines properties then report the variable as a table,
            % otherwise, report it as a paragraph.
        end

        function out=makeTabularReport(~) %#ok<STOUT>
            % content = makeTabularReport(this) reports on the variable as
            % a table. If the enumerated variable does not have properties,
            % the generated table contains the enumerated value and its
            % data type(enumeration class name).Otherwise, the table
            % contains the enumerated value and the values of its properties.
        end

    end
end
