function reDef(ncid)
%netcdf.reDef Set netCDF file into define mode.
%   netcdf.reDef(ncid) Puts an open netCDF dataset into define mode so 
%   that dimensions, variables, and attributes can be added or renamed.  
%   Attributes can also be deleted in define mode.
%
%   For all netCDF-4 files, the root ncid must be used. This is the ncid 
%   returned by netcdf.open and netcdf.create, and points to the root of 
%   the hierarchy tree for netCDF-4 files. 
%
%   To use this function, you should be familiar with the information about 
%   netCDF contained in the "NetCDF C Interface Guide".  This function 
%   corresponds to the "nc_redef" function in the netCDF library C API.
%
%   Example:
%       srcFile = which('example.nc');
%       copyfile(srcFile,'myfile.nc');
%       fileattrib('myfile.nc','+w');
%       ncid = netcdf.open('myfile.nc','WRITE');
%       netcdf.reDef(ncid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.endDef.

%   Copyright 2008-2021 The MathWorks, Inc.

matlab.internal.imagesci.netcdflib('redef',ncid);            
