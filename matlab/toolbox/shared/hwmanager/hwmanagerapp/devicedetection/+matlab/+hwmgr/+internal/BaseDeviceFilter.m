classdef BaseDeviceFilter < handle
%BaseDeviceFilter Base class for all client fitlers
%   This is the interface class for all filters for all devices with
%   different searchKey
    
%   Copyright 2018-2020 The MathWorks, Inc.
    properties (Abstract, Constant)
        %EnumID
        %   ID of the enumerator matched to this filter. It is required to
        %   construct the enumeartor to filters map by the
        %   DeviceEnumeratorIdentifier
        EnumID
        %SearchKey
        %   SearchKey is used to identify the type of devices filtered by
        %   this class in the database
        SearchKey
    end
    
        methods(Abstract, Static)
            deviceList = matchInDatabase(databaseStructArray, connectedEnumDevices)
        end
    
    methods(Static)
        function validateInputDevices(databaseStructArray, connectedEnumDevices)
            validateattributes(databaseStructArray, {'struct'}, {'column', 'nonempty'}, 'validateInputDevices', 'databaseStructArray', 1);
            validateattributes(connectedEnumDevices, {'struct'}, {'column', 'nonempty'}, 'validateInputDevices', 'connectedEnumDevices', 2);
        end
        
        function searchKeyMatchingStruct = getDeviceDatabaseEntriesFromSearchKey(databaseStructArray, searchKey)
            matchingInd = arrayfun(@(x) strcmpi(x.searchKey, searchKey), databaseStructArray);
            searchKeyMatchingStruct = databaseStructArray(matchingInd);
        end
    end
end
