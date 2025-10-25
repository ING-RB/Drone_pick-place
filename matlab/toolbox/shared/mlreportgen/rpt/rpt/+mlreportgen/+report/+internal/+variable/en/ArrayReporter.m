classdef ArrayReporter< mlreportgen.report.internal.variable.VariableReporter
% ArrayReporter is the base class for reporters that reports on
% numeric, logical, object, and cell arrays.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=ArrayReporter
        end

        function out=make2DArrayReporters(~) %#ok<STOUT>
            % make2DArrayReporters(this, array, arrayName, history)
            % recursively generates a reporter for each of the
            % 2-dimensional slices of the multi-dimensional array.
        end

        function out=makeAutoReport(~) %#ok<STOUT>
            % content = makeAutoReport(this) creates a tabular report for
            % the array owned by this reporter
        end

        function out=makeTabularReport(~) %#ok<STOUT>
            % baseTable = makeTabularReport(this) generates a table with
            % enteries as array data
        end

    end
    methods (Abstract)
        % Abstract method to get the table content when reporting in a
        % tabular form
        getTableContent;

    end
end
