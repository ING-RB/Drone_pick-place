classdef Environment < handle
%

%   Copyright 2016-2020 The MathWorks, Inc.
    
    % Environment specific variables
    properties(Abstract)
        FullToolboxRoot
        RelativeToolboxRoot
        DependencyDatabasePath
    end
    
    properties(Constant)
        PcmPath = fullfile(fileparts(mfilename('fullpath')), ...
            ['pcm_' initArch() '_db']);
    end
    
end
