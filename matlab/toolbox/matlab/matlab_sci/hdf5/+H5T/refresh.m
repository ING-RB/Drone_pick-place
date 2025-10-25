function refresh(dtype_id)
%H5T.refresh(dtype_id) Refreshes buffers for a committed datatype
%   H5T.refresh causes all the buffers associated with a committed datatype
%   to be cleared and immediately re-loaded with updated contents from
%   disk. This function closes the committed datatype, evicts all metadata
%   associated with it from the cache, and then reopens the datatype with
%   the same identifier
%  
%   See also H5T, H5T.flush.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dtype_id, {'H5ML.id'}, {'nonempty'});
matlab.internal.sci.hdf5lib2('H5Trefresh', dtype_id);
