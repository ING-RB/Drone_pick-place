function idx = idxMapInfo(swathID,geodim,datadim)
%idxMapInfo Retrieve indexed array of geolocation mapping.
%   IDX = idxMapInfo(swathID,GEODIM,DATADIM) retrieves the indexed elements 
%   of the geolocation mapping between GEODIM and DATADIM.
%
%   This function corresponds to the SWidxmapinfo function in the HDF-EOS C
%   library API.
%
%   See also sw, sw.geoMapInfo.

%   Copyright 2010-2017 The MathWorks, Inc.

if nargin > 1
    geodim = convertStringsToChars(geodim);
end

if nargin > 2
    datadim = convertStringsToChars(datadim);
end

[idxsize, idx] = hdf('SW','idxmapinfo',swathID,geodim,datadim);
hdfeos_sw_error(idxsize,'SWidxmapinfo');

idx = idx';
