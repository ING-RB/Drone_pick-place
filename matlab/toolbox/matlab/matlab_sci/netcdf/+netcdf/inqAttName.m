function attname = inqAttName(ncid,varid,attnum)
%netcdf.inqAttName Return name of netCDF attribute.
%   attname = netcdf.inqAttName(ncid,varid,attnum) returns
%   the name of an attribute given the attribute number.
%
%   This function corresponds to the "nc_inq_attname" function in the 
%   netCDF library C API.
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       varid = netcdf.inqVarID(ncid,'temperature');
%       attname = netcdf.inqAttName(ncid,varid,0);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqAtt, netcdf.inqAttID.

%   Copyright 2008-2021 The MathWorks, Inc.

attname = matlab.internal.imagesci.netcdflib('inqAttName', ncid, ...
    varid, attnum);            
