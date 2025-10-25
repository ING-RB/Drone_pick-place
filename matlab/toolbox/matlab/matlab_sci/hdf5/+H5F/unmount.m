function unmount(loc_id, name)
%H5F.unmount  Unmount file or group from mount point.
%   H5F.unmount(loc_id, name) dissassociates the file or group specified by
%   loc_id from the mount point specified by name. loc_id can be a file or
%   group identifier. 
%
%   See also H5F, H5F.mount.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    name = convertStringsToChars(name);
end

matlab.internal.sci.hdf5lib2('H5Funmount', loc_id, name);            
