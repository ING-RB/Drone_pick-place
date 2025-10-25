function is_disabled = are_mdc_flushes_disabled(object_id)
%H5O.are_mdc_flushes_disabled  Determine if mdc flushes are disabled. 
%   is_disabled = H5O.are_mdc_flushes_disabled(object_id) returns true if
%   an HDF5 object (dataset, group, committed datatype) has had flushes
%   of metadata entries disabled.
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
%       % Flush the group
%       % Flushes are enabled by default
%       H5O.are_mdc_flushes_disabled(grpID) % should return 0
%       % Disable grpID flush
%       H5O.disable_mdc_flushes(grpID);
%       H5O.are_mdc_flushes_disabled(grpID) % should return 1
%       % Reenable grpID flush
%       H5O.enable_mdc_flushes(grpID);
%       H5O.are_mdc_flushes_disabled(grpID) % should return 0
%       % Flush the grpID
%       H5G.flush(grpID);
%       % Close the identifiers
%       H5S.close(dspaceID);
%       H5G.close(grpID);
%       H5F.close(fileID);
%
%   See also H5O.disable_mdc_flushes, H5O.enable_mdc_flushes.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(object_id,{'H5ML.id'},{'nonempty','scalar'});
is_disabled = matlab.internal.sci.hdf5lib2('H5Oare_mdc_flushes_disabled',object_id);
