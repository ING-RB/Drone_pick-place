classdef AppOptions < handle
    %APPOPTIONS 

    % Copyright 2023-2024 The MathWorks, Inc.
    
    properties (Hidden)
        Filepath string
    end

    properties
        ClearCache logical = false;
        CacheExpireDate datetime = datetime('now') + days(30);
    end
end
