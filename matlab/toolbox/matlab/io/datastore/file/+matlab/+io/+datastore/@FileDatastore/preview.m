function data = preview(fds)
%PREVIEW Read the first file from the datastore.
%   DATA = PREVIEW(FDS) always reads the first file from FDS.
%   DATA is equal to the data returned by ReadFcn of FileDatastore unless a
%   custom PreviewFcn has been set on the FileDatastore.
%
%   Example 1:
%   ----------
%      folder = fullfile(matlabroot,'toolbox','matlab','demos');
%      fds = fileDatastore(folder,'ReadFcn',@load,'FileExtensions','.mat');
%
%      PREVIEW(fds);      %Preview the data from the first file
%
%   Example 2:
%   ----------
%      folder = fullfile(matlabroot,'toolbox','matlab','demos');
%      fds = fileDatastore(folder,'ReadFcn',@load,'FileExtensions','.mat',...
%                                 'PreviewFcn',@(filename) who('-file', filename));
%
%      PREVIEW(fds);      %Preview the array names from the first file 
%                         %without reading the entire MAT file.
%
%
%   See also fileDatastore, hasdata, readall, read, reset.

%   Copyright 2015-2017 The MathWorks, Inc.

try
    % If files are empty, return empty cell
    if isEmptyFiles(fds)
        data = fds.BufferedZero1DimData;
        return;
    end
    
    % Work with a copy of the datastore to make preview stateless.
    fdsCopy = copy(fds);
    fdsCopy.ReadFcn = fds.PreviewFcn;
    reset(fdsCopy);
    
    % Change the error handler on the SplitReader to get a nicer error
    % message if preview fails.
    fdsCopy.SplitReader.CustomReadErrorFcn = @customPreviewError;
    fdsCopy.PreviewCall = true;

    data = read(fdsCopy);
catch e
    throw(e);
end

end

function customPreviewError(ME, fcn, filename, numOutputs, className)
    import matlab.io.datastore.exceptions.decorateCustomFunctionError;
    % Set "PreviewFcn" as the function name that errored.
    decorateCustomFunctionError(ME, fcn, filename, numOutputs, className, "PreviewFcn");
end
