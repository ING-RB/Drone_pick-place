function options = get_chunk_opts(dcpl_id)
%H5P.get_chuck_opts  Get dataset edge chunk option setting.
%   options = get_chuck_opts(dcpl_id) retrieves the edge chunk option
%   setting stored in the dataset creation property list dcpl_id.
%
%   Example:
%       % Create the dataset creation property list and set the layout as chunked
%       dcplID = H5P.create('H5P_DATASET_CREATE');
%       H5P.set_layout(dcplID,'H5D_CHUNKED');
%       % Query the default value of chunk_opts
%       chunk_opts = H5P.get_chunk_opts(dcplID);
%       % Set the chunk_opts to 'H5D_CHUNK_DONT_FILTER_PARTIAL_CHUNKS' and query the chunk_opts value
%       H5P.set_chunk_opts(dcplID,'H5D_CHUNK_DONT_FILTER_PARTIAL_CHUNKS');
%       chunk_opts = H5P.get_chunk_opts(dcplID);
%       H5P.close(dcplID);
%
%   See also H5P, H5P.set_chunk_opts.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dcpl_id,{'H5ML.id'},{'nonempty','scalar'});
options = matlab.internal.sci.hdf5lib2('H5Pget_chunk_opts',dcpl_id);
