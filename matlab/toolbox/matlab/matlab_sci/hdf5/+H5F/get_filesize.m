function size = get_filesize(file_id)
%H5F.get_filesize  Return size of HDF5 file.
%   size = H5F.get_filesize(file_id) returns the size of the HDF5 file 
%   specified by file_id
%
%   See also H5F.

%   Copyright 2006-2024 The MathWorks, Inc.

size = matlab.internal.sci.hdf5lib2('H5Fget_filesize', file_id);
