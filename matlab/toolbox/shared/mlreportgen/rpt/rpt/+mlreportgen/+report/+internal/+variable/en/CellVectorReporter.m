classdef CellVectorReporter< mlreportgen.report.internal.variable.ObjectVectorReporter
% CellVectorReporter Reports on a variable whose value is a cell
% vector.

     
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=CellVectorReporter
            % this = CellVectorReporter(reportOptions, varName, varValue)
            % creates a reporter for a cell vector variable
            % varName/varValue.
        end

        function out=getLeftBracket(~) %#ok<STOUT>
            % Override the base class method to return the left bracket for
            % this cell vector to be displayed in the report.
        end

        function out=getRightBracket(~) %#ok<STOUT>
            % Override the base class method to return the right bracket
            % for this cell vector to be displayed in the report.
        end

        function out=getVectorElement(~) %#ok<STOUT>
            % Overriding the base class method to the return the cell
            % vector element value at the specified index.
        end

    end
end
