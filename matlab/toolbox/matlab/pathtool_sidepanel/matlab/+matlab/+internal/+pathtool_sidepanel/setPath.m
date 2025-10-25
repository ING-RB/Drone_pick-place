function setPath(varargin)
    %

    % Copyright 2025 The MathWorks, Inc.
    matlab.internal.pathtool_sidepanel.executePathOperation('path(%s)', varargin{:});
end
