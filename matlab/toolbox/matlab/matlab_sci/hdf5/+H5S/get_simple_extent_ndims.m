function output = get_simple_extent_ndims(space_id)
%H5S.get_simple_extent_ndims  Return rank of dataspace.
%   output = H5S.get_simple_extent_ndims(space_id) returns the dimensionality
%   (also called the rank) of a dataspace. 
%
%   See also H5S.

%   Copyright 2006-2024 The MathWorks, Inc.

output = matlab.internal.sci.hdf5lib2('H5Sget_simple_extent_ndims', space_id);            
