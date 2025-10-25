function flush(dataset_id)
%H5D.flush  Flush all buffers to disk.
%   H5D.flush(dataset_id) causes all buffers for the dataset associated
%   with identifier dataset_id to be immediately flushed to disk
%   without removing data from the cache.
%
%   Example:
%       % Create file access property list with latest library version
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%       dtypeID = H5T.copy('H5T_NATIVE_DOUBLE');          
%       % Create a file
%       dspaceID = H5S.create_simple(2,[4 4],[]);
%       fileID = H5F.create('sampleFile.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);        
%       % Create a dataset and write data to it
%       dsetID = H5D.create(fileID,['dataset'],dtypeID,dspaceID,'H5P_DEFAULT');
%       H5D.write(dsetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT', ones(4,4));         
%       % Flush the dataset
%       H5D.flush(dsetID);         
%       % Close the identifiers
%       H5S.close(dspaceID)
%       H5D.close(dsetID);
%       H5F.close(fileID);
%  
%   See also H5D, H5D.refresh.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dataset_id,{'H5ML.id'},{'nonempty','scalar'});
matlab.internal.sci.hdf5lib2('H5Dflush',dataset_id);
