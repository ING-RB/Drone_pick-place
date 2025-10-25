function copied = copyFile(componentDir, folder, file, target, compressed, skipIfSourceIsMissing)
%

%   Copyright 2023 The MathWorks, Inc.

copied = true;

if isfile(target) || isfolder(target)
    return;
end

if matlab.internal.examples.isInstalled
    src = fullfile(componentDir,folder,file);
    if ~isfile(src) && ~isfolder(src)
        if ~skipIfSourceIsMissing
            copied = false;
        end
        return
    end
    matlab.internal.examples.copyIfMissing(src,target);
else
    [~,component,~] = fileparts(componentDir);
    copied = matlab.internal.examples.copyFromWeb(component, folder, file, target, compressed) || skipIfSourceIsMissing;
end
