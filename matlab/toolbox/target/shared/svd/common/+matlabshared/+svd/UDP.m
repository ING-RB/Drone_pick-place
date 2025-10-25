classdef (StrictDefaults)UDP < matlab.System
    % UDP base class

    %#codegen
    %#ok<*EMCA>

    % Copyright 2018-2024 The MathWorks, Inc.

    properties (Hidden)
        Hw = [];
    end

    properties (Dependent, Access=protected)
        ByteOrderEnum
    end

    properties (Nontunable)
        % RemoteIPPort - Remote IP Port
        RemoteIPPort = 25002;
        % LocalIPPort - Local IP Port
        LocalPort = 25010;
        % RemoteIPAddress - Remote IP address (0.0.0.0 for accepting all)
        RemoteIPAddress = '0.0.0.0';
        % byte order
        ByteOrder = 'LittleEndian';
    end

    %

    properties (Constant, Hidden)
        ByteOrderSet = matlab.system.StringSet({'BigEndian','LittleEndian'});
    end

    properties (Nontunable)
        % BlockingMode - Wait until previous packet transmitted
        BlockingMode (1, 1) logical = false;


        % Timeout in seconds
        BlockTimeout = 0.1;
    end


    properties (Access = protected)
        MW_UDPHANDLE
    end

    methods (Access=protected)

        function DataLength = validateDataLength(~, DataLength)
            validateattributes(DataLength,{'numeric'}, {'nonnegative','scalar','integer','finite','nonnan','nonempty'}, '', 'Data length');
        end


        function flag = isInactivePropertyImpl(obj, prop)
            switch (prop)

                case 'RemoteIPAddress'
                    flag = false;

                case 'LocalPort'
                    flag = false;

                case 'RemoteIPPort'
                    if obj.DirectionEnum == SVDTypes.MW_Input
                        flag = true;
                    else
                        flag = false;
                    end

                case 'DataType'
                    if obj.DirectionEnum == SVDTypes.MW_Input
                        flag = false;
                    else
                        flag = true;
                    end
                case 'DataLength'
                    if obj.DirectionEnum == SVDTypes.MW_Input
                        flag = false;
                    else
                        flag = true;
                    end
                case 'SampleTime'
                    flag = false;
                case 'BlockingMode'
                    flag = false;
                case 'BlockTimeout'
                    flag = ~obj.BlockingMode;
                case 'Direction'
                    flag = true;
                case 'ByteOrder'
                    flag = true;
                case 'OutputStatus'
                    flag = false;
            end
        end


    end

    methods(Static)

        function allowedDataType(DataType)
            validatestring(DataType,{'int8','uint8','int16','uint16','int32','uint32','int64','uint64','single','double'}, '', 'Data type');
        end

        function dataSizeInBytes = parseDataType(dataInput)
            if isa(dataInput, 'embedded.fi')
                dataSizeInBytes = dataInput.WordLength/8;
            else
                switch (class(dataInput))
                    case 'double'
                        dataSizeInBytes =  8;
                    case {'single','int32','uint32'}
                        dataSizeInBytes =  4;
                    case {'int16','uint16'}
                        dataSizeInBytes =  2;
                    case {'int8','uint8','boolean','logical'}
                        dataSizeInBytes =  1;
                    otherwise
                        dataSizeInBytes = 0;
                end
            end
        end

        function UDPDataOut = getNumberOfBytes(obj,DataType)
            matlabshared.svd.UDP.allowedDataType(DataType);
            switch(DataType)
                case 'double'
                    UDPDataOut = double(zeros(obj.DataLength,1));
                case 'single'
                    UDPDataOut = single(zeros(obj.DataLength,1));
                case  'int8'
                    UDPDataOut = int8(zeros(obj.DataLength,1));
                case 'uint8'
                    UDPDataOut = uint8(zeros(obj.DataLength,1));
                case 'int16'
                    UDPDataOut = int16(zeros(obj.DataLength,1));
                case 'uint16'
                    UDPDataOut = uint16(zeros(obj.DataLength,1));
                case 'int32'
                    UDPDataOut = int32(zeros(obj.DataLength,1));
                case 'uint32'
                    UDPDataOut = uint32(zeros(obj.DataLength,1));
                case 'boolean'
                    UDPDataOut = false(obj.DataLength,1);
            end
        end


        function str = cstr(str)
            str = [str(:).', char(0)];
        end
    end

    methods
        function obj = UDP(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:}, 'Length');
        end


        function ret = get.ByteOrderEnum(obj)
            if isequal(obj.ByteOrder,'BigEndian')
                ret = true;
            else
                ret = false;
            end
        end

        function set.BlockTimeout(obj, val)
            attributes = {'nonempty','nonnan','real','nonnegative','nonzero','scalar'};
            paramName = 'Timeout in seconds';
            validateattributes(val,{'numeric'},attributes,'',paramName);
            obj.BlockTimeout = val;
        end

        function set.LocalPort(obj, val)
            validateattributes(val,{'numeric'}, ...
                {'real', 'integer', 'nonzero', 'scalar','finite','nonnan','nonempty',...
                '>=',-1,'<=',65535}, '', 'LocalPort');
            obj.LocalPort = val;
        end

        function set.RemoteIPPort(obj, val)
            validateattributes(val,{'numeric'}, ...
                {'real', 'positive', 'scalar','finite','nonnan','nonempty',...
                '>=',1,'<=',65535}, '', 'RemoteIPPort');
            obj.RemoteIPPort = val;
        end

        function set.RemoteIPAddress(obj, val)
            validateattributes(val, ...
                {'char', 'string'}, {'nonempty'}, '', 'RemoteIPAddress');
            if isstring(val)
                val = convertStringsToChars(val);
            end
            if isempty(coder.target)
                % ISVALIDIP    Check for validity of IP address
                val = strrep(strtrim(val), 'http://', '');
                if (length(val) > 15)
                    error(message('svd:svd:InvalidIPAddress'));
                end
                ipAddr = val;
                expr = '25[0-5]\.|2[0-4][0-9]\.|1[0-9][0-9]\.|[1-9][0-9]\.|[1-9]\.|0\.';
                [match] = regexp([ipAddr '.'], expr, 'match');
                if ( length(match) ~= 4 )
                    error(message('svd:svd:InvalidIPAddress'));
                end

                ipStr = [match{1} match{2} match{3} match{4}(1:end-1)];
                if ~strcmp(ipStr, ipAddr)
                    error(message('svd:svd:InvalidIPAddress'));
                end
            end
            obj.RemoteIPAddress = val;
        end

        function open(obj)
            if coder.target('Rtw')
                coder.cinclude('MW_ETH.h');
                if obj.DirectionEnum == SVDTypes.MW_Input
                    obj.MW_UDPHANDLE = coder.opaque('MW_Handle_Type','NULL','HeaderFile','MW_SVD.h');
                    obj.MW_UDPHANDLE = coder.ceval('MW_UDP_Open',int32(obj.LocalPort),cstr(obj.RemoteIPAddress),int32(0));
                else
                    obj.MW_UDPHANDLE = coder.opaque('MW_Handle_Type','NULL','HeaderFile','MW_SVD.h');
                    obj.MW_UDPHANDLE = coder.ceval('MW_UDP_Open',int32(obj.LocalPort),cstr(obj.RemoteIPAddress),uint32(obj.RemoteIPPort));
                end
            else
                % Place simulation setup code here
            end
        end


        function close(obj)
            if coder.target('Rtw')
                % Init PWM
                coder.cinclude('MW_ETH.h');
                coder.ceval('MW_UDP_Close', obj.MW_UDPHANDLE);
            else
                % Place simulation setup code here
            end
        end

        function varargout = connect(obj)
            status = coder.nullcopy(uint8(0));
            if coder.target('Rtw')
                status = coder.ceval('MW_UDP_connect',obj.MW_UDPHANDLE, ...
                    uint32(obj.RemoteIPPort));
            else
            end

            if nargout > 0
                varargout{1} =  status ;
            end
        end


        function [output, varargout]= receive(obj,DataType, DataLength, DataTypeLength)
            coder.inline('always');
            % Validate data length
            validateDataLength(obj, obj.DataLength);


            if obj.BlockingMode == true
                %pass -1 for infinite blocking
                if obj.BlockTimeout == inf
                    timeout = -1;
                else
                    timeout = obj.BlockTimeout;
                end
            else
                %Non blocking
                timeout = 0;
            end

            status = coder.nullcopy(uint8(0));

            UDPDataOut = matlabshared.svd.UDP.getNumberOfBytes(obj,DataType);
            if coder.target('Rtw')% done only for code gen
                status = coder.ceval('MW_UDP_Receive',obj.MW_UDPHANDLE, ...
                    coder.wref(UDPDataOut), ...
                    uint32(DataLength * DataTypeLength), ...
                    uint32(obj.BlockingMode),double(timeout));
            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end

            if obj.ByteOrderEnum
                output = matlabshared.svd.ByteOrder.changeByteOrder(UDPDataOut, DataType);
            else
                % Reform the data to required data type
                output = matlabshared.svd.ByteOrder.concatenateBytes(UDPDataOut, DataType);
            end

            if nargout > 1
                varargout{1} = status;
            end

        end


        function varargout = send(obj, dataInp, dataType)
            coder.inline('always');
            status = coder.nullcopy(uint8(0));
            if isequal(class(dataInp), dataType)
                CastedData = dataInp;
            else
                CastedData = cast(dataInp, dataType);
            end

            if obj.BlockingMode == true
                %pass -1 for infinite blocking
                if obj.BlockTimeout == inf
                    timeout = -1;
                else
                    timeout = obj.BlockTimeout;
                end
            else
                %Non blocking
                timeout = 0;
            end

            if obj.ByteOrderEnum
                SwappedDataBytes = matlabshared.svd.ByteOrder.getSwappedBytes(CastedData);
            else
                SwappedDataBytes = matlabshared.svd.ByteOrder.concatenateBytes(CastedData, 'uint8');
            end

            dataSizeInBytes = matlabshared.svd.UDP.parseDataType(SwappedDataBytes);

            if coder.target('Rtw')% done only for code gen
                status = coder.ceval('MW_UDP_Send',obj.MW_UDPHANDLE, ...
                    coder.rref(SwappedDataBytes), ...
                    uint32(numel(SwappedDataBytes) * dataSizeInBytes), ...
                    uint32(obj.BlockingMode),double(timeout));

            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end

            varargout{1}= status;
        end
    end


    methods (Access=protected)
        function varargout = stepImpl(~,varargin)
            varargout{1} = 0;
        end

        function validateInputsImpl(obj,varargin)
            % Run this always in Simulation
            if coder.target('Rtw')
                %
            else
                if (1 == getNumInputsImpl(obj))
                    validateattributes(varargin{1},{'numeric'},...
                        {'vector'},'','Data');
                end
            end
        end
    end

    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
            % Direction
            DirectionProp = matlab.system.display.internal.Property('Direction', 'Description', 'svd:svd:DirectionPrompt');
            RemoteIPAddressProp= matlab.system.display.internal.Property('RemoteIPAddress', 'Description', 'svd:svd:UDPRemoteIPAddressPrompt');

            RemoteIPPortProp= matlab.system.display.internal.Property('RemoteIPPort', 'Description', 'svd:svd:UDPRemoteIPPortPrompt');
            LocalPortProp= matlab.system.display.internal.Property('LocalPort', 'Description', 'svd:svd:TCPUDPLocalPortPrompt');
            ByteOrderProp=matlab.system.display.internal.Property('ByteOrder', 'Description', 'svd:svd:TCPUDPByteOrderPrompt');
            BlockingModeProp=matlab.system.display.internal.Property('BlockingMode', 'Description', 'svd:svd:TCPUDPBlockingModePrompt');
            BlockTimeoutProp=matlab.system.display.internal.Property('BlockTimeout', 'Description', 'svd:svd:TCPUDPBlockTimeoutPrompt');

            % Property list
            PropertyListOut = {DirectionProp,RemoteIPAddressProp,LocalPortProp,RemoteIPPortProp, ByteOrderProp,BlockingModeProp,BlockTimeoutProp};

            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);

            groups = Group;

            % Output property list if requested
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end

function str = cstr(str)
str = [str(:).', char(0)];
end

% LocalWords:  ISVALIDIP ETH Sfun TCPUDP
