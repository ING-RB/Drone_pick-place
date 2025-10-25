function openppt(filename)
    %OPENPPT Opens a Microsoft PowerPoint file.

    if ispc
        winopen(filename)
    elseif ismac
        matlab.system.internal.executeCommand(['open "' filename '" &']);
    else
        throwExtensionError('MATLAB:openPlatform:winmaconly', filename);
    end
end

% Copyright 1984-2024 The MathWorks, Inc.
