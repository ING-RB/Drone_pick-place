function disable_mdc_flushes(object_id)
%H5O.disable_mdc_flushes  Prevent metadata cache entries from being flushed.
%   H5O.disable_mdc_flushes(object_id) prevents metadata entries for an object 
%   associated with object_id from being flushed from the metadata cache to storage.
%   This function prevents an object's or cache's dirty metadata entries from
%   being flushed from the cache by the usual cache eviction/flush policy.
%   Instead, users must manually flush the cache or entries for individual
%   objects via the appropriate H5F/H5D/H5G/H5T/H5O.flush functions. 
%
%   Example:
%       % Create file access property list with latest library version
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%       % Create a file
%       dspaceID = H5S.create_simple(2,[4 4],[]);
%       fileID = H5F.create('myexample.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%       % Create a group
%       grpID = H5G.create(fileID,'myGroup','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
%       % Create a dataset and write data to it
%       dtypeID = H5T.copy('H5T_NATIVE_DOUBLE');
%       dsetID = H5D.create(grpID,'myDataset',dtypeID,dspaceID,'H5P_DEFAULT');
%       H5D.write(dsetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',ones(4,4));
%       % Flush the group
%       % Flushes are enabled by default
%       H5O.are_mdc_flushes_disabled(grpID) % should return 0
%       % Disable grpID flush
%       H5O.disable_mdc_flushes(grpID);
%       H5O.are_mdc_flushes_disabled(grpID) % should return 1
%       % Reenable grpID flush
%       H5O.enable_mdc_flushes(grpID);
%       H5O.are_mdc_flushes_disabled (grpID) % should return 0
%       % Flush the grpID
%       H5G.flush(grpID);        
%       % Close identifiers
%       H5S.close(dspaceID);
%       H5D.close(dsetID);
%       H5G.close(grpID);
%       H5F.close(fileID);
%
%   See also H5O, H5O.enable_mdc_flushes, H5O.are_mdc_flushes_disabled.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(object_id,{'H5ML.id'},{'nonempty','scalar'});
matlab.internal.sci.hdf5lib2('H5Odisable_mdc_flushes',object_id);
