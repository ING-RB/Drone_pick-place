function output = get_member_class(type_id, membno)
%H5T.get_member_class  Return datatype class for compound datatype member.
%   output = H5T.get_member_class(type_id, membno) returns the datatype class
%   of the compound datatype member specified by membno. type_id is the 
%   datatype identifier of a compound object.
%
%   Example:
%      fid = H5F.open('example.h5');
%      dset_id = H5D.open(fid,'/g3/compound');
%      type_id = H5D.get_type(dset_id);
%      member_name = H5T.get_member_name(type_id,0);
%      member_class = H5T.get_member_class(type_id,0);
%
%   See also H5T, H5T.get_member_name.

%   Copyright 2006-2024 The MathWorks, Inc.

output = matlab.internal.sci.hdf5lib2('H5Tget_member_class',type_id, membno); 
