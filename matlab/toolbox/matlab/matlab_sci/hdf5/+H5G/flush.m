function flush(group_id)
%H5G.flush  Flush all buffers associated with a group to disk.
%   H5G.flush(group_id) causes all buffers associated with a group to 
%   be immediately flushed to disk without removing the data from the cache. 
%
%   Example:
%       % Create file access property list with latest library version
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%       dtypeID = H5T.copy('H5T_NATIVE_DOUBLE');          
%       % Create a file
%       dspaceID = H5S.create_simple(2,[4 4],[]);
%       fileID = H5F.create('sampleFile.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%       % Create a group
%       grpID = H5G.create(fileID,'myGroup','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');
%       % Create a dataset and write data to it
%       dsetID = H5D.create(grpID,['dataset'],dtypeID,dspaceID,'H5P_DEFAULT');
%       H5D.write(dsetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',ones(4,4));         
%       % Flush the dataset and the group
%       H5D.flush(dsetID);
%       H5G.flush(grpID);        
%       % Close the identifiers
%       H5S.close(dspaceID);
%       H5D.close(dsetID);
%       H5G.close(grpID);
%       H5F.close(fileID);
%
%   See also H5G, H5G.refresh.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(group_id,{'H5ML.id'},{'nonempty','scalar'});
matlab.internal.sci.hdf5lib2('H5Gflush',group_id);
