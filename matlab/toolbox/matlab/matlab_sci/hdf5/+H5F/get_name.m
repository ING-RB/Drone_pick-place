function name = get_name(obj_id)
%H5F.get_name  Return name of HDF5 file.
%   name = H5F.get_name(obj_id) retrieves the name of the file to which the
%   object obj_id belongs. The object can be a group, dataset, attribute,
%   or named datatype.
%
%   Example:
%       fid = H5F.open('example.h5');
%       name = H5F.get_name(fid);
%       H5F.close(fid);
%
%   See also H5F, H5A.get_name, H5I.get_name.

%   Copyright 2006-2024 The MathWorks, Inc.

name = matlab.internal.sci.hdf5lib2('H5Fget_name', obj_id);            
