function [typeName,byteSize,baseTypeID,numFields,classID] = inqUserType(ncid,typeID)
%netcdf.inqUserType Return information about a user-defined type.
%   [typeName,byteSize,baseTypeID,numFields,classID] =
%   netcdf.inqUserType(ncid,typeID) returns information about a
%   user-defined type (specified by its numeric typeID) in a NetCDF file
%   (specified by ncid). This information includes the name of the
%   user-defined type (as a character vector), its size in bytes (as a
%   double), the numeric ID of its base type or 0 if not applicable (as a
%   double), its number of fields or 0 if not applicable (as a double), and
%   which class of user-defined types it is (specified as a numeric class
%   ID, a double value, e.g. 13 for NC_VLEN as returned by
%   netcdf.getConstant("NC_VLEN")).
%
%   This function corresponds to the "nc_inq_user_type" function in the
%   NetCDF library C API.
%
%   Example: Define an NC_VLEN type ("MY_VLEN") in a new NetCDF4
%   file and retrieve information about it (note that numFields is not
%   applicable to NC_VLEN types).
%       ncid = netcdf.create("myfile.nc","NETCDF4"); 
%       typeid = netcdf.defVlen(ncid,"MY_VLEN","NC_DOUBLE"); 
%       [typeName,byteSize,baseTypeID,numFields, ...
%           classID] = netcdf.inqUserType(ncid,typeid)
%       netcdf.close(ncid)
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqVlen, netcdf.defVlen, netcdf.inqVar

%   Copyright 2021 The MathWorks, Inc.

arguments
    ncid (1,1) {mustBeInteger, mustBePositive}
    typeID (1,1) {mustBeInteger, mustBePositive}
end

[typeName, byteSize, baseTypeID, numFields, classID] = ...
    matlab.internal.imagesci.netcdflib('inqUserType', ncid, typeID);  