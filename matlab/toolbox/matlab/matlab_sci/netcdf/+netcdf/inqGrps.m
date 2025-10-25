function childGrps = inqGrps(ncid)
%netcdf.inqGrps Return array of child group IDs.
%   childGrps = netcdf.inqGrps(ncid) returns all the child group IDs in 
%   a parent group.
%
%   This function corresponds to the "nc_inq_grps" function in the 
%   netCDF library C API.  
%
%   Example:
%       ncid = netcdf.open('example.nc','nowrite');
%       childGroups = netcdf.inqGrps(ncid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqNcid.

%   Copyright 2010-2021 The MathWorks, Inc.

childGrps = matlab.internal.imagesci.netcdflib('inqGrps',ncid);
