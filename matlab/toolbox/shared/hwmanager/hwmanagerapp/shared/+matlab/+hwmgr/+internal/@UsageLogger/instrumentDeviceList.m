function instrumentDeviceList(obj, allDevices)
% Method that will log each device as a seperate DDUX event with a unique
% UUID that will be used to associate/re-stitch the device list from server
% side.

% Copyright 2019 The MathWorks, Inc.

    if isempty(allDevices)
        % We currently do not log the empty device list
        return;
    end


    % Get the unique ID used to associate each device data into a list
    uuid = matlab.hwmgr.internal.UsageLogger().generateDeviceListUUID();

    newDeviceDataArray = [];
    for i = 1:numel(allDevices)

        currDevice = allDevices(i);
        % Get the device property-value pairs in struct format
        dataStruct = matlab.hwmgr.internal.UsageLogger.extractDeviceData(currDevice,...
                                                          uuid, ...   % enumerationId
                                                          "", ...     % appletName
                                                          "", ...     % appletConstructor
                                                          "", ...     % runResult
                                                          "");        % runErrMsg

        newDeviceDataArray = [newDeviceDataArray; dataStruct];
    end

    currentData = obj.DeviceData;

    % If this is the first time devices have been enumerated, then simply set
    % the data and return
    if isempty(currentData)
        obj.DeviceData = newDeviceDataArray;
        return;
    end

    % Otherwise, concatenate the previous and new data and uniqueify
    joinedData = [currentData; newDeviceDataArray];

    % Remove duplicates based on friendly name and provider
    friendlyNames = [joinedData.friendlyName]';
    providers = [joinedData.provider]';

    [~, indices] = unique(friendlyNames + providers);

    % Only keep unique values of the concatenated device data
    joinedData = joinedData(indices);

    obj.DeviceData = joinedData;

end
