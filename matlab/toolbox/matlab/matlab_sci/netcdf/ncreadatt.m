function attValue = ncreadatt(ncFile, location, attName)
%

%NCREADATT Read attribute value from a NetCDF source.
%
%    ATTVALUE = NCREADATT(FILENAME, LOCATION, ATTNAME) reads the
%    attribute ATTNAME from the group or variable specified by the string
%    LOCATION. To read global attributes set LOCATION to '/'.
%
%    ATTVALUE = NCREADATT(OPENDAP_URL, LOCATION, ATTNAME) reads from an
%    OPeNDAP NetCDF data source.
%
%    ATTVALUE = NCREADATT(HTTP_URL, LOCATION, ATTNAME) reads from a remote
%    NetCDF source using its HTTP URL (with the #mode=bytes suffix for
%    byte-range reading).
%
%    Example: Read a global attribute.
%      creation_date = ncreadatt('example.nc','/','creation_date');
%      disp(creation_date);
%
%    Example: Read a variable attribute.
%      scale_factor = ncreadatt('example.nc','temperature','scale_factor');
%      disp(scale_factor);
%
%    Example: Read a global attribute from a remote NetCDF source using its
%    HTTP URL (with byte-range reading).
%      attData =
%      ncreadatt("http://hostname/path_to_file/sample.nc#mode=bytes","/","attribute_name");
%      disp(attData);
%
%    See also ncread, ncinfo, ncdisp, ncwriteatt, netcdf.

%   Copyright 2010-2022 The MathWorks, Inc.

if nargin > 0
    ncFile = convertStringsToChars(ncFile);
end

if nargin > 1
    location = convertStringsToChars(location);
end

if nargin > 2
    attName = convertStringsToChars(attName);
end

ncObj    = internal.matlab.imagesci.nc(ncFile);
cleanUp  = onCleanup(@()ncObj.close());

attValue = ncObj.readAttribute(location, attName);
