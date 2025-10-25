function attid = inqAttID(ncid,varid,attname)
%netcdf.inqAttID Return ID of netCDF attribute.
%   attnum = netcdf.inqAttID(ncid,varid,attname) retrieves the 
%   number of the attribute associated with the attribute name.
%
%   This function  corresponds to the "nc_inq_att_id" function in the 
%   netCDF library C API.
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       varid = netcdf.inqVarID(ncid,'temperature');
%       attid = netcdf.inqAttID(ncid,varid,'scale_factor');
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqAtt.

%   Copyright 2008-2021 The MathWorks, Inc.

if nargin > 2
    attname = convertStringsToChars(attname);
end

attid = matlab.internal.imagesci.netcdflib('inqAttID', ncid, varid,attname);            
