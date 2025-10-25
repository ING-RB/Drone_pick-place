function varids = inqVarIDs(ncid)
%netcdf.inqVarIDs Return list of variables in group.
%   varids = netcdf.inqVarIDs(ncid) returns the list of all variable IDs 
%   in the group specified by ncid.
%
%   This function corresponds to the "nc_inq_varids" function in the 
%   netCDF library C API.  
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       gid = netcdf.inqNcid(ncid,'grid1');
%       varids = netcdf.inqVarIDs(gid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqDimIDs.

%   Copyright 2010-2021 The MathWorks, Inc.

varids = matlab.internal.imagesci.netcdflib('inqVarIDs',ncid);
