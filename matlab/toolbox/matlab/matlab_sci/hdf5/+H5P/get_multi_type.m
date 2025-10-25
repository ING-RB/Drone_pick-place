function type = get_multi_type(fapl_id)
%H5P.get_multi_type  Return type of data property for MULTI driver.
%   type = H5P.get_multi_type(fapl_id) returns the type of data setting 
%   from the file access or data transfer property list, fapl_id.
%
%   This function should only be used with an HDF5 file written as a set of
%   files with the MULTI file driver.
%
%   See also H5P, H5P.set_multi_type.

%   Copyright 2006-2024 The MathWorks, Inc.

type = matlab.internal.sci.hdf5lib2('H5Pget_multi_type', fapl_id);            
