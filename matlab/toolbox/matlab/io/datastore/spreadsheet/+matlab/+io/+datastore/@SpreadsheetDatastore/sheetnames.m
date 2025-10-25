function sheetNames = sheetnames(ds, fileNameOrIdx)
%SHEETNAMES returns the sheet names in the file name or file index
%   This function is responsible for returning the sheet names from the
%   specified file name or file index. The file name must be contained in
%   the datastore. The file index must be less than or equal to the number
%   of files in the datastore.
%
%   Example:
%   --------
%      % Create a SpreadsheetDatastore
%      ssds = spreadsheetDatastore('airlinesmall_subset.xlsx')
%      % sheetnames in the first file
%      sNames = sheetnames(ssds, 1)

%   Copyright 2015-2019 The MathWorks, Inc.

    % imports
    import matlab.io.spreadsheet.internal.getRemoteSpreadsheet;
    import matlab.io.spreadsheet.internal.getSheetNames;

    narginchk(2,2);
    fileNameOrIdx = convertStringsToChars(fileNameOrIdx);
    try
        % specified input must be a valid filename or a file index.
        if matlab.internal.datatypes.isScalarText(fileNameOrIdx)
            if ~ismember(fileNameOrIdx, ds.Files)
                error(message('MATLAB:datastoreio:spreadsheetdatastore:invalidFileName', ...
                    fileNameOrIdx));
            end
        else
            try
                validateattributes(fileNameOrIdx, {'numeric'}, ...
                    {'scalar', 'positive', 'integer', '<=', numel(ds.Files)});
            catch
                error(message('MATLAB:datastoreio:spreadsheetdatastore:invalidFileIndex', ...
                    numel(ds.Files)));
            end
            fileNameOrIdx = ds.Files{fileNameOrIdx};
        end

        % get remote file, if necessary
        [fileNameOrIdx, remote2Local] = getRemoteSpreadsheet(...
            fileNameOrIdx, ds.RemoteToLocalObject); %#ok<ASGLU>

        % get sheet names
        sheetNames = getSheetNames(fileNameOrIdx);
    catch ME
        throw(ME);
    end
end