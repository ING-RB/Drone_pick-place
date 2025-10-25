function abort(ncid)
%netcdf.abort Revert recent netCDF file definitions.
%   netcdf.abort(ncid) will revert a netCDF file out of any definitions
%   made after netcdf.create but before netcdf.endDef.  The file will
%   also be closed.
%
%   This function corresponds to the function "nc_abort" in the netCDF 
%   library C API.
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.create, netcdf.endDef.
%

%   Copyright 2008-2021 The MathWorks, Inc.

matlab.internal.imagesci.netcdflib('abort',ncid);
