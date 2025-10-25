function fieldStruct = getRequiredJSONFields()
% This is an internal utility function that returns the registered fields
% and mandatory fields for all device data JSON files.

% Copyright 2018 The MathWorks, Inc.

mandatoryFields = {'searchKey', 'icon', 'supportPkg', 'hardwareSupportUrl'};
registeredFields = {'searchKey', 'icon', 'supportPkg', 'hardwareSupportUrl', ...
    'deviceName', 'vid', 'pid'};
fieldStruct = struct('RegisteredFields', {registeredFields}, 'MandatoryFields', {mandatoryFields});
end