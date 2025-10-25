function close(plist_id)
%H5P.close  Close property list.
%   H5P.close(plist_id) terminates access to the property list specified by 
%   plist_id. 
%
%   See also H5P, H5P.create.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 0
    plist_id = convertStringsToChars(plist_id);
end

if isa(plist_id, 'H5ML.id')
    id = plist_id.identifier;
    plist_id.identifier = -1;
else
    id = plist_id;
end
matlab.internal.sci.hdf5lib2('H5Pclose', id);            
