function output = filter_avail(filter_id)
%H5Z.filter_avail  Determine availability of specified filter.
%   output = H5Z.filter_avail(filter_id) determines whether the filter specified
%   by the filter identifier is available to the application.  filter_id
%   may be specified by one of the following strings or its numeric
%   equivalent:
%
%       'H5Z_FILTER_DEFLATE'
%       'H5Z_FILTER_SHUFFLE'
%       'H5Z_FILTER_FLETCHER32'
%       'H5Z_FILTER_SZIP'
%       'H5Z_FILTER_NBIT'
%       'H5Z_FILTER_SCALEOFFSET'
%
%   For custom third-party filters, filter_id should be the numeric filter
%   identifier assigned by The HDF Group.
%
%   Example:  determine if the shuffle filter is available.
%       bool = H5Z.filter_avail('H5Z_FILTER_SHUFFLE');
%
%   See also H5Z, H5ML.get_constant_value.

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

output = matlab.internal.sci.hdf5lib2('H5Zfilter_avail',filter_id);
