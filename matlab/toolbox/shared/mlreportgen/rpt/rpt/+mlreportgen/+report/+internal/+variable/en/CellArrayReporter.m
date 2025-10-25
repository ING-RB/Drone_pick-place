classdef CellArrayReporter< mlreportgen.report.internal.variable.ObjectArrayReporter
% CellArrayReporter Reports on a variable whose value is a cell array.

     
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=CellArrayReporter
            % this = CellArrayReporter(reportOptions, varName, varValue)
            % makes a reporter for the cell array variable
            % varName/varValue.
        end

        function out=getArrayElement(~) %#ok<STOUT>
            % Override base class method to return the cell array element
            % at the specified row and column index.
        end

        function out=getLeftBracket(~) %#ok<STOUT>
            % Override the base class method to return the left bracket for
            % this cell array to be displayed in the report.
        end

        function out=getRightBracket(~) %#ok<STOUT>
            % Override the base class method to return the right bracket
            % for this cell array to be displayed in the report.
        end

    end
end
