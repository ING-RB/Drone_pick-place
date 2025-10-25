function intent = get_intent(file_id)
%H5F.get_intent  Return read/write or read-only status of a file.
%   intent = H5F.get_intent(file_id) returns the intented access mode
%   flag passed in with H5F.open when the file was opened.  file_id is 
%   the file identifier for the currently open HDF5 file.  intent is
%   the access mode flag originally passed in with H5F.open.  Valid 
%   values are:
%
%      'H5F_ACC_RDONLY'                   (numeric equivalent 0)
%      'H5F_ACC_RDWR'                     (numeric equivalent 1)
%      'H5F_ACC_RDONLY|H5F_ACC_SWMR_READ' (numeric equivalent 64)
%      'H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE'  (numeric equivalent 33)
%  
%   Example
%       fileID = H5F.open('example.h5','H5F_ACC_RDWR','H5P_DEFAULT');
%       H5F.get_intent(fileID)
%       H5F.close(fileID);
%
%   See also H5F, H5F.open.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(file_id,{'H5ML.id'},{'nonempty','scalar'});
intent = matlab.internal.sci.hdf5lib2('H5Fget_intent',file_id);
