function defVarFill(ncid,varid,noFillMode,fillvalue)
%netcdf.defVarFill Sets fill parameters for a variable in a netCDF-4 file.
%   netcdf.defVarFill(ncid,varid,noFillMode,fillValue) sets the fill 
%   parameters for a netCDF variable identified by varid.  ncid specifies 
%   the location.  fillValue must be the same datatype as the variable.
%
%   When noFillMode is set to true, fill values will not be written for the
%   variable and any value supplied for fillValue will be ignored. This is
%   helpful in high performance applications.  This should never be done
%   after calling netcdf.endDef.
%
%   This function corresponds to the "nc_def_var_fill" function in the 
%   netCDF library C API.  
%
%   Example:
%       ncid = netcdf.create('myfile.nc','NETCDF4');
%       dimid =  netcdf.defDim(ncid,'latitude',180);
%       varid = netcdf.defVar(ncid,'latitude','double',dimid);
%       netcdf.defVarFill(ncid,varid,false,-999);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.setFill, netcdf.inqVarFill.

%   Copyright 2010-2023 The MathWorks, Inc.

[~,xtype,~,~] = netcdf.inqVar(ncid,varid);

% only convert fillvalue to chars for atomic types
if nargin > 3 && xtype < netcdf.getConstant("NC_FIRSTUSERTYPEID")
    fillvalue = convertStringsToChars(fillvalue);
end

% validate NC_VLEN fill value
if xtype >= netcdf.getConstant("NC_FIRSTUSERTYPEID")
    validateattributes(fillvalue, {'cell'}, ...
        {'nonempty','scalar'}, '', 'FILLVALUE')
    fillvalue = validateVLEN(fillvalue, ...
        ncid, xtype);
end

matlab.internal.imagesci.netcdflib('defVarFill',ncid,varid,noFillMode,fillvalue);
