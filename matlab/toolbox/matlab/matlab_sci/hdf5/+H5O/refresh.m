function refresh(object_id)
%H5O.refresh  Refresh all buffers associated with an object.
%   H5O.refresh(object_id) causes all buffers associated with object_id
%   to be cleared and immediately reloaded with updated contents from disk.
%   This function essentially closes the object, evicts all metadata
%   associated with it from the cache, and then reopens the object.
%   The reopened object is automatically reregistered with the same identifier.
%   object_id can be any named object associated with a file including a
%   dataset, a group, or a committed datatype.
%
%   See also H5O, H5O.flush.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(object_id,{'H5ML.id'},{'nonempty','scalar'});
matlab.internal.sci.hdf5lib2('H5Orefresh',object_id);
