classdef VIDPIDDeviceFilter < matlab.hwmgr.internal.BaseDeviceFilter
%VIDPIDDeviceFilter is a filter for USB devices with a searchKey of "vidpid"
    
%   Copyright 2018-2020 The MathWorks, Inc.
    
    properties (Constant)
        EnumID = "genericEnum"
        SearchKey = "vidpid"
    end
    
    methods (Static)
        function foundSupportedVIDPIDDevices = matchInDatabase(databaseStructArray, connectedVIDPIDDevices)
            % Deduplicate connectedVIDPIDDevices for vidpid filter, since devices with
            % multiple interfaces have multiple device instances ending up with multiple 
            % devices with same VID, PID (they may have different names/descriptions).            
            % Combine vid pid in one string.
            vidPidStr = cellfun(@(x, y) [x y], {connectedVIDPIDDevices.VendorID}', {connectedVIDPIDDevices.DeviceID}', 'UniformOutput', 0);
            [~, ind, ~] = unique(vidPidStr, 'stable');
            connectedVIDPIDDevices = connectedVIDPIDDevices(ind);            
            
            % convert connectedVIDPIDDevices to foundSupportedVIDPIDDevices with
            % all required struct fields for a vidpid device from databaseStructArray
            matlab.hwmgr.internal.BaseDeviceFilter.validateInputDevices(databaseStructArray, connectedVIDPIDDevices);
            
            % find all structs with the required searchKey vidpid
            searchKeyMatchingStruct = matlab.hwmgr.internal.BaseDeviceFilter.getDeviceDatabaseEntriesFromSearchKey(...
                databaseStructArray, matlab.hwmgr.internal.filters.VIDPIDDeviceFilter.SearchKey);
            
            foundSupportedVIDPIDDevices = [];
            for i = 1:length(connectedVIDPIDDevices)
                curDevice = connectedVIDPIDDevices(i);
                % filter connected devices that are in database
                vidMatchingStuct = searchKeyMatchingStruct(arrayfun(@(x) strcmpi(x.vid, curDevice.VendorID), searchKeyMatchingStruct));
                vidpidMatchingStuct = vidMatchingStuct(arrayfun(@(x) strcmpi(x.pid, curDevice.DeviceID), vidMatchingStuct));
                foundSupportedVIDPIDDevices = [foundSupportedVIDPIDDevices; vidpidMatchingStuct];
            end
        end
        
    end
    
end
