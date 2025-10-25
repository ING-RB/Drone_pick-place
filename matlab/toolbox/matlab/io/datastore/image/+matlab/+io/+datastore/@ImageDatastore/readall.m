function data = readall(imds, varargin)
%READALL Read all of the image files from the datastore.
%   IMGARR = READALL(IMDS) reads all of the image files from IMDS.
%   IMGARR is a cell array containing all the images returned by the
%   readimage method.
%
%   IMGARR = READALL(IMDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.
%
%   See also imageDatastore, hasdata, read, readimage, preview, reset.

%   Copyright 2015-2020 The MathWorks, Inc.

if matlab.io.datastore.read.validateReadallParameters(varargin{:})
    data = matlab.io.datastore.read.readallParallel(imds);
    return;
end

try
    % If empty files return an empty cell array
    if isEmptyFiles(imds)
        data = cell(0,1);
        return;
    end
    nFiles = imds.NumFiles;

    if isequal(imds.CachedRead, 'off') || ~imds.IsReadFcnDefault
        origReadCounter = imds.PrivateReadCounter;
        imds.PrivateReadCounter = true;
        data = cell(nFiles, 1);
        for ii = 1:nFiles
            data{ii} = readimage(imds, ii);
        end
        imds.PrivateReadCounter = origReadCounter;
        dispReadallWarning(imds);
    else
        idxes = true(nFiles, 1);
        % Create a copy so we don't mess with the states in the prefetching
        % for read.
        cpyDs = copy(imds);
        origReadCounter = cpyDs.PrivateReadCounter;
        cpyDs.PrivateReadCounter = true;
        reset(cpyDs);
        data = readUsingPreFetcher(cpyDs, cpyDs.Files, idxes, [], nFiles);
        cpyDs.PrivateReadCounter = origReadCounter;
        dispReadallWarning(cpyDs);
        imds.PrivateReadFailuresList = cpyDs.PrivateReadFailuresList;
    end
catch ME
    throw(ME);
end

end