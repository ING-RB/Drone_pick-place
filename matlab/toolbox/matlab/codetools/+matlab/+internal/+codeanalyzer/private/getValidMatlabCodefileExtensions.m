function exts = getValidMatlabCodefileExtensions
%GETVALIDMATLABCODEFILEEXTENSIONS returns valid file extensions for MATLAB
%   files.

%   Copyright 2014-2024 The MathWorks, Inc.

    if feature("AppDesignerPlainTextFileFormat")
        exts = { '.mapp', '.mlapp', '.mlx', '.m' };
    else
        exts = { '.mlapp', '.mlx', '.m' };
    end
end
