classdef Descriptor < matlabshared.blelib.internal.Node & matlab.mixin.CustomDisplay
% Class that represents a descriptor on a Bluetooth Low Energy device.

% Copyright 2019 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = public)
        Name
        UUID
        Attributes
    end
    
    % Only expose to characteristic class to check for existing descriptors
    properties(Access = {?matlabshared.blelib.Characteristic})
        Index
    end
    
    properties(Access = private)
        ReadInterface
        WriteInterface
    end
    
    methods
        function obj = Descriptor(characteristic, dinfo, rinterface, winterface)
            characteristic.addChildren(obj);
            
            obj.Index = dinfo.Index;
            obj.Name = dinfo.Name;
            obj.UUID = dinfo.UUID;
            obj.Attributes = dinfo.Attributes;
            
            % Assign proper interfaces
            obj.ReadInterface = rinterface;
            obj.WriteInterface = winterface;
        end
        
        function value = read(obj)
            %READ Read descriptor value.
            %
            %   value = READ(c) reads descriptor value from the Bluetooth Low Energy
            %   peripheral device.
            %
            %   Examples:
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %       d = descriptor(c,"client characteristic configuration");
            %       value = read(d)
            %
            %   See also write
            try
                value = obj.ReadInterface.read(obj);
            catch e
                throwAsCaller(e);
            end
        end
        
        function write(obj, varargin)
            %WRITE Write descriptor value.
            %
            %   WRITE(c, data) writes descriptor with the given data.
            %
            %   WRITE(c, data, precision) writes descriptor with the given data of the
            %   specified precision.
            %
            %   Examples:
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %       d = descriptor(c,"client characteristic configuration");
            %       write(d,[1 0])
            %
            %       b = ble("HR Monitor");
            %       c = characteristic(b,"heart rate","heart rate measurement");
            %       d = descriptor(c,"client characteristic configuration");
            %       write(d,1,'uint16')
            %
            %   See also read
            try
                obj.WriteInterface.write(obj, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods(Access = {?matlabshared.blelib.read.descriptor.Interface, ?matlabshared.blelib.write.descriptor.Interface})
        function output = execute(obj, cmd, varargin)
            characteristic = obj.getParent;
            output = characteristic.execute(cmd, obj.Index, varargin{:});
        end
    end
    
    methods(Access=protected)
        function delete(~)
        end
        
        function displayScalarObject(obj)
            characteristic = obj.getParent;
            peripheral = characteristic.getParent;
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
            
            % Resort to default display
            displayScalarObject@matlab.mixin.CustomDisplay(obj);
            
            function cleanup(ws)
                warning(ws.state, 'MATLAB:ble:ble:deviceDisconnected');
            end
        end
    end
end