function [flags,cd_values,name,filter_config] = get_filter_by_id(plist_id,filter_id)
%H5P.get_filter_by_id  Return information about specified filter.
%   [flags cd_values name filter_config] = H5P.get_filter_by_id(plist_id,filter_id)
%   returns information about the filter.  plist_id is a property list 
%   identifier. filter_id is the filter identifier and should correspond
%   to one of the following values if using an HDF5 predefined filter:
%
%       H5Z_FILTER_DEFLATE
%       H5Z_FILTER_SZIP
%       H5Z_FILTER_SHUFFLE
%       H5Z_FILTER_FLETCHER32
%
%   For custom third-party filters, filter_id should be the numeric filter
%   identifier assigned by The HDF Group.
%
%   flags specifies the behavior upon filter failure.  H5Z_FLAG_OPTIONAL
%   indicates the filter is to be excluded from the filter pipeline for
%   the chunk on which it failed.  H5Z_FLAG_MANDATORY indicates the HDF5
%   library will error if it encounters any filter failures. 
%   
%   cd_values is the auxiliary data for the filter.
%
%   name is the name of the filter.
%
%   filter_config indicates whether the filter is configured to
%   decode data, encode data, neither, or both.  filter_config should be
%   used with the HDF5 constant values H5Z_FILTER_CONFIG_ENCODE_ENABLED and
%   H5Z_FILTER_CONFIG_DECODE_ENABLED in a bitwise AND operation.  If the
%   resulting value is 0, then the encode or decode functionality is not
%   available.
% 
%   See also H5P, H5P.get_filter, H5P.get_nfilters, H5P.modify_filter,
%   H5P.remove_filter, H5Z.get_filter_info.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    filter_id = convertStringsToChars(filter_id);
end

validateattributes(plist_id,{'H5ML.id'},{'nonempty'});

if isa(filter_id,'numeric')
    % Filter id should not exceed H5Z_FILTER_MAX (65535)
    validateattributes(filter_id,{'numeric'},{'scalar','integer','nonnegative','<=',65535,'nonempty'});
else
    validateattributes(filter_id,{'string','char'},{'scalartext','nonempty'});
end

[flags,cd_values,name,filter_config] = ...
    matlab.internal.sci.hdf5lib2('H5Pget_filter_by_id',plist_id,filter_id);            
