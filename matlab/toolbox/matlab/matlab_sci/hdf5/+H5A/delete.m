function delete(loc_id, name)
%H5A.delete  Delete attribute.
%   H5A.delete(loc_id, name) removes the attribute specified by name from 
%   the dataset, group, or named datatype specified by loc_id.
%
%   Example:  Delete a root group attribute.
%       srcFile = which('example.h5');
%       copyfile(srcFile,'myfile.h5');
%       fileattrib('myfile.h5','+w');
%       fid = H5F.open('myfile.h5','H5F_ACC_RDWR','H5P_DEFAULT');
%       gid = H5G.open(fid,'/');
%       H5A.delete(gid,'attr1');
%       H5G.close(gid);
%       H5F.close(fid);
%
%   See also H5A.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    name = convertStringsToChars(name);
end

matlab.internal.sci.hdf5lib2('H5Adelete', loc_id, name);            
