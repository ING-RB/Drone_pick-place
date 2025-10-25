function groupName = inqGrpName(ncid)
%netcdf.inqGrpName Return relative name of group.
%   groupName = netcdf.inqGrpName(ncid) returns the name of a group
%   specified by ncid.  The root group will have name '/'.  
%
%   This function corresponds to the "nc_inq_grpname" function in the
%   netCDF library C API.
%
%   Example:
%       ncid = netcdf.open('example.nc','nowrite');
%       name = netcdf.inqGrpName(ncid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqGrpNameFull.

%   Copyright 2010-2021 The MathWorks, Inc.

groupName = matlab.internal.imagesci.netcdflib('inqGrpName',ncid);
