function refresh(group_id)
%H5G.refresh  Refresh all buffers associated with a group.
%   H5G.refresh(group_id) causes all buffers associated with group 
%   identifier group_id to be cleared and immediately reloaded with
%   updated contents from disk.
%  
%   See also H5G, H5G.flush.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(group_id,{'H5ML.id'},{'nonempty','scalar'});
matlab.internal.sci.hdf5lib2('H5Grefresh',group_id);
