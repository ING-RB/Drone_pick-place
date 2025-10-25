function remove_filter(plist_id,filter_id)
%H5P.remove_filter  Remove filter from property list.
%   H5P.remove_filter(plist_id,filter_id) removes the specified filter from
%   the filter pipeline.  plist_id is the dataset creation property list
%   identifier.  filter_id is the filter identifier and should correspond to
%   one of the following values if using an HDF5 predefined filter:
%
%       H5Z_FILTER_DEFLATE
%       H5Z_FILTER_SZIP
%       H5Z_FILTER_SHUFFLE
%       H5Z_FILTER_FLETCHER32
% 
%   For custom third-party filters, filter_id should be the numeric filter
%   identifier assigned by The HDF Group.
%
%   See also H5P, H5P.get_filter, H5P.get_nfilters, H5P.get_filter_by_id,
%   H5P.modify_filter.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    filter_id = convertStringsToChars(filter_id);
end

validateattributes(plist_id,{'H5ML.id'},{'nonempty'});

if isa(filter_id,'numeric')
    validateattributes(filter_id,{'numeric'},{'scalar','integer','nonnegative','nonempty'});
else
    validateattributes(filter_id,{'string','char'},{'scalartext','nonempty'});
end

matlab.internal.sci.hdf5lib2('H5Premove_filter',plist_id,filter_id);            
