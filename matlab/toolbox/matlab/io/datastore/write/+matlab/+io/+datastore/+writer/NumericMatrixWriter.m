classdef NumericMatrixWriter < matlab.io.datastore.writer.FileWriter
%NUMERICMATRIXWRITER This class dispatches to the appropriate numeric
%   matrix write method

%   Copyright 2023 The MathWorks, Inc.

    methods
        function tf = write(~, data, writeInfo, outputFmt, varargin)
            tf = false;
            % dispatch to the appropriate writer
            if any(matlab.io.datastore.internal.FileWritableSupportedOutputFormats.ImageDatastoreSupportedOutputFormats.contains(outputFmt, "IgnoreCase", true))
                tf = imageWriter(data, writeInfo, varargin{:});
            elseif any(matlab.io.datastore.internal.FileWritableSupportedOutputFormats.AudioDatastoreSupportedOutputFormats.contains(outputFmt, "IgnoreCase", true))
                tf = audioWriter(data, writeInfo, varargin{:});
            end
        end
    end
end

function tf = imageWriter(data, writeInfo, varargin)
    if iscell(data)
        for ii = 1 : size(data,1)
            imwrite(data{ii}, writeInfo.SuggestedOutputName(ii), varargin{:});
        end
    else
        imwrite(data, writeInfo.SuggestedOutputName, varargin{:});
    end
    tf = true;
end

function tf = audioWriter(data, writeInfo, varargin)
    audiowrite(writeInfo.SuggestedOutputName, data, writeInfo.ReadInfo.SampleRate, ...
        varargin{:});
    tf = true;
end