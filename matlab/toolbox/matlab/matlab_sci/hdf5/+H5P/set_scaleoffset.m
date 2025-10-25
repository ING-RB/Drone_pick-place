function set_scaleoffset(plist_id,scaleType,scaleFactor)
%H5P.set_scaleoffset  Setup Scale-Offset filter.
%   H5P.set_scaleoffset(plistId,scaleType,scaleFactor) sets the
%   Scale-Offset filter, H5Z_FILTER_SCALEOFFSET, for a dataset.  For
%   integer datatypes, the parameter scaleType should be set to the
%   enumerated value H5Z_SO_INT.  For floating-point datatypes, the
%   scaleType should be the enumerated value H5Z_SO_FLOAT_DSCALE.  Chunking
%   must already be enabled on the dataset creation property list.
%
%   See also H5P, H5P.set_chunk.

%   Copyright 2009-2024 The MathWorks, Inc.

if nargin > 1
    scaleType = convertStringsToChars(scaleType);
end

if nargin > 2
    scaleFactor = convertStringsToChars(scaleFactor);
end

matlab.internal.sci.hdf5lib2('H5Pset_scaleoffset',...
    plist_id, scaleType, scaleFactor);

