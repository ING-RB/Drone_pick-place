function gcpl_id = get_create_plist(group_id)
%H5G.get_create_plist  Return a group creation property list.
%   gcpl_id = H5G.get_create_plist(group_id) returns the identifier to
%   the group creation property list for the group specified by
%   group_id. 
%
%   Example: 
%       fid = H5F.open('example.h5');
%       group_id = H5G.open(fid,'/g1/g1.1');
%       gcpl_id = H5G.get_create_plist(group_id);
%       H5P.close(gcpl_id);
%       H5G.close(group_id);
%       H5F.close(fid);
%
%   See also H5G, H5D.get_create_plist, H5F.get_create_plist,
%   H5T.get_create_plist.

%   Copyright 2022-2024 The MathWorks, Inc.

validateattributes(group_id,{'H5ML.id'},{'nonempty','scalar'});
gcpl_id = matlab.internal.sci.hdf5lib2('H5Gget_create_plist',group_id);
gcpl_id = H5ML.id(gcpl_id,'H5Gclose');
