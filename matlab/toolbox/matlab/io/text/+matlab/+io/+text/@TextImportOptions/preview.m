function data = preview(filename,opts)
%PREVIEW Read up to 8 rows of data from the beginning of the file with
%Import Options.
%   T = PREVIEW(FILENAME,OPTS) reads up to 8 rows of data from the
%   beginning of FILENAME using the options set in OPTS. T is a table with
%   variables governed by OPTS.SelectedVariableNames. T has at most 8 rows.
%
%   Example:
%   --------
%      filename = 'outages.csv';
%      % Create an ImportOptions
%      opts = detectImportOptions(filename);
%      % Preview 8 rows of the data
%      preview(filename,opts);
%      % Narrow focus to only the Outage Time data
%      opts.SelectedVariableNames = 'OutageTime';
%      % Preview again
%      preview(filename,opts);
%
%   See also detectImportOptions, readtable,
%       matlab.io.text.DelimitedTextImportOptions,
%       matlab.io.text.FixedWidthImportOptions

%   Copyright 2017-2022 The MathWorks, Inc.

    if nargin < 2
        error(message("MATLAB:textio:preview:NotEnoughArguments"));
    end
    if ~isa(opts,"matlab.io.ImportOptions")
        error(message("MATLAB:textio:io:OptsSecondArg","preview"))
    end
    % We request extra rows in case some rows are empty or the MissingRule or
    % ImportErrorRule are set to 'omitrow'. In these cases we might get less
    % than the preview size so read some extra rows to fill them in if
    % necessary.
    filename = convertStringsToChars(filename);
    try
    
        data = readtable(filename, opts, MaxRowsRead=matlab.io.ImportOptions.PreviewSize);
    catch ME
        throwAsCaller(ME);
    end

    if isempty(data)
        error(message("MATLAB:textio:preview:NoDataAvailable"));
    end
end

