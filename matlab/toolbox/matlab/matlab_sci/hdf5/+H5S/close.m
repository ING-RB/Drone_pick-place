function close(space_id)
%H5S.close  Close dataspace.
%   H5S.close(space_id) releases and terminates access to a dataspace.
%   space_id is a dataspace identifier.
%
%   See also H5S, H5A.get_space, H5D.get_space.

%   Copyright 2006-2024 The MathWorks, Inc.

if isa(space_id, 'H5ML.id')
    id = space_id.identifier;
    space_id.identifier = -1;
else
    id = space_id;
end
matlab.internal.sci.hdf5lib2('H5Sclose', id);            
