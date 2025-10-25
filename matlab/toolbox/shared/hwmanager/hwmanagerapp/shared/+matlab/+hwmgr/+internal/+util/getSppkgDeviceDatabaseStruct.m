function deviceList = getSppkgDeviceDatabaseStruct()
% getSppkgDeviceDatabaseStruct - Utility function to get the device
% detection database in a struct

% Copyright 2018-2019 The MathWorks, Inc.

persistent deviceDatabaseStruct

if isempty(deviceDatabaseStruct)
    sppkgJSONDir = fullfile(matlabroot, 'toolbox', 'shared', 'hwmanager', 'hwmanagerapp', 'devicedata');
    fileListings = dir(fullfile(sppkgJSONDir, '*.JSON'));
    fileNames = {fileListings.name};
    filePaths = cellfun(@(x) fullfile(sppkgJSONDir, x), fileNames, 'UniformOutput', false);
    
    deviceDatabaseStruct = matlab.hwmgr.internal.util.createDataStructArrayFromJSON(filePaths);
end
deviceList = deviceDatabaseStruct;
end