function filter_config_flags = get_filter_info(filter_id)
%H5Z.get_filter_info  Return information about specified filter.
%   [filter_config_flags] = H5Z.get_filter_info(filter_id) retrieves
%   information about the filter specified by its identifier. At present,
%   the information returned is the filter's configuration flags,
%   indicating whether the filter is configured to decode data, to encode
%   data, neither, or both.  filter_config_flags should be used with the
%   HDF5 constant values H5Z_FILTER_CONFIG_ENCODE_ENABLED and
%   H5Z_FILTER_CONFIG_DECODE_ENABLED in a bitwise AND operation.  If the
%   resulting value is 0, then the encode or decode functionality is not
%   available.
%
%   For custom third-party filters, filter_id should be the numeric filter
%   identifier assigned by The HDF Group.
%
%   Example:  determine if encoding is enabled for the deflate filter.
%       flags = H5Z.get_filter_info('H5Z_FILTER_DEFLATE');
%       functionality = H5ML.get_constant_value('H5Z_FILTER_CONFIG_ENCODE_ENABLED');
%       enabled = bitand(flags,functionality) > 0;
%      
%   See also H5Z, H5Z.filter_avail, H5ML.get_constant_value, bitand.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 0
    filter_id = convertStringsToChars(filter_id);
end

if isa(filter_id,'numeric')
    validateattributes(filter_id,{'numeric'},...
        {'scalar','integer','nonnegative','nonempty'});
else
    validateattributes(filter_id,{'string','char'},{'scalartext','nonempty'});
end

try
    filter_config_flags = matlab.internal.sci.hdf5lib2(...
        'H5Zget_filter_info',filter_id);            
catch me
    if (strcmp(me.identifier,'MATLAB:imagesci:hdf5lib:libraryError'))
        filter_config_flags = 0;
    else
        rethrow(me);
    end
end
