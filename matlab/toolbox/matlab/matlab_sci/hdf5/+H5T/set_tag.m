function set_tag(type_id, tag)
%H5T.set_tag  Tag opaque datatype with description.
%   H5T.set_tag(type, tag) tags the opaque datatype, specified by type_id,
%   with the descriptive ASCII string identifier, tag.
%
%   Example:  create an opaque datatype with a length of 4 bytes and a
%   particular tag.
%       type_id = H5T.create('H5T_OPAQUE',4);
%       H5T.set_tag(type_id,'Created by MATLAB.');
%
%   See also H5T, H5T.create, H5T.get_tag.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    tag = convertStringsToChars(tag);
end

matlab.internal.sci.hdf5lib2('H5Tset_tag', type_id, tag); 
