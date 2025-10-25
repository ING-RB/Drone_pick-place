function varargout = open(filename, varargin)
%netcdf.open Open NetCDF source.
%   ncid = netcdf.open(filename) opens an existing file in read-only mode.
%   ncid = netcdf.open(opendapURL) opens an OPeNDAP NetCDF data source in
%   read-only mode.
%
%   ncid = netcdf.open(httpURL) accesses an HTTP URL of a remote NetCDF
%   data source to open the source in read-only mode (with the #mode=bytes
%   suffix for byte-range reading).
%
%   ncid = netcdf.open(filename, mode) opens a NetCDF file and returns a
%   netCDF ID in ncid. The type of access is described by the mode
%   parameter,  which can be 'WRITE' for read-write access, 'SHARE' for
%   synchronous file updates, or 'NOWRITE' for read-only access.  The mode
%   may also be a numeric value that can be retrieved via
%   netcdf.getConstant.  The mode may also be a bitwise-or of numeric mode
%   values.
%
%   [chosen_chunksize, ncid] = netcdf.open(filename, mode, chunksize)
%   is similar to the above, but makes use of an additional
%   performance tuning parameter, chunksize, which can affect I/O
%   performance.  The actual value chosen by the netCDF library may
%   not correspond to the input value.
%
%   This function corresponds to the "nc_open" and "nc__open" functions in
%   the netCDF library C API.
%
%   Example:
%       ncid = netcdf.open('example.nc','NOWRITE');
%       netcdf.close(ncid);
%
%   Example: Open a remote NetCDF data source in read-only mode using
%   byte-range reading
%       ncid =
%       netcdf.open("http://hostname/path_to_file/sample.nc#mode=bytes");
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.close, netcdf.getConstant.


%   Copyright 2008-2022 The MathWorks, Inc.

if nargin > 0
    filename = convertStringsToChars(filename);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(1,3);

if contains(filename, '://')
    % OPeNDAP link
else
    % Get the full path name.
    fid = fopen(filename,'r');
    if fid == -1
        error(message('MATLAB:imagesci:validate:fileOpen',filename));
    end
    filename = fopen(fid);
    fclose(fid);
end


if(nargin>=2 && ischar(varargin{1}))
    varargin{1} = netcdf.getConstant(varargin{1});
end
varargout = cell(1,nargout);
switch nargin
    case 1
        [varargout{:}] = matlab.internal.imagesci.netcdflib('open', ...
            filename, 'NOWRITE');        
    case 2
        [varargout{:}] = matlab.internal.imagesci.netcdflib('open', ...
            filename, varargin{1});
    case 3
        [varargout{:}] = matlab.internal.imagesci.netcdflib('pOpen', ...
            filename, varargin{1}, varargin{2});
end

