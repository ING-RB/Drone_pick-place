classdef UserEnvironment < matlab.depfun.internal.Environment
%

%   Copyright 2016-2020 The MathWorks, Inc.
    
    properties
        FullToolboxRoot = fullfile(matlabroot,'toolbox')
        RelativeToolboxRoot = 'toolbox'
        DependencyDatabasePath = ...
            fullfile(fileparts(mfilename('fullpath')), ...
            ['requirements_' initArch() '_dfdb']);
    end
    
end

% LocalWords:  dfdb
