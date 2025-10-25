classdef Characteristic < matlabshared.blelib.internal.Node & matlab.mixin.CustomDisplay
% Class that represents a characteristic on a Bluetooth Low Energy device.

% Copyright 2019-2024 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        Name
        UUID
        Attributes
        Descriptors
    end
    
    properties(Access = public, Dependent)
        DataAvailableFcn
    end
    
    % Only expose to ble class to check for existing characteristics
    properties(Access = {?ble, ?matlabshared.blelib.internal.TestAccessor})
        ServiceIndex
        CharacteristicIndex
    end
    
    properties(Access = private)
        ReadInterface
        WriteInterface
    end
    
    properties(Access = {?matlabshared.blelib.read.characteristic.NotifyOnly, ?matlabshared.blelib.write.descriptor.Write})
        % Flag indicating whether notification or indication is on
        % The flag is shared among NotifyOnly interface(subscribe/unsubscribe) 
        % and Write(descriptor write)
        SubscriptionOn = false
    end
    
    properties(Access = private)
        % Internal variable that counts how much data has been counted to 
        % trigger DataAvailableFcn callbacks
        TotalElementsProvidedInCallbacks = 0
        % Callback is triggered on every DataAvailableFcnCount data
        % received(not considering what's read or not read by user in the
        % buffer)
        DataAvailableFcnCount = 1
    end
    
    methods
        function obj = Characteristic(peripheral, sinfo, cinfo, rinterface, winterface)
            peripheral.addChildren(obj);
            
            obj.ServiceIndex = sinfo.Index;
            obj.CharacteristicIndex = cinfo.Index;
            obj.Name = cinfo.Name;
            obj.UUID = cinfo.UUID;
            obj.Attributes = cinfo.Attributes;
            
            % Assign proper interfaces
            obj.ReadInterface = rinterface;
            obj.WriteInterface = winterface;
                
            try
                obj.Descriptors = table(strings(0,1),strings(0,1),cell(0,1));
                obj.Descriptors.Properties.VariableNames = ["DescriptorName","DescriptorUUID","Attributes"];
                descriptors = execute(obj, matlabshared.blelib.internal.ExecuteCommands.DISCOVER_DESCRIPTORS);
                for descriptor = descriptors
                    dinfo = matlabshared.blelib.internal.ServicesCharacteristicsDescriptorsInfo.getInstance.getDescriptorInfoByUUID(descriptor.UUID);
                    attributes = descriptor.Attributes;
                    obj.Descriptors = [obj.Descriptors; {dinfo.Name, dinfo.UUID, {attributes}}];
                end
            catch e
                % Remove the child from parent if failure occurs in construction
                obj.disconnect;
                if ismember(e.identifier, ["MATLAB:ble:ble:failToExecuteDeviceDisconnected", ...
                                           "MATLAB:ble:ble:deviceProfileChanged"])
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToDiscoverDescriptors');
                end
            end
        end
        
        function [value, timestamp] = read(obj, varargin)
            %READ Read characteristic value.
            %
            %   [value, timestamp] = READ(c) reads the latest characteristic value from 
            %   the Bluetooth Low Energy peripheral device and also returns the 
            %   timestamp of when the data is received.
            %
            %   [value, timestamp] = READ(c, mode) reads the characteristic value with
            %   the specified mode from the Bluetooth Low Energy peripheral device and
            %   also returns the timestamp of when the data is received.
            %
            %   For characteristic that only supports Read, valid mode is "latest".
            %   For characteristic that supports Notify, Indicate or both, valid modes 
            %   are "latest" and "oldest". Use "oldest" mode when calling read in 
            %   DataAvailableFcn callback.
            %
            %   Examples:
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","body sensor location");
            %       [value,timestamp] = read(c);
            %       [value,timestamp] = read(c, "latest");
            %
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %       [value,timestamp] = read(c);
            %       [value,timestamp] = read(c, "oldest");
            %       [value,timestamp] = read(c, "latest");
            %
            %   See also write, subscribe, unsubscribe, descriptor
            try
                [value, timestamp] = obj.ReadInterface.read(obj, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function write(obj, varargin)
            %WRITE Write characteristic value.
            %
            %   WRITE(c, data) writes characteristic with the given data.
            %
            %   WRITE(c, data, type) writes characteristic with the given data and the
            %   specified type of either "withresponse" or "withoutresponse".
            %
            %   WRITE(c, data, precision) writes characteristic with the given data of
            %   the specified precision.
            %
            %   WRITE(c, data, precision, type) writes characteristic with the given
            %   data of the specified precision and the specified type.
            %
            %   Examples:
            %       b = ble("TestDevice");
            %       c = characteristic(b,"FF50","32E0");
            %       write(c,10);
            %
            %       b = ble("TestDevice");
            %       c = characteristic(b,"FF50","32E0");
            %       write(c,300,'uint16')
            %
            %       b = ble("TestDevice");
            %       c = characteristic(b,"FF50","32E0");
            %       write(c,10,'withoutresponse')
            %
            %       b = ble("TestDevice");
            %       c = characteristic(b,"FF50","32E0");
            %       write(c,300,'uint16','withoutresponse)
            %
            %   See also read, subscribe, unsubscribe, descriptor
            try
                obj.WriteInterface.write(obj, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function subscribe(obj, varargin)
            %SUBSCRIBE Subscribe to notification or indication.
            %
            %   SUBSCRIBE(c) subscribes to the notification or indication of the
            %   characteristic. The type is derived from characteristic attributes and
            %   notification takes precedance.
            %
            %   SUBSCRIBE(c, type) subscribes to the specified subscription of the
            %   characteristic. Valid types are "notification" and "indication"
            %
            %   Examples:
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %       subscribe(c);
            %
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %       subscribe(c,"notification");
            %
            %   See also read, write, unsubscribe, descriptor
            try
                % Set usercalled to true to force setting
                obj.ReadInterface.subscribe(obj, true, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function unsubscribe(obj)
            %UNSUBSCRIBE Unsubscribe from notification and indication.
            %
            %   UNSUBSCRIBE(c) unsubscribes from both notification and indication of
            %   the characteristic
            %
            %   Examples:
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %       subscribe(c,'notification');
            %       unsubscribe(c);
            %
            %   See also read, write, unsubscribe, descriptor
            try
                obj.ReadInterface.unsubscribe(obj);
            catch e
                throwAsCaller(e);
            end
        end
        
        function d = descriptor(obj, input)
            %DESCRIPTOR Create an object that represents a descriptor under the
            %characteristic on the Bluetooth Low Energy peripheral device.
            %
            %   d = DESCRIPTOR(c,name) creates an object representing the descriptor
            %   that has the specified name on the characteristic.
            %
            %   d = DESCRIPTOR(c,uuid) creates an object representing the descriptor
            %   that has the specified UUID on the characteristic.
            %
            %   DESCRIPTOR methods:
            %
            %   <a href="matlab:help matlabshared.blelib.Descriptor.read">read</a>        - Reads the descriptor value from the peripheral.
            %   <a href="matlab:help matlabshared.blelib.Descriptor.write">write</a>       - Writes the descriptor value to the peripheral.
            %
            %   DESCRIPTOR properties:
            %
            %   Name             - Specifies the descriptor name
            %   UUID             - Specifies the descriptor UUID
            %   Attributes       - Specifies the descriptor properties
            %
            %   Examples:
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %       d = descriptor(c,"client characteristic configuration")
            %
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %   	d = descriptor(c,"2902")
            %
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %   	d = descriptor(c,0x2902)
            %
            %   See also <a href="matlab:help matlabshared.blelib.Descriptor.read">read</a>, <a href="matlab:help matlabshared.blelib.Descriptor.write">write</a>
            
            % Validate descriptor input
            try
                if isempty(obj.Descriptors)
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:noDescriptors');
                end
                narginchk(2, 2);
                dinfo = validateDescriptor(obj, input);
            catch e
                throwAsCaller(e);
            end
            
            % Check if descriptor already exists
            children = obj.getChildren;
            for child = children'
                if isa(child,'matlabshared.blelib.Descriptor') && (child.Index==dinfo.Index)
                    d = child;
                    return;
                end
            end
            
            % Create descriptor            
            try
                [rinterface,winterface] = matlabshared.blelib.internal.getDescriptorInterfaceFactory(dinfo.Attributes);
                d = matlabshared.blelib.Descriptor(obj, dinfo, rinterface, winterface);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    % Setter/getter for DataAvailableFcn
    methods
        function set.DataAvailableFcn(obj, fcn)
            try
                setDataAvailableFcn(obj.ReadInterface, obj, fcn);
            catch e
                throwAsCaller(e);
            end
        end
        
        function fcn = get.DataAvailableFcn(obj)
            try
                fcn = getDataAvailableFcn(obj.ReadInterface);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods(Access = private)
        function dinfo = validateDescriptor(obj,input)
            % Check if input is a valid descriptor name or UUID supported on
            % the characteristic and return index of the descriptor in
            % Descriptors table
            
            % Validate data type
            info = matlabshared.blelib.internal.ServicesCharacteristicsDescriptorsInfo.getInstance;
            uuid = info.getDescriptorUUID(input);
            uuid = info.getShortestUUID(uuid);
            
            try
                uuid = validatestring(uuid, obj.Descriptors.DescriptorUUID);
            catch e
                if strcmpi(e.identifier,'MATLAB:ambiguousStringChoice')
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedDescriptor');
                end
            end
            
            dinfo = info.getDescriptorInfoByUUID(uuid);
            dinfo.Index = find(obj.Descriptors.DescriptorUUID == uuid);
            dinfo.Attributes = obj.Descriptors.Attributes{dinfo.Index};
        end
    end
    
    methods(Access = {?matlabshared.blelib.Descriptor, ?matlabshared.blelib.read.characteristic.Interface, ?matlabshared.blelib.write.characteristic.Interface})
        function output = execute(obj, cmd, varargin)
            peripheral = obj.getParent;
            % Supress warning that might be thrown in get.Connected
            ws = warning('off', 'MATLAB:ble:ble:deviceDisconnected');
            c = onCleanup(@() cleanup(ws));
            if ~peripheral.Connected
                matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToExecuteDeviceDisconnected');
            end
            output = peripheral.execute(cmd, obj.ServiceIndex, obj.CharacteristicIndex, varargin{:});
                        
            function cleanup(ws)
                warning(ws.state, 'MATLAB:ble:ble:deviceDisconnected');
            end
        end
    end
    
    % Handle data at the characteristic level to allow first input of
    % DataAvailableFcn be the characteristic object instead of the read
    % interface object
    methods(Access = ?matlabshared.blelib.read.characteristic.NotifyOnly)
        function handleData(obj, bufferObj, ~)
            % Trigger user callback if DataAvailableFcn is specified and
            % subscription is enabled in however means
            % 1. Trigger it as many times as new data count is of the 
            % DataAvailableFcnCount which defaults to 1 now
            % 2. Checking SubscriptionOn to not fire callback if there 
            % are not-processed data in the asyncio buffer when unsubscribe
            % is called.
            % 3. SubscriptionOn is cached on the characteristic to avoid
            % querying the device in each callback. Since both
            % subscribe/unsubscribe on characteristic and write of
            % descriptor of client characteristic configuration can update
            % the value, the property is stored on the general
            % characteristic object to allow sharing.
            newDataReceived = bufferObj.TotalElementsWritten - obj.TotalElementsProvidedInCallbacks;
            % Account for data read from buffer outside callbacks or after
            % subscription stops(either by unsubscribing or writing to
            % client characteristic configuration descriptor)
            if bufferObj.NumElementsAvailable < newDataReceived
                newDataReceived = bufferObj.NumElementsAvailable;
                % Pretend those data read outside callback are provided in
                % the callback to them so that we don't fire callbacks for
                % data that has already been read
                numDataReadOutsideCallback = newDataReceived - bufferObj.NumElementsAvailable;
                obj.TotalElementsProvidedInCallbacks = obj.TotalElementsProvidedInCallbacks + numDataReadOutsideCallback;
            end
            % Check if callback is assigned before entering the while-loop
            % to avoid looping for nothing
            if ~isempty(obj.DataAvailableFcn)
                while newDataReceived >= obj.DataAvailableFcnCount
                    % Check callback(again) and subscription each time to 
                    % account for changes happened in between callbacks
                    if ~isempty(obj.DataAvailableFcn) && obj.SubscriptionOn
                        try
                            obj.DataAvailableFcn(obj, matlabshared.blelib.internal.DataAvailableEventData);
                        catch e
                            % Hide internal trace and only throw user
                            % callback error
                            stack = e.stack(1);
                            % Print standard error(2)
                            errorText = message("MATLAB:ble:ble:callbackError", stack.name, num2str(stack.line), MException(e.identifier, e.message).message).getString;
                            fprintf(2, errorText);
                        end
                        obj.TotalElementsProvidedInCallbacks = obj.TotalElementsProvidedInCallbacks + obj.DataAvailableFcnCount;
                    end
                    newDataReceived = newDataReceived - obj.DataAvailableFcnCount;
                    % Allow callback to process
                    pause(1e-3);
                end
            end
        end
    end
    
    methods(Access=protected)
        function delete(obj)
            try
                resetSubscription(obj.ReadInterface, obj);
            catch
                % Suppress all errors in destructor
            end
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            peripheral = obj.getParent;
            % Only warn when warning is not suppressed
            currentWarnState = warning('query', 'MATLAB:ble:ble:deviceDisconnected');
            if strcmpi(currentWarnState.state, 'on')
                % Supress warning that might be thrown in get.Connected
                ws = warning('off', 'MATLAB:ble:ble:deviceDisconnected');
                c = onCleanup(@() cleanup(ws));
                if ~peripheral.Connected
                    warning('on', 'MATLAB:ble:ble:deviceDisconnected');
                    matlabshared.blelib.internal.localizedWarning('MATLAB:ble:ble:deviceDisconnected');
                end
            end
            
            disp(getHeader(obj));
            fprintf('             Name: "%s"\n', obj.Name);
            fprintf('             UUID: "%s"\n', obj.UUID);
            if isempty(obj.Attributes)
                fprintf('       Attributes: []\n');
            else
                fprintf('       Attributes: "%s"\n', strjoin(obj.Attributes,'" "'));
            end
            if isempty(obj.Descriptors)
                fprintf('      Descriptors: []\n');
            else
                fprintf('      Descriptors: [%dx%d table]\n', height(obj.Descriptors), width(obj.Descriptors));
            end
            displayDataAvailableFcn(obj.ReadInterface);
            
            % Pass through the resulting variable name
            thisObj = inputname(1);
            footer = getFooter(obj, thisObj);
            if strcmpi(get(0,'FormatSpacing'), 'compact')
                disp(strtrim(sprintf("%s",footer)));
            else
                disp(footer);
            end
            
            function cleanup(ws)
                warning(ws.state, 'MATLAB:ble:ble:deviceDisconnected');
            end
        end
        
        function out = getFooter(obj, thisObj)
            out = [];
            if ~isempty(obj.Descriptors)
                out = [newline sprintf('Show <a href="matlab:if exist(''%s'',''var'')&&isa(%s,''matlabshared.blelib.Characteristic''),nobodyknows = eval(''%s'');disp(''>>'');disp(nobodyknows.Descriptors);clear nobodyknows; else, disp(''Object ''''%s'''' does not exist or is no longer valid characteristic type.''), end">descriptors</a>\n', thisObj, thisObj, thisObj, thisObj)];
            end
        end
    end
end