function flush(object_id)
%H5O.flush  Flush all buffers to disk.
%   H5O.flush(object_id) flushes all buffers for an object associated
%   with object identifier object_id to disk.  object_id can be any named
%   object associated with a file including a dataset, a group, or a
%   committed datatype.
%
%   See also H5O, H5O.refresh.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(object_id,{'H5ML.id'},{'nonempty','scalar'});
matlab.internal.sci.hdf5lib2('H5Oflush',object_id);
