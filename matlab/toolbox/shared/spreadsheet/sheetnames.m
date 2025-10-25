function sheets = sheetnames(filename)
% SHEETNAMES(FILENAME) returns the sheet names from the given spreadsheet FILENAME
%   FILENAME: If the file is not on the MATLAB path, you must specify the
%   full path to the file on the local machine or as an URL for a remote file
%
%   Example:
%   --------
%   sheets = sheetnames('testData.xlsx');% File is on MATLAB path
%   sheets = sheetnames('C:\Users\username\Desktop\testData.xlsx'); % Absolute path to file
%   sheets = sheetnames('s3://bucketname/path_to_file'); % Remote s3 file

% Copyright 2018-2024 The MathWorks, Inc.

import matlab.io.spreadsheet.internal.*;
import matlab.io.internal.common.validators.isGoogleSheet;

try
    if ~matlab.internal.datatypes.isScalarText(filename)
        error('sheetnames:InputMustBeScalar', ...
            'Filename must be a non-empty character vector or string scalar.');
    end

    filename = convertStringsToChars(filename);

    % get the remote file, if necessary
    [filename, remote2Local] = getRemoteSpreadsheet(filename); %#ok<ASGLU>

    if ~isGoogleSheet(filename)
        validFilename = matlab.io.internal.validators.validateFileName(filename);
        filename = validFilename{1};
    end

    % get sheet names from file
    sheets = getSheetNames(filename);
catch ME
    if strcmp(ME.identifier, 'MATLAB:spreadsheet:book:fileTypeUnsupported')
        error(message('MATLAB:spreadsheet:book:invalidFormatUnix'));
    end
    throw(ME);
end
end
