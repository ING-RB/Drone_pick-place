function dimids = inqDimIDs(ncid,includeParents)
%netcdf.inqDimIDs Return list of dimension identifiers in group.
%   dimIDs = netcdf.inqDimIDs(ncid) returns a list of dimension identifiers
%   in the group specified by ncid.  
%
%   dimIDs = netcdf.inqDimIDs(ncid,includeParents) includes all dimensions 
%   in all parent groups if includeParents is true.  By default, 
%   includeParents is false.
%
%   This function corresponds to the "nc_inq_dimids" function in the 
%   netCDF library C API.  
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       gid = netcdf.inqNcid(ncid,'grid1');
%       dimids = netcdf.inqDimIDs(gid);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.inqVarIDs.

%   Copyright 2010-2021 The MathWorks, Inc.

if nargin < 2
	includeParents = false;
end
dimids = matlab.internal.imagesci.netcdflib('inqDimIDs',ncid,includeParents);
