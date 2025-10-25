function renameDim(ncid,dimid,new_name)
%netcdf.renameDim Change name of netCDF dimension.
%   netcdf.renameDim(ncid,dimid,newName) renames a dimension identified
%   by dimid to the new name.
%
%   To use this function, you should be familiar with the information about 
%   netCDF contained in the "NetCDF C Interface Guide".  This function 
%   corresponds to the "nc_rename_dim" function in the netCDF library C 
%   API.
%
%   Example:
%       srcFile = which('example.nc');
%       copyfile(srcFile,'myfile.nc');
%       fileattrib('myfile.nc','+w');
%       ncid = netcdf.open('myfile.nc','WRITE');
%       netcdf.reDef(ncid);
%       dimid = netcdf.inqDimID(ncid,'x');
%       netcdf.renameDim(ncid,dimid,'new_x');
%       netcdf.close(ncid);
%       
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.reDef, netcdf.renameVar.
%

%   Copyright 2008-2021 The MathWorks, Inc.

if nargin > 2
    new_name = convertStringsToChars(new_name);
end

matlab.internal.imagesci.netcdflib('renameDim', ncid, dimid, new_name);            
