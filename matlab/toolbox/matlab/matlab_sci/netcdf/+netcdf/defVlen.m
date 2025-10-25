function typeID = defVlen(ncid,typeName,baseType)
%netcdf.defVlen Define a new NC_VLEN type.
%   typeID = netcdf.defVlen(ncid,typeName,baseType) creates a new NC_VLEN
%   (variable length array) type with the given typeName and baseType in
%   the file identified by ncid. The typeName is the name of the new
%   NC_VLEN type specified as a text scalar, and the baseType is the type
%   of the elements this variable-length array type will contain (specified
%   as a text scalar like 'NC_DOUBLE' or as the equivalent numeric type
%   ID). The return value is the numeric type ID corresponding to the new
%   user-defined NC_VLEN type.
%
%   This function corresponds to the "nc_def_vlen" function in the NetCDF 
%   library C API.
%
%   Example: Define an NC_VLEN type ("MY_VARIABLE_LENGTH_SAMPLE") in a new
%   NetCDF4 file and create and write a variable of this new type.
%       ncid = netcdf.create("myfile.nc","NETCDF4");
%       typeid = netcdf.defVlen(ncid,"MY_VARIABLE_LENGTH_SAMPLE","NC_FLOAT");
%       dimid = netcdf.defDim(ncid,"TIME",3);
%       varid = netcdf.defVar(ncid,"samples",typeid,dimid);
%       netcdf.putVar(ncid,varid,{single([0.1 0.2]), ...
%           single([2.333 7.94 0.5 0]),single(4.2)});
%       netcdf.close(ncid)
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqVlen, netcdf.inqUserType, netcdf.defVar
%
%   Note: NC_VLEN is available only in NetCDF4 files

%   Copyright 2021 The MathWorks, Inc.

arguments
    ncid (1,1) {mustBeInteger, mustBePositive}
    typeName (1,:) {mustBeTextScalar}
    baseType
end

typeName = convertStringsToChars(typeName);
baseType = validateNetCDFType(baseType, "baseType");

typeID = matlab.internal.imagesci.netcdflib('defVlen', ...
    ncid, typeName, baseType);            
