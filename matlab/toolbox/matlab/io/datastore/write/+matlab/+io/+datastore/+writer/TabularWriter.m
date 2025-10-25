classdef TabularWriter < matlab.io.datastore.writer.FileWriter
%TABULARWRITER This class dispatches to the appropriate tabular write
%   method

%   Copyright 2023 The MathWorks, Inc.

    methods
        function tf = write(~, data, writeInfo, outputFmt, varargin)
            % dispatch to the appropriate writer
            if any(matlab.io.datastore.internal.FileWritableSupportedOutputFormats.TabularTextDatastoreSupportedOutputFormats.contains(outputFmt, "IgnoreCase",true))
                tf = tabularTextWriter(data, writeInfo, varargin{:});
            elseif any(matlab.io.datastore.internal.FileWritableSupportedOutputFormats.SpreadsheetDatastoreSupportedOutputFormats.contains(outputFmt, "IgnoreCase", true))
                tf = spreadsheetWriter(data, writeInfo, varargin{:});
            end
        end
    end
end

function tf = tabularTextWriter(data, writeInfo, varargin)
    % Text writer
    params = {};
    if isfile(writeInfo.SuggestedOutputName)
        params = {"WriteVariableNames", false};
    end

    % Switch yard on the type of data - call the appropriate underlying
    % writing function
    if isa(data, "table")
        writerFunc = @writetable;
    elseif isa(data, "timetable")
        writerFunc = @writetimetable;
    elseif isnumeric(data)
        writerFunc = @writematrix;
    elseif iscell(data)
        writerFunc = @writecell;
    else
        error(message("MATLAB:io:datastore:write:write:IncorrectDatatypeForWrite"));
    end
    writerFunc(data, writeInfo.SuggestedOutputName, "WriteMode","append", ...
        "FileType", "text", varargin{:}, params{:});
    tf =  true;
end

function tf = spreadsheetWriter(data, writeInfo, varargin)
    % Spreadsheet writer
    params = {};
    % Switch yard on the type of data - call the appropriate underlying
    % writing function
    if isa(data, "table")
        writerFunc = @writetable;
    elseif isa(data, "timetable")
        writerFunc = @writetimetable;
    elseif isnumeric(data)
        writerFunc = @writematrix;
    elseif iscell(data)
        writerFunc = @writecell;
    else
        error(message("MATLAB:io:datastore:write:write:IncorrectDatatypeForWrite"));
    end

    if isfile(writeInfo.SuggestedOutputName)
        params = {"WriteVariableNames",false};
        rangeVal = matlab.io.datastore.internal.write.utility.getRangeToWrite(...
            writeInfo.SuggestedOutputName,1);
        writerFunc(data, writeInfo.SuggestedOutputName, "Range", rangeVal, ...
            varargin{:}, params{:});
    else
        writerFunc(data, writeInfo.SuggestedOutputName, varargin{:}, params{:});
    end
    tf = true;
end
