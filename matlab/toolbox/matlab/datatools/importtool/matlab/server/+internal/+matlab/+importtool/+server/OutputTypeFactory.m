% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is a factory which returns the appropriate OutputType Matlab class
% based on the output type, either in text or as a Java class name.

% Copyright 2018-2019 The MathWorks, Inc.

classdef OutputTypeFactory
    methods(Static)
        function v = getOutputTypeFromText(outputType)
            % Returns the OutputType class based on the input text
            % The outputType argument is expected to be one of the following:
            % - numericarray
            % - cellarray
            % - stringarray
            % - dataset
            % - table
            % - columnvector
            switch lower(outputType)
                case "numericarray"
                    v = internal.matlab.importtool.server.output.NumericArrayOutputType;
                case "cellarray"
                    v = internal.matlab.importtool.server.output.CellArrayOutputType;
                case "stringarray"
                    v = internal.matlab.importtool.server.output.StringArrayOutputType;
                case "dataset"
                    v = internal.matlab.importtool.server.output.DatasetArrayOutputType;
                case "table"
                    v = internal.matlab.importtool.server.output.TableOutputType;
                case "timetable"
                    v = internal.matlab.importtool.server.output.TimeTableOutputType;
                case "columnvector"
                    v = internal.matlab.importtool.server.output.ColumnVectorOutputType;
                otherwise
                    % default to table
                    v = internal.matlab.importtool.server.output.TableOutputType;
            end
        end
        
        function v = getOutputTypeFromJava(javaStr)
            % Returns the OutputType class based on the Java string input text.
            % The javaStr input text is the allocation function used by the java
            % code to specify rules.
            switch javaStr
                case "internal.matlab.importtool.AbstractSpreadsheet.matrixAllocationFcn"
                    v = internal.matlab.importtool.server.output.NumericArrayOutputType;
                case "internal.matlab.importtool.AbstractSpreadsheet.cellArrayAllocationFcn"
                    v = internal.matlab.importtool.server.output.CellArrayOutputType;
                case "internal.matlab.importtool.AbstractSpreadsheet.stringAllocationFcn"
                    v = internal.matlab.importtool.server.output.StringArrayOutputType;
                case "internal.matlab.importtool.AbstractSpreadsheet.datasetAllocationFcn"
                    v = internal.matlab.importtool.server.output.DatasetArrayOutputType;
                case "internal.matlab.importtool.AbstractSpreadsheet.tableAllocationFcn"
                    v = internal.matlab.importtool.server.output.TableOutputType;
                case "internal.matlab.importtool.AbstractSpreadsheet.columnVectorAllocationFcn"
                    v = internal.matlab.importtool.server.output.ColumnVectorOutputType;
            end
        end
    end
end