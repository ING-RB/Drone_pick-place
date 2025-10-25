function attempts = get_metadata_read_attempts(fapl_id)
%H5P.get_metadata_read_attempts  Return number of metadata read attempts.
%   attempts = H5P.get_metadata_read_attempts(fapl_id) retrieves the number
%   of read attempts set in the file access property list fapl_id. 
%
%   Example:
%       % Set up the file access property list ID
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%       % Default read attempts
%       read_attempts = H5P.get_metadata_read_attempts(faplID)
%       % Set the number of metadata read attempts
%       H5P.set_metadata_read_attempts(faplID,10);
%         
%       % Create the file with the faplID
%       fileID = H5F.create('myexample.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%       H5P.close(faplID);
%         
%       % Query the number of read attempts
%       file_aplID = H5F.get_access_plist(fileID);
%       read_attempts = H5P.get_metadata_read_attempts(file_aplID)
%         
%       % Close identifiers
%       H5P.close(file_aplID);
%       H5F.close(fileID);
%
%   See also H5P.set_metadata_read_attempts, H5F.get_metadata_read_retry_info.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(fapl_id, {'H5ML.id'}, {'nonempty','scalar'});
attempts = matlab.internal.sci.hdf5lib2(...
    'H5Pget_metadata_read_attempts', fapl_id);
