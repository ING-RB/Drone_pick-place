function varargout = unwrap_ids(varargin)
% Preprocess the inputs to the HDF5 library gateway builtin.
% Turn H5ML.ids into int64 when calling the library.

%   Copyright 2013-2024 The MathWorks, Inc.

for i=1:nargin      % nargin must be equal to nargout
    if isa(varargin{i}, 'H5ML.id')
        varargout{i} = varargin{i}.identifier;
    else
        varargout{i} = varargin{i};
    end
end
