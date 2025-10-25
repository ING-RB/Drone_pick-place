function reset(imds)
%RESET Reset the datastore to the start of the data.
%   RESET(IMDS) resets IMDS to the beginning of the datastore.
%
%   Example:
%   --------
%      folders = fullfile(matlabroot,'toolbox','matlab',{'demos','imagesci'});
%      exts = {'.jpg','.png','.tif'};
%      imds = imageDatastore(folders,'FileExtensions',exts);
%
%      while hasdata(imds)
%          img = read(imds);      % Read the images
%          imshow(img);           % See images in a loop
%      end
%      reset(imds);               % Reset to the beginning of the datastore
%      img = read(imds)           % Read from the beginning
%
%   See also imageDatastore, read, readimage, readall, hasdata, preview.

%   Copyright 2015-2018 The MathWorks, Inc.
try
    reset@matlab.io.datastore.internal.util.SubsasgnableFileSetLabels(imds);
    updateNumSplits(imds.Splitter);
    reset@matlab.io.datastore.FileBasedDatastore(imds);
    imds.PrivateReadFailuresList = zeros(imds.NumFiles,1);
    resetBatchReading(imds);
catch ME
    throw(ME);
end
end
