function str = getStringFromCatalog(catalog, id, varargin)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023 The MathWorks, Inc.

str = getString(message("MATLAB:buildtool:" + catalog + ":" + id, varargin{:}));
end
