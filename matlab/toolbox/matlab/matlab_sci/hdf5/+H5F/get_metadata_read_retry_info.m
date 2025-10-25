function retry_info = get_metadata_read_retry_info(file_id)
%H5F.get_metadata_read_retry_info  Return metadata read retry information.
%   retry_info = get_metadata_read_retry_info(file_id) retrieves information 
%   regarding the number of read retries for metadata entries with checksum
%   for the file file_id.  retry_info is a H5F_NUM_METADATA_READ_RETRY_TYPES-by-1 
%   cell array of numeric vectors. 
%   The i-th entry of this cell array can be:
%       - nbins x 1 double matrix containing retry information for the i-th metadata type OR
%       - [] double matrix if no retries were incurred for the i-th metadata type
%
%   Example:
%       filename = 'example.h5';
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%       fileID = H5F.create(filename,'H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%       retries = H5F.get_metadata_read_retry_info(fileID)
%       H5F.close(fileID);
%
%   See also H5P.set_metadata_read_attempts,
%   H5P.get_metadata_read_attempts.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(file_id,{'H5ML.id'},{'nonempty','scalar'});

retry_info = matlab.internal.sci.hdf5lib2('H5Fget_metadata_read_retry_info',file_id);
