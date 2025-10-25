function flush(dtype_id)
%H5T.flush(dtype_id) Flushes all buffers of a committed datatype to disk
%   H5T.flush causes all the buffers associated with a committed datatype
%   to be flushed to disk without removing the data from the cache
%
%   Example:
%         filename = 'myexample.h5';
%         faplID = H5P.create('H5P_FILE_ACCESS');
%         H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%         fileID = H5F.create(filename,'H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%         H5F.close(fileID);        
%         % Open the file with SWMR write and read mode
%         fileIDW = H5F.open(filename,'H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE',faplID);
%         % Create the committed datatype
%         dtypeIDW = H5T.copy('H5T_NATIVE_DOUBLE');
%         H5T.commit(fileIDW,'myDtype',dtypeIDW);
%         % Flush the group
%         H5T.flush(dtypeIDW);
%         H5T.close(dtypeIDW);
%  
%   See also H5T, H5T.refresh.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dtype_id, {'H5ML.id'}, {'nonempty'});
matlab.internal.sci.hdf5lib2('H5Tflush', dtype_id);
