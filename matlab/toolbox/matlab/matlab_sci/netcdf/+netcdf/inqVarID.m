function varid = inqVarID(ncid,varname)
%netcdf.inqVarID Return ID associated with variable name.
%   varid = netcdf.inqVarID(ncid,varname) returns the ID of a netCDF 
%   variable identified by varname.
%
%   This function corresponds to the "nc_inq_varid" function in the netCDF
%   library C API.
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       varid = netcdf.inqVarID(ncid,'temperature');
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqVar.

%   Copyright 2010-2021 The MathWorks, Inc.

if nargin > 1
    varname = convertStringsToChars(varname);
end

varid = matlab.internal.imagesci.netcdflib('inqVarID', ncid, varname);            
