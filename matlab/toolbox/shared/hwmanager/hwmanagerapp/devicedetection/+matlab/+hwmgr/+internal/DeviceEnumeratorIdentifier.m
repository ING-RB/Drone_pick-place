classdef DeviceEnumeratorIdentifier < handle
    %DeviceEnumeratorIdentifier This is the class that identifies connected
    %devices
    %
    % DeviceEnumeratorIdentifier gets raw devices by calling mex function
    % getdevices. Each raw USB device has a EnumID which indicates the
    % enumerator that enumerates it. Each enumerator is mapped to one or
    % more device filters through "EnumFilterMap". Each filter corresponds
    % to a searchKey in the device database json file.
    %
    % A raw device is sent to filters that are mapped by its EnumID.
    % Inside the filter, the raw device is matched to a device in database
    % (if match exists) and used to create a supported device struct with
    % fields required for creating HardwareManagerDevice.
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties (SetAccess = private)
        %EnumFilterMap 
        %   Map from EnumID to filter class names
        EnumFilterMap

        %SupportedDeviceDatabase 
        %   A struct array of all supported devices
        %obtined from JSON files
        SupportedDeviceDatabase
    end
    
    methods
        function obj = DeviceEnumeratorIdentifier()
            obj.initializeEnumFilterMap();
            obj.SupportedDeviceDatabase = matlab.hwmgr.internal.util.getSppkgDeviceDatabaseStruct();
        end
    end

    methods
        function filteredDeviceStruct = getHwmgrSupportedDevicesData(obj, varargin)
            % Get filtered device struct array which contains data of
            % devices that are connected and supported by Hardware Manager.
            % varargin is used to take optional input for enum types in the
            % form of cell array of char array, e.g. {'genericEnum',
            % 'webcamEnum'}

            % connectedEnumDevices is a Nx1 cell array, where each cell
            % array contains a Nx1 struct array of a particular type of
            % enumerated device (e.g. webcam, generic usb device).
            connectedEnumDevices = obj.getRawDevices(varargin{:});
            filteredDeviceStruct = [];

            % for each cell of returned raw devices, get all filters
            for i = 1:length(connectedEnumDevices)
                devicesFromCurrEnum = connectedEnumDevices{i};
                if isempty(devicesFromCurrEnum)
                    % continue if the enumerator returns empty cell
                    continue;
                end
                filterClasses = obj.EnumFilterMap(devicesFromCurrEnum(1).EnumID);
                % go through each filter for this enumerator
                for j = 1:length(filterClasses)
                    deviceStruct = feval(strcat(filterClasses{j}, ".matchInDatabase"), obj.SupportedDeviceDatabase, devicesFromCurrEnum);
                    filteredDeviceStruct = [filteredDeviceStruct; deviceStruct];
                end
            end
        end

        function devices = getRawDevices(~, varargin)
            % This method can be mocked for testing, so real devices are not
            % required during testing.
            if strcmpi(computer, 'pcwin64')
                if isempty(varargin)
                    devices = matlab.hwmgr.internal.getdevices();
                else
                    devices = matlab.hwmgr.internal.getdevices(varargin{1});
                end
            else
                devices = cell.empty();
            end
        end
        
        function initializeEnumFilterMap(obj)
            % Construct an enumID to filters map
            obj.EnumFilterMap = containers.Map;
            % Get all filter classes in the package
            filterClasses = {meta.package.fromName('matlab.hwmgr.internal.filters').ClassList.Name};
            for i = 1:length(filterClasses)
                filterClass = filterClasses{i};
                enumID = eval(strcat(filterClass, ".EnumID"));
                if isKey(obj.EnumFilterMap, enumID)
                    currentValue = obj.EnumFilterMap(enumID);
                    obj.EnumFilterMap(enumID) = {currentValue, filterClass};
                else
                    obj.EnumFilterMap(enumID) = {filterClass};
                end
            end            
        end
    end

end
