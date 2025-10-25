classdef FileWriter < matlab.io.datastore.writer.Writer
%FILEWRITER This class dispatches to the appropriate writer class based on
%   the output format

%   Copyright 2023 The MathWorks, Inc.

    methods
        function tf = write(~, data, writeInfo, outputFmt, varargin)
            tf = false;
            if any(matlab.io.datastore.internal.FileWritableSupportedOutputFormats.TabularDatastoreSupportedOuptutFormats.contains(outputFmt, "IgnoreCase", true))
                newWriter = matlab.io.datastore.writer.TabularWriter;
                tf = newWriter.write(data, writeInfo, lower(outputFmt), varargin{:});
            elseif any(matlab.io.datastore.internal.FileWritableSupportedOutputFormats.ImageDatastoreSupportedOutputFormats.contains(outputFmt, "IgnoreCase", true)) || ...
                    any(matlab.io.datastore.internal.FileWritableSupportedOutputFormats.AudioDatastoreSupportedOutputFormats.contains(outputFmt, "IgnoreCase", true))
                newWriter = matlab.io.datastore.writer.NumericMatrixWriter;
                tf = newWriter.write(data, writeInfo, lower(outputFmt), varargin{:});
            end
        end
    end

    methods (Static)
        function t = constructEmptyFormatTable()
            t = table('Size', [0, 1], 'VariableTypes', {'string'}, ...
                'VariableNames', "AcceptableNVPairs");
        end
    end
end