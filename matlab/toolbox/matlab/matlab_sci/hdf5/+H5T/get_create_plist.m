function plist_id = get_create_plist(datatype_id)
%H5T.get_create_plist  Return copy of datatype creation property list.
%   plist_id = H5T.get_create_plist(datatype_id) returns a property list 
%   identifier for the datatype creation property list associated with the 
%   datatype specified by datatype_id.
%
%   See also H5T, H5D.get_create_plist, H5F.get_create_plist,
%       H5G.get_create_plist.

%   Copyright 2009-2024 The MathWorks, Inc.

plist_id = matlab.internal.sci.hdf5lib2('H5Tget_create_plist', datatype_id);            
plist_id = H5ML.id(plist_id,'H5Pclose');

