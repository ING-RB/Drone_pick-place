function [typeName,byteSize,baseTypeID] = inqVlen(ncid,typeID)
%netcdf.inqVlen Return information about a user-defined NC_VLEN type.
%   [typeName,byteSize,baseTypeID] = netcdf.inqVlen(ncid,typeID) returns
%   the name of NC_VLEN type (as a character vector), its size in bytes (as
%   a double), and its base type (numeric type ID, a double value, of the
%   elements inside this variable-length array) for the NC_VLEN type
%   (specified by its numeric typeID) in a NetCDF file (specified by ncid).
%
%   This function corresponds to the "nc_inq_vlen" function in the NetCDF 
%   library C API.
%
%   Example: Define an NC_VLEN type ("MY_VARIABLE_INT_ARRAY") in a new
%   NetCDF4 file and get back information about it.
%       ncid = netcdf.create("myfile.nc","NETCDF4");
%       typeid = netcdf.defVlen(ncid,"MY_VARIABLE_INT_ARRAY","NC_INT");
%       [typeName,byteSize,baseTypeID] = netcdf.inqVlen(ncid,typeid);
%       netcdf.close(ncid)
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqUserType, netcdf.defVlen, netcdf.inqVar

%   Copyright 2021 The MathWorks, Inc.

arguments
    ncid (1,1) {mustBeInteger, mustBePositive}
    typeID (1,1) {mustBeInteger, mustBePositive}
end

[typeName, byteSize, baseTypeID] = ...
    matlab.internal.imagesci.netcdflib('inqVlen', ncid, typeID);  

end