function oldFormat = setDefaultFormat(newFormat)
%netcdf.setDefaultFormat Change default netCDF file format.
%   oldFormat = netcdf.setDefaultFormat(newFormat) changes the format 
%   of subsequently created files to newFormat and returns the value of the
%   old format.  newFormat can be one of the following strings or the
%   numeric equivalent:
%
%       'FORMAT_CLASSIC'
%       'FORMAT_64BIT'
%       'FORMAT_NETCDF4'
%       'FORMAT_NETCDF4_CLASSIC'
%
%   This setting persists for the remainder of the MATLAB session or until
%   a 'clear mex' is issued.
%   
%   To use this function, you should be familiar with the information about 
%   netCDF contained in the "NetCDF C Interface Guide".  This function 
%   corresponds to the "nc_set_default_format" function in the netCDF 
%   library C API.
% 
%   Example:
%       newFormat = netcdf.getConstant('FORMAT_NETCDF4_CLASSIC');
%       oldFormat = netcdf.setDefaultFormat(newFormat);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqFormat, netcdf.getConstant.
%

%   Copyright 2008-2021 The MathWorks, Inc.

if nargin > 0
    newFormat = convertStringsToChars(newFormat);
end

if ischar(newFormat)
    newFormat = netcdf.getConstant(newFormat);
end

oldFormat = matlab.internal.imagesci.netcdflib('setDefaultFormat',newFormat);
