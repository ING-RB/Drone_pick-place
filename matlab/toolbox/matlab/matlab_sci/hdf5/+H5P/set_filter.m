function set_filter(plist_id,filter_id,flags,cd_values)
%H5P.set_filter  Add filter to filter pipeline.
%   H5P.set_filter(plist_id,filter_id,flags,cd_values) adds the specified
%   filter and corresponding properties to the end of an output filter
%   pipeline. plist_id is a property list identifier. filter_id is the filter
%   identifier and should correspond to one of the following values if
%   using an HDF5 predefined filter:
%
%       H5Z_FILTER_DEFLATE
%       H5Z_FILTER_SZIP
%       H5Z_FILTER_SHUFFLE
%       H5Z_FILTER_FLETCHER32
% 
%   For custom third-party filters, filter_id should be the numeric filter
%   identifier assigned by The HDF Group.
%
%   flags is a constant specifying behavior if the filter fails.  Valid
%   values are:
%       H5Z_FLAG_OPTIONAL  In event of filter failure, the filter is
%       excluded from the pipeline for the chunk for which it failed and
%       will not participate in the pipeline during a subsequent read
%       of the chunk. 
%       H5Z_FLAG_MANDATORY  In event of filter failure, the HDF5 library 
%       will issue an error. The library will still write all chunks
%       processed by the filter before the failure occured.  
%
%   cd_values specifies auxiliary data for the filter.
%
%   See also H5P, H5P.set_deflate, H5P.set_fletcher32, H5P.set_shuffle.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    filter_id = convertStringsToChars(filter_id);
end

if nargin > 2
    flags = convertStringsToChars(flags);
end

validateattributes(plist_id,{'H5ML.id'},{'nonempty'});

if isa(filter_id,'numeric')
    validateattributes(filter_id,{'numeric'},{'scalar','integer','nonnegative','nonempty'});
else
    validateattributes(filter_id,{'string','char'},{'scalartext','nonempty'});
end

if isa(flags,'numeric')
    validateattributes(flags,{'numeric'},{'scalar','integer','nonnegative','nonempty'});
else
    validateattributes(flags,{'string','char'},{'scalartext','nonempty'});
end

validateattributes(cd_values,{'numeric'},{});
matlab.internal.sci.hdf5lib2('H5Pset_filter',...
    plist_id,filter_id,flags,cd_values);            
