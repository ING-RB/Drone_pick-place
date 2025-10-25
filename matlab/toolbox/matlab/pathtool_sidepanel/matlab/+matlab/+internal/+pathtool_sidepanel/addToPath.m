function addToPath(varargin)
%

%   Copyright 2023-2025 The MathWorks, Inc.
    matlab.internal.pathtool_sidepanel.executePathOperation('addpath(%s)', varargin{:});
end
