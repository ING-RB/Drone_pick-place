function delAtt(ncid,varid,attname)
%netcdf.delAtt Delete netCDF attribute.
%   netcdf.delAtt(ncid,varid,attName) deletes the attribute identified
%   by attName from the variable identified by varid.  In order to delete
%   a global attribute, use netcdf.getConstant('GLOBAL') for the varid.
%
%   This function corresponds to the "nc_del_att" function in the netCDF 
%   library C API.
%
%   Example:
%       srcFile = which('example.nc');
%       copyfile(srcFile,'myfile.nc');
%       fileattrib('myfile.nc','+w');
%       ncid = netcdf.open('myfile.nc','WRITE');
%       netcdf.reDef(ncid);
%       netcdf.delAtt(ncid,netcdf.getConstant('GLOBAL'),'creation_date');
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.putAtt, netcdf.getConstant.

%   Copyright 2008-2021 The MathWorks, Inc.

if nargin > 2
    attname = convertStringsToChars(attname);
end

matlab.internal.imagesci.netcdflib('delAtt', ncid, varid, attname);
