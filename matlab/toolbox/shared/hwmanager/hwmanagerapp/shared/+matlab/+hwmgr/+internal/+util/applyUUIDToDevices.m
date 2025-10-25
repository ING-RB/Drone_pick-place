function updatedDevices = applyUUIDToDevices(devices)
% This function will take an array of hardware manager devices objects and
% assign a UUID to them.

% Copyright 2022 The MathWorks, Inc.

% If the device list is empty, do nothing and return
if isempty(devices)
    updatedDevices = [];
    return;
end

for i = 1:numel(devices)   
    % If the the UUID is empty, assign one
    if devices(i).UUID == ""
        devices(i).UUID = devices(i).generateDefaultUUID();
    end
end

% Next check if there are collisions. If there are, assign a unique postfix
% to the generated UUID to make sure all device UUIDs are unique 

% Get all the UUIDs
allUUIDs = [devices.UUID];

% Get the indices of the unique UUIDs
[~, uniqueIndices] = unique(allUUIDs);

% Find the indices of the devices that don't have unique UUIDs
duplicateIndices = setdiff(1:numel(allUUIDs), uniqueIndices);

% Apply the collision avoidance to the duplicate device UUIDs

for k = 1:numel(duplicateIndices)
    duplicateDeviceIndex = duplicateIndices(k);
    devices(duplicateDeviceIndex).UUID = devices(duplicateDeviceIndex).UUID + ":::" +  matlab.lang.internal.uuid;
end
updatedDevices = devices;

end
