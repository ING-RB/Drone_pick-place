function disabledAddonsWithFunction = findDisabledAddons(functionName)

% Returns list of currently disabled add-ons that have function with specified name

% Copyright 2018-2024 The MathWorks, Inc.

addonSpecification = matlab.internal.regfwk.ResourceSpecification;
addonSpecification.ResourceName = 'addons_core';
addonSpecification.ResourceType = matlab.internal.regfwk.ResourceType.XML;

disabledAddons = matlab.internal.regfwk.getResourceList(addonSpecification, 'disabled');

disabledAddonsWithFunction = struct('addonName', {}, 'addonUID', {});
disabledAddonsWithFunctionIdx = 1;

% If string manipulation results in poor performance, cache function names
% and the folder to which they belong
for i = 1:size(disabledAddons, 1)
    codeFiles = disabledAddons(i).resourcesFileContents.codeFiles;
    for j = 1:size(codeFiles, 1)
        [~, fileName, ~] = fileparts(codeFiles(j).fileName);
        if strcmp(fileName, functionName)
            addOnData = disabledAddons(i).resourcesFileContents.addOnsCore;
            disabledAddonsWithFunction(disabledAddonsWithFunctionIdx).addonName = [char(addOnData.name) [' ' getString(message('matlab_addons:enableDisableManagement:connectionForDisabledAddonRegistrationLinkText')) ' ']  char(addOnData.version)];
            disabledAddonsWithFunction(disabledAddonsWithFunctionIdx).addonUID = [char(addOnData.identifier) ',' char(addOnData.version)];
            disabledAddonsWithFunction(disabledAddonsWithFunctionIdx).name = addOnData.name;
            disabledAddonsWithFunction(disabledAddonsWithFunctionIdx).identifier = addOnData.identifier;
            disabledAddonsWithFunction(disabledAddonsWithFunctionIdx).version = addOnData.version;
            disabledAddonsWithFunctionIdx = disabledAddonsWithFunctionIdx + 1;
            break;
        end
    end
end
end
