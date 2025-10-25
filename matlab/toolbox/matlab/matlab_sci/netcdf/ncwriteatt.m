function ncwriteatt(ncFile, location, attName, attValue, varargin)
%

%NCWRITEATT Write attribute to NetCDF file.
%
%    NCWRITEATT(FILENAME, LOCATION, ATTNAME, ATTVALUE) create or modify
%    an attribute ATTNAME in the group or variable specified by LOCATION.
%    To specify global attributes, set LOCATION to '/'. ATTVALUE can be a
%    numeric vector, a character vector or a scalar string. For netcdf4
%    files, ATTVALUE can also be a vector of strings.
%
%    NCWRITEATT supports the following optional Name-Value Pair Argument:
%
%    'Datatype'     The datatype of the NetCDF attribute. Specify the
%                   datatype as one of the following values on the left:
%
%              Value of 'Datatype'     NetCDF type of the attribute
%                    'double'               NC_DOUBLE
%                    'single'               NC_FLOAT
%                    'int64'                NC_INT64*
%                    'uint64'               NC_UINT64*
%                    'int32'                NC_INT
%                    'uint32'               NC_UINT*
%                    'int16'                NC_SHORT
%                    'uint16'               NC_USHORT*
%                    'int8'                 NC_BYTE
%                    'uint8'                NC_UBYTE*
%                    'char'                 NC_CHAR
%                    'string'               NC_STRING*
%               * These datatypes are only available with netcdf4 format.
%
%    Example: Create a global attribute.
%      copyfile(which('example.nc'),'myfile.nc');
%      fileattrib('myfile.nc','+w');
%      ncdisp('myfile.nc');
%      ncwriteatt('myfile.nc','/','modification_date',datestr(now));
%      ncdisp('myfile.nc');
%
%    Example: Modify an existing variable attribute.
%      copyfile(which('example.nc'),'myfile.nc');
%      fileattrib('myfile.nc','+w');
%      ncdisp('myfile.nc','peaks');
%      ncwriteatt('myfile.nc','peaks','description','Output of PEAKS');
%      ncdisp('myfile.nc','peaks');
%
%    See also ncdisp, ncreadatt, ncwrite, ncread, nccreate, netcdf.

%   Copyright 2010-2024 The MathWorks, Inc.


if nargin > 0
    ncFile = convertStringsToChars(ncFile);
end

if nargin > 1
    location = convertStringsToChars(location);
end

if nargin > 2
    attName = convertStringsToChars(attName);
end

if nargin > 4 % datatype was specified
    [varargin{:}] = convertStringsToChars(varargin{:});
end

%error out if file does not exist.
if(~exist(ncFile,'file'))
    error(message('MATLAB:imagesci:netcdf:fileDoesNotExist', ncFile));
end

% Files hosted in server for byte-range or OpeNDAP access usually do not
% have write permissions
% Use fopen to check if the file has writing permissions.
fid = -1;
try
    fid = fopen(ncFile, 'r+');
catch ME
    % For errors other than 'MATLAB:httpsError' (which is thrown when fopen
    % is called on http/https links with write mode), rethrow
    if ~strcmp(ME.identifier,'MATLAB:httpsError')
        rethrow(ME);
    end
end
% Throw the error below if fopen errors while opening a hyperlink in write
% mode or if fid == -1
if (fid == -1)
    error(message('MATLAB:imagesci:netcdf:unableToOpenforWrite', ncFile));
end
fclose(fid);

ncObj   = internal.matlab.imagesci.nc(ncFile,'a');
cleanUp = onCleanup(@()ncObj.close());


ncObj.writeAttribute(location, attName, attValue, varargin{:});

