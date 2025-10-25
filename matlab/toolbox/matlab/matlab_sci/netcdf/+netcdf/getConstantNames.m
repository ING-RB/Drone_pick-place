function names = getConstantNames()
%netcdf.getConstantNames Return list of constants known to netCDF library.
%   names = netcdf.getConstantNames() returns a list of names of netCDF 
%   library constants, definitions, and enumerations.  When these 
%   strings are supplied as actual parameters to the netCDF namespace 
%   functions, they will automatically be converted to the appropriate 
%   numeric value.
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.create, netcdf.defVar, netcdf.open, 
%   netcdf.setDefaultFormat, netcdf.setFill.
%

%   Copyright 2008-2023 The MathWorks, Inc.

names = matlab.internal.imagesci.netcdflib('getConstantNames');
names = sort(names);

