function childGrpId = inqNcid(ncid,childGroupName)
%netcdf.inqNcid Return ID of named group.
%   childGroupId = netcdf.inqNcid(ncid,childGroupName) returns the ID of 
%   the named child group in the group specified by ncid.
%
%   This function corresponds to the "nc_inq_ncid" function in the 
%   netCDF library C API.  
%
%   Example:
%       ncid = netcdf.open('example.nc','nowrite');
%       gid = netcdf.inqNcid(ncid,'grid1');
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqGrpName, netcdf,inqGrpNameFull.

%   Copyright 2010-2021 The MathWorks, Inc.

if nargin > 1
    childGroupName = convertStringsToChars(childGroupName);
end

childGrpId = matlab.internal.imagesci.netcdflib('inqNcid',ncid,childGroupName);
