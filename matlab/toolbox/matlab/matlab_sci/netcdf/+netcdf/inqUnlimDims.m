function dimids = inqUnlimDims(ncid)
%netcdf.inqUnlimDims Return list of unlimited dimensions visible in group.
%   unlimdimIDs = netcdf.inqUnlimDims(ncid) returns the IDs of all 
%   unlimited dimensions in the group specified by ncid.  unlimDimIDs will 
%   be the empty set if no such unlimited dimensions exist.
%
%   This function corresponds to the "nc_inq_unlim_dims" function in the 
%   netCDF library C API.
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       dimids = netcdf.inqUnlimDims(ncid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.defDim, netcdf.inqDim, netcdf.inqDimID,
%   netcdf.renameDim, netcdf.inqDimIDs.
    
%   Copyright 2010-2021 The MathWorks, Inc.

dimids = matlab.internal.imagesci.netcdflib('inqUnlimDims',ncid);            
