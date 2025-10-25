function renameVar(ncid,varid,new_name)
%netcdf.renameVar Change name of netCDF variable.
%   netcdf.renameVar(ncid,varid,newName) renames the variable identified 
%   by varid in the netCDF file or group associated with ncid.
%
%   This function corresponds to the "nc_rename_var" function in the netCDF
%   library C API.
%
%   Example:
%       srcFile = which('example.nc');
%       copyfile(srcFile,'myfile.nc');
%       fileattrib('myfile.nc','+w');
%       ncid = netcdf.open('myfile.nc','WRITE');
%       varid = netcdf.inqVarID(ncid,'temperature');
%       netcdf.renameVar(ncid,varid,'fahrenheight_temperature');
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.renameDim, netcdf.renameAtt.

%   Copyright 2008-2021 The MathWorks, Inc.

if nargin > 2
    new_name = convertStringsToChars(new_name);
end

matlab.internal.imagesci.netcdflib('renameVar', ncid, varid, new_name);            
