function setDataStrs(sdsID,label,unit,format,coordsys)
%setDataStrs Set predefined attributes for a data set.
%   setDataStrs(sdsID,LABEL,UNIT,FORMAT,COORDSYS) sets the predefined
%   attributes 'long_name', 'units', 'format', and 'coordsys' for a data 
%   set.  
%   
%   Example:
%       import matlab.io.hdf4.*
%       sdID = sd.start('myfile.hdf','create');
%       sdsID = sd.create(sdID,'temperature','double',[10 20]);
%       sd.setDataStrs(sdsID,'degrees_celsius','degrees_east','','geo');
%       sd.endAccess(sdsID);
%       sd.close(sdID);
%
%   This function corresponds to the SDsetdatastrs function in the HDF
%   library C API.
%
%   See also sd, sd.getDataStrs, sd.setDimStrs.

%   Copyright 2010-2017 The MathWorks, Inc.

if nargin > 1
    label = convertStringsToChars(label);
end

if nargin > 2
    unit = convertStringsToChars(unit);
end

if nargin > 3
    format = convertStringsToChars(format);
end

if nargin > 4
    coordsys = convertStringsToChars(coordsys);
end

status = hdf('SD','setdatastrs',sdsID,label,unit,format,coordsys);
if status < 0
    hdf4_sd_error('SDsetdatastrs');
end
