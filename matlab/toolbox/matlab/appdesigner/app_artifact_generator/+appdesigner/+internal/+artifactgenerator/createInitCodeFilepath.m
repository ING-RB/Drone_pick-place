function [mappFolder, cachePath, fcnName] = createInitCodeFilepath(filepath, cacheBucket)
    %CREATEINITCODEFILEPATH generates the filepath which will contain the M code initialization

%   Copyright 2024 The MathWorks, Inc.

    [~, filename, ~] = fileparts(filepath);

    [~, cachePath] = cacheBucket.addFolder('server');

    fcnName = append('AD_', filename, '_init');

    path = fullfile(cachePath, append(fcnName, '.m'));
end
