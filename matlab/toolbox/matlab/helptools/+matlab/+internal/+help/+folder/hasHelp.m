function b = hasHelp(topic)
    folders = what(topic)';
    for folder = folders
        if ~matlab.lang.internal.introspective.isObjectDirectorySpecified(folder.path) && matlab.internal.help.folder.hasContents(folder, CheckEmptyContents=true)
            % A folder has help if it has any contents.
            b = true;
            return;
        end
    end
    b = false;
end

%   Copyright 2018-2024 The MathWorks, Inc.
