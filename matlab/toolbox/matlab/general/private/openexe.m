function openexe(file)
    %OPENEXE Opens a Microsoft DOS or Windows executable.

    if ispc
        winopen(file);
    else
        throwExtensionError('MATLAB:openPlatform:winonly', file);
    end
end

% Copyright 2004-2024 The MathWorks, Inc.
