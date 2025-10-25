function putVar(ncid,varid,varargin)
%netcdf.putVar Write data to netCDF variable.
%   netcdf.putVar(ncid,varid,data) writes data to an entire netCDF
%   variable identified by varid and the file or group identified by ncid.
%
%   netcdf.putVar(ncid,varid,start,data) writes a single data value into 
%   the variable at the specified index. 
%
%   netcdf.putVar(ncid,varid,start,count,data) writes an array section 
%   of values into the netCDF variable.  The array section is specified 
%   by the start and count vectors, which give the starting index and 
%   count of values along each dimension of the specified variable.
%
%   netcdf.putVar(ncid,varid,start,count,stride,data) uses a sampling 
%   interval given by the stride argument.
%
%   This function corresponds to the "nc_put_var" family of functions in 
%   the netCDF library C API.
%
%   Example:  Write to the first ten elements of the example 'temperature'
%   variable.
%       srcFile = which('example.nc');
%       copyfile(srcFile,'myfile.nc');
%       fileattrib('myfile.nc','+w');
%       ncid = netcdf.open('myfile.nc','WRITE');
%       varid = netcdf.inqVarID(ncid,'temperature');
%       data = [100:109];
%       netcdf.putVar(ncid,varid,0,10,data);
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.getVar.

%   Copyright 2008-2021 The MathWorks, Inc.

% Ensure correct datatype for text-based variables
[~,xtype,~,~] = netcdf.inqVar(ncid,varid);
% Last input argument is always the data to be written.
% Make sure it is string for NC_STRING, and char for NC_CHAR
if (xtype == netcdf.getConstant('NC_CHAR'))

    [varargin{end}] = convertStringsToChars(varargin{end});

    % do not allow string arrays
    if iscell(varargin{end})
        error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                'string array', 'char'));
    end
elseif (xtype == netcdf.getConstant('NC_STRING'))

    % do not allow character matrices
    if ischar(varargin{end}) && ~isvector(varargin{end})
        error(message('MATLAB:imagesci:netcdf:charMatrixString'));
    end

    [varargin{end}] = convertCharsToStrings(varargin{end});
end

narginchk(3,6);
% Which family of functions?
switch nargin
  case 3
    funcstr = 'putVar';
  case 4
    funcstr = 'putVar1';
  case 5
    funcstr = 'putVara';
  case 6
    funcstr = 'putVars';
end


% Finalize the function string from the appropriate datatype.
% ('cell' is for NC_VLEN data)
validateattributes(varargin{end}, {'numeric', 'char', 'string', 'cell'}, ...
    {}, '', 'DATA');
switch ( class(varargin{end}) )
    case 'double'
        funcstr = [funcstr 'Double'];
    case 'single'
        funcstr = [funcstr 'Float'];
    case 'int64'
        funcstr = [funcstr 'Int64'];
    case 'uint64'
        funcstr = [funcstr 'Uint64'];
    case 'int32'
        funcstr = [funcstr 'Int'];
    case 'uint32'
        funcstr = [funcstr 'Uint'];
    case 'int16'
        funcstr = [funcstr 'Short'];
    case 'uint16'
        funcstr = [funcstr 'Ushort'];
    case 'int8'
        funcstr = [funcstr 'Schar'];
    case 'uint8'
        funcstr = [funcstr 'Uchar'];
    case 'char'
        funcstr = [funcstr 'Text'];
    case 'string'
        funcstr = [funcstr 'String'];
    case 'cell'
        % validate that xtype is user-defined NC_VLEN type
        % and that cell array is homogeneous and matches that
        % NC_VLEN type's definition
        varargin{end} = validateVLEN(varargin{end}, ...
            ncid, xtype);
        funcstr = [funcstr 'Vlen'];
end


% Invoke the correct netCDF library routine.
matlab.internal.imagesci.netcdflib(funcstr,ncid,varid,varargin{:});
