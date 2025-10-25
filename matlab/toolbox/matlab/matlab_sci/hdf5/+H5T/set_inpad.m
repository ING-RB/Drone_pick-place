function set_inpad(type_id, inpad)
%H5T.set_inpad  Specify how unused unused internal bits are to be filled.
%   H5T.set_inpad(type_id, pad) sets how unused internal bits of a floating 
%   point type are filled. type_id is the identifier of the datatype. inpad
%   specifies how to fill the bits: H5T_PAD_ZERO, H5T_PAD_ONE, or 
%   H5T_PAD_BACKGROUND (leave background alone).
%
%   Example:
%       type_id = H5T.copy('H5T_NATIVE_FLOAT');
%       pad_type = H5ML.get_constant_value('H5T_PAD_ZERO');
%       H5T.set_inpad(type_id,pad_type);
%
%   See also H5T, H5T.get_inpad.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    inpad = convertStringsToChars(inpad);
end

matlab.internal.sci.hdf5lib2('H5Tset_inpad',type_id, inpad);
