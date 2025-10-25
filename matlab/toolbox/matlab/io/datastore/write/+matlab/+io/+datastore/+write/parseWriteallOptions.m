function nvStruct = parseWriteallOptions(ds, varargin)
%parseWriteallOptions    Helper function that parses each name-value
%   pair of the writeall method.

%   Copyright 2023 The MathWorks, Inc.

    % Populate inputParser and register name-value pairs on first 
    % construction.
    writeInputParser = inputParser;
    addParameter(writeInputParser, "FolderLayout", "duplicate");
    addParameter(writeInputParser, "UseParallel", false);
    addParameter(writeInputParser, "WriteFcn", "");
    addParameter(writeInputParser, "OutputFormat", "");
    addParameter(writeInputParser, "FilenamePrefix", "");
    addParameter(writeInputParser, "FilenameSuffix", "");

    % Set KeepUnmatched to true so we can forward unused name-value pairs
    % to each datastore's writer.
    writeInputParser.KeepUnmatched = true;
    writeInputParser.parse(varargin{:});

    % Copy the results out of the InputParser instance.
    nvStruct = writeInputParser.Results;
    nvStruct.Parameters = writeInputParser.Parameters;
    nvStruct.UsingDefaults = writeInputParser.UsingDefaults;

    % If datastore contains DefaultOutputFormat, set it
    if nvStruct.OutputFormat == "" && ~ismissing(ds.DefaultOutputFormat)
        nvStruct.OutputFormat = ds.DefaultOutputFormat;
    end
    % Convert the 'Unmatched' struct to a cell array before forwarding.
    nvStruct.Unmatched = convertUnmatchedNVPairStructToCell(writeInputParser.Unmatched);
end

function parameters = convertUnmatchedNVPairStructToCell(NVPairs)
    fields = fieldnames(NVPairs);
    parameters = cell(2*numel(fields),1);
    jj = 1;
    for ii = 1 : numel(fields)
        parameters{jj} = fields{ii};
        parameters{jj+1} = NVPairs.(fields{ii});
        jj = jj+2;
    end
end
