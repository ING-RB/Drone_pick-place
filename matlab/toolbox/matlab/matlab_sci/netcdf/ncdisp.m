function ncdisp(ncFile, location, modestr)
%

%NCDISP Display contents of a NetCDF source in command window.
%
%    NCDISP(FILENAME) displays the groups, dimensions, variable definitions
%    and all attributes in the NetCDF file FILENAME as text in the command
%    window.
%
%    NCDISP(OPENDAP_URL) displays information from an OPeNDAP NetCDF data
%    source.
%
%    NCDISP(HTTP_URL) displays information from a remote NetCDF data source
%    using its HTTP URL (with the #mode=bytes suffix for byte-range
%    reading).
%
%    NCDISP(SOURCE, LOCATION) displays information about the variable or
%    group specified by the string LOCATION in SOURCE, which can either be
%    a filename or an OPeNDAP URL. Set LOCATION to '/' to display entire
%    file contents.
%
%    NCDISP(SOURCE, LOCATION, MODESTR) displays the contents of the
%    LOCATION according to the value of MODESTR. Valid values for MODESTR
%    are:
%
%     'min'  - display variable definitions only. 
%
%     'full' - display dimensions, attributes and variable definitions.
%              This is the default value.
%
%
%    Example: Visually inspect a NetCDF file.
%       ncdisp('example.nc');
%
%    Example: Visually inspect a NetCDF file, hide the attributes.
%       ncdisp('example.nc','/','min');
%
%    Example: Visually inspect the full details of a variable.
%       ncdisp('example.nc','peaks');
%
%    Example: Visually inspect a remote NetCDF source using its HTTP URL
%    (with byte-range reading).
%       ncdisp("http://hostname/path_to_file/sample.nc#mode=bytes");
%
%    See also ncinfo, ncread, ncreadatt, ncwrite, netcdf.

%   Copyright 2010-2022 The MathWorks, Inc.

% Defaults
if nargin > 0
    ncFile = convertStringsToChars(ncFile);
end

if nargin > 1
    location = convertStringsToChars(location);
end

if nargin > 2
    modestr = convertStringsToChars(modestr);
end

switch nargin
    case 1
        location = '/';
        modestr  = 'full';
    case 2
        modestr  = 'full';        
end
        

ncObj   = internal.matlab.imagesci.nc(ncFile);
cleanUp = onCleanup(@()ncObj.close());

ncObj.setDisplayMode(modestr);


ncObj.disp(location);


