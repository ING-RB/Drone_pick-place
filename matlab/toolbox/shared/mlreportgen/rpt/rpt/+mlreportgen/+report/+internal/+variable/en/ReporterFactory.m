classdef ReporterFactory< handle
% ReporterFactory creates variable reporters capable of handling
% various MATLAB data types.
%
% Use the static method
% mlreportgen.report.internal.variable.ReporterFactory.makeReporter
% providing the variable name, variable value, and the variable
% reporting options. This method will create and return an appropriate
% variable reporter object based on the variable data type.

     
    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=ReporterFactory
        end

        function out=makeReporter(~) %#ok<STOUT>
            % makeReporter creates a reporter object that knows how to
            % create a report for a variable that best describes the
            % variable's value.
            %
            % Factory supports following data type variable reporters:
            %   - StringReporter
            %   - LogicalScalarReporter
            %   - LogicalVectorReporter
            %   - NumericScalarReporter
            %   - NumericVectorReporter
            %   - XMLDocReporter
            %   - StructureReporter
            %   - HGObjectReporter
            %   - MCOSObjectReporter
            %   - UDDObjectReporter
            %   - SimulinkObjectReporter
            %   - MATLABTableReporter
            %   - ObjectVectorReporter
            %   - CellVectorReporter
            %   - LogicalArrayReporter
            %   - NumericArrayReporter
            %   - ObjectArrayReporter
            %   - CellArrayReporter
            %   - EnumerationReporter
        end

    end
end
