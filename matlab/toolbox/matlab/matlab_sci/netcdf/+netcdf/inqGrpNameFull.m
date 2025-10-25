function groupName = inqGrpNameFull(ncid)
%netcdf.inqGrpNameFull Return complete pathname of group.
%   groupName = netcdf.inqGrpNameFull(ncid) returns the complete pathname 
%   of a group specified by ncid.  The root group will have name '/'.  
%   Parent groups and child groups will be separated with the forward slash 
%   '/' as in UNIX directory names.  For example, 
%   '/group1/subgrp2/subsubgrp3'.
%
%   This function corresponds to the "nc_inq_grpname_full" function in the
%   netCDF library C API.
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       gid = netcdf.inqNcid(ncid,'grid2');
%       fullName = netcdf.inqGrpNameFull(gid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqGrpName.

%   Copyright 2010-2021 The MathWorks, Inc.

groupName = matlab.internal.imagesci.netcdflib('inqGrpNameFull',ncid);
