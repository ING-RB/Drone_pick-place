function varid = defVar(ncid,varname,xtype,dimids)
%netcdf.defVar Create netCDF variable.
%   varid = netcdf.defVar(ncid,varname,xtype,dimids) creates a new 
%   variable given a name, datatype, and list of dimension IDs.  The
%   datatype is given by xtype, and can be specified as a string scalar or
%   character vector (e.g. 'NC_DOUBLE'), or as the equivalent numeric value
%   returned by the netcdf.getConstant function. For user-defined NC_VLEN
%   types, specify xtype as the numeric value returned by the
%   netcdf.defVlen function. The return value, varid, is the numeric ID
%   corresponding to the new variable.
%
%   This function corresponds to the "nc_def_var" function in the netCDF
%   library C API, but because MATLAB uses FORTRAN-style ordering, the
%   fastest-varying dimension comes first and the slowest comes last. Any
%   unlimited dimension is therefore last in the list of dimension IDs.
%   This ordering is the reverse of that found in the C API.
%
%   Example:  Create a coordinate variable called 'latitude'.  A coordinate
%   variable is a variable that has exactly one dimension with the same
%   name.
%       ncid = netcdf.create('myfile.nc','CLOBBER');
%       dimid =  netcdf.defDim(ncid,'latitude',180);
%       varid = netcdf.defVar(ncid,'latitude','NC_DOUBLE',dimid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.getConstant, netcdf.inqVar, netcdf.putVar
%

%   Copyright 2008-2021 The MathWorks, Inc.

if nargin > 1
    varname = convertStringsToChars(varname);
end

if nargin > 2
    xtype = convertStringsToChars(xtype);
end

if ischar(xtype)
    xtype = netcdf.getConstant(xtype);
end

varid = matlab.internal.imagesci.netcdflib('defVar', ncid, varname, xtype, dimids);            
