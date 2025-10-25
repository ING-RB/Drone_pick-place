function set_chunk_opts(dcpl_id,options)
%H5P.set_chunk_opts  Set dataset edge chunk option.
%   H5P.set_chunk_opts specifies storage options for chunks on the
%   edge of a dataset's dataspace for dataset creation property 
%   list dcpl_id.  This allows for performance tuning in cases
%   where the dataset size may not be a multiple of the chunk size
%   and the handling of partial edge chunks can impact performance. 
%   options is the edge chunk option flag.  Valid values are:
%
%       'H5D_CHUNK_DONT_FILTER_PARTIAL_CHUNKS' 
%           Partial edge chunks will not be filtered.
%       0 (zero, default)
%           Partial edge chunks will be filtered.
% 
%   Example:
%       dcplID = H5P.create('H5P_DATASET_CREATE');
%       H5P.set_layout(dcplID,'H5D_CHUNKED');      
%       % Default value
%       chunk_opts = H5P.get_chunk_opts(dcplID) % should be 0
%       % Set the chunk options flag to not filter partial chunks 
%       H5P.set_chunk_opts(dcplID,'H5D_CHUNK_DONT_FILTER_PARTIAL_CHUNKS');
%       chunk_opts = H5P.get_chunk_opts(dcplID) % should be 2
%       % Set the chunk options flag to 0 (disabled) again
%       H5P.set_chunk_opts(dcplID,0);
%       chunk_opts = H5P.get_chunk_opts(dcplID) % should be 0
%
%   See also H5P, H5P.get_chunk_opts.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dcpl_id,{'H5ML.id'},{'nonempty','scalar'});

if isstring(options)
    options = convertStringsToChars(options);
end

if ~isnumeric(options)
    validateattributes(options,{'char','string'},{'nonempty','scalartext'});
    options = convertStringsToChars(options);
else
    validateattributes(options,{'double'},{'scalar','integer'});
end

matlab.internal.sci.hdf5lib2('H5Pset_chunk_opts',dcpl_id,options);
