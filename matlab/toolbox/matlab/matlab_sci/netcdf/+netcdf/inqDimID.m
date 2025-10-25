function dimid = inqDimID(ncid,dimname)
%netcdf.inqDimID Return dimension ID.
%   dimid = netcdf.inqDimID(ncid,dimname) returns the ID of a dimension
%   given the name.
%
%   To use this function, you should be familiar with the information about 
%   netCDF contained in the "NetCDF C Interface Guide".  This function 
%   corresponds to the "nc_inq_dimid" function in the netCDF library C API.
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       dimid = netcdf.inqDimID(ncid,'x');
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqDim.

%   Copyright 2008-2021 The MathWorks, Inc.

if nargin > 1
    dimname = convertStringsToChars(dimname);
end

dimid = matlab.internal.imagesci.netcdflib('inqDimID', ncid,dimname);            
