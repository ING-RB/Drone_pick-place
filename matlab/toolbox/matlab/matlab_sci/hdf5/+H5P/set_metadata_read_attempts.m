function set_metadata_read_attempts(fapl_id, attempts)
%H5P.set_metadata_read_attempts Set the number of read attempts in a
%faplID.
%   H5P.set_metadata_read_attempts(fapl_id, attempts) sets the number of
%   reads that the library will try when reading checksummed metadata in an
%   HDF5 file opened with SWMR access.
%   The number of read attempts used by the library will depend on how the
%   file is opened and whether the user sets the number of read attempts
%   via this routine:
%   For a file opened with SWMR access: 
%       If the user sets the number of attempts to N, the library will use N.
%       If the user does not set the number of attempts, the library will
%       use the default for SWMR access (100).
%   For a file opened with non-SWMR access, the library will always
%   use the default for non-SWMR access (1). The value set via this routine
%   does not have any effect during non-SWMR access.
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
%       H5P.close(faplID)
%         
%       % Query the number of read attempts
%       file_aplID = H5F.get_access_plist(fileID);
%       read_attempts = H5P.get_metadata_read_attempts(file_aplID)
%         
%       H5P.close(file_aplID);
%       H5F.close(fileID);
%
%   See also H5P.get_metadata_read_attempts,
%   H5F.get_metadata_read_retry_info.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(fapl_id, {'H5ML.id'}, {'nonempty', 'scalar'});
validateattributes(attempts, {'double'}, {'scalar', 'nonnegative', 'integer'});
matlab.internal.sci.hdf5lib2('H5Pset_metadata_read_attempts',...
    fapl_id, attempts);
