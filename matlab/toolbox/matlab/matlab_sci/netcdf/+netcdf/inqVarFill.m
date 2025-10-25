function [noFillMode,fillValue] = inqVarFill(ncid,varid)
%netcdf.inqVarFill Return fill parameters for a variable in a netCDF-4 file.
%   [noFillMode,fillValue] = netcdf.inqVarFill(ncid,varid) returns the 
%   no-fill mode and the fill value itself for the variable varid.  
%   ncid identifies the file or group.
%
%   This function corresponds to the "nc_inq_var_fill" function in the 
%   netCDF library C API.  
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       varid = netcdf.inqVarID(ncid,'temperature');
%       [noFillMode,fillValue] = netcdf.inqVarFill(ncid,varid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.defVarFill, netcdf.setFill.

%   Copyright 2010-2021 The MathWorks, Inc.

[noFillMode,fillValue] = matlab.internal.imagesci.netcdflib('inqVarFill',ncid,varid);
