function output = get_native_type(type_id, direction)
%H5T.get_native_type  Return native datatype of specified datatype.
%   output = H5T.get_native_type(TYPE_ID, DIRECTION) returns the equivalent 
%   native datatype for the dataset datatype specified in TYPE_ID. 
%   DIRECTION indicates the order in which the library searches for a 
%   native datatype match and must be either 'H5T_DIR_ASCEND' or 
%   'H5T_DIR_DESCEND'.
%
%   See also H5T.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    direction = convertStringsToChars(direction);
end

output = matlab.internal.sci.hdf5lib2('H5Tget_native_type',...
    type_id, direction); 
output = H5ML.id(output,'H5Tclose');
