function output = get_member_index(type_id, name)
%H5T.get_member_index  Return index of compound or enumeration type member.
%   idx = H5T.get_member_index(type_id, name) returns the index of a field
%   of a compound datatype or an element of an enumeration datatype.
%   type_id is a datatype identifier and name is a text string that
%   identifies the target field or element.
%
%   Example:
%      fid = H5F.open('example.h5');
%      dset_id = H5D.open(fid,'/g3/compound');
%      type_id = H5D.get_type(dset_id);
%      idx = H5T.get_member_index(type_id,'b'); 
%
%   See also H5T, H5T.get_member_name.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    name = convertStringsToChars(name);
end

output = matlab.internal.sci.hdf5lib2('H5Tget_member_index',type_id, name); 
