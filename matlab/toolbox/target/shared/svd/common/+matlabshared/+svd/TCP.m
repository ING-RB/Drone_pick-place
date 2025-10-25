classdef (StrictDefaults)TCP < matlab.System
        % TCP base class
    
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
        % ConnectionMode - Connection mode
        ConnectionMode = 'Server';
        % RemoteIPAddress - Server IP Address
        RemoteIPAddress = '192.168.1.2';
        % ServerIPPort - Server IP Port
        ServerIPPort = 25000;
        % LocalPort - Local Port
        LocalPort = 25000;
        % byte order
        ByteOrder = 'LittleEndian';
    end
    
    properties (Hidden,Transient,Constant)
        ConnectionModeSet = matlab.system.StringSet({'Server','Client'});
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
        MW_TCPHANDLE;
    end
    
    methods (Access=protected)
        
        function DataLength = validateDataLength(~, DataLength)
            validateattributes(DataLength,{'numeric'}, {'nonnegative','scalar','integer','finite','nonnan','nonempty'}, '', 'Data length');
            
        end
        
        
        function flag = isInactivePropertyImpl(obj, prop)
            switch (prop)
                case 'ConnectionMode'
                    flag = false;
                case 'RemoteIPAddress'
                    if isequal(obj.ConnectionMode,'Client')
                        flag = false;
                    else
                        flag = true;
                    end
                case 'ServerIPPort'
                    if isequal(obj.ConnectionMode,'Client')
                        flag = false;
                    else
                        flag = true;
                    end
                case 'LocalPort'
                    flag = false;
                    
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
        
        function TCPDataOut = getNumberOfBytes(obj,DataType)
            matlabshared.svd.TCP.allowedDataType(DataType);
            switch(DataType)
                case 'double'
                    TCPDataOut = double(zeros(obj.DataLength,1));
                case 'single'
                    TCPDataOut = single(zeros(obj.DataLength,1));
                case  'int8'
                    TCPDataOut = int8(zeros(obj.DataLength,1));
                case 'uint8'
                    TCPDataOut = uint8(zeros(obj.DataLength,1));
                case 'int16'
                    TCPDataOut = int16(zeros(obj.DataLength,1));
                case 'uint16'
                    TCPDataOut = uint16(zeros(obj.DataLength,1));
                case 'int32'
                    TCPDataOut = int32(zeros(obj.DataLength,1));
                case 'uint32'
                    TCPDataOut = uint32(zeros(obj.DataLength,1));
                case 'boolean'
                    TCPDataOut = false(obj.DataLength,1);
            end
        end
        
        
        function str = cstr(str)
            str = [str(:).', char(0)];
        end
    end
    
    methods
        function obj = TCP(varargin)
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
                {'real', 'positive', 'integer', 'scalar','finite','nonnan','nonempty',...
                '>=',1,'<=',65535}, '', 'Local Port');
            obj.LocalPort = val;
        end
        
        function set.ServerIPPort(obj, val)
            validateattributes(val,{'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar','finite','nonnan','nonempty',...
                '>=',1,'<=',65535}, '', 'Server IP Port');
            obj.ServerIPPort = val;
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
                if ( (~strcmp(ipStr, ipAddr)) || (strcmp(ipStr,'0.0.0.0')) )
                    error(message('svd:svd:InvalidIPAddress'));
                end
            end
            obj.RemoteIPAddress = val;
            
        end
        
        function open(obj)
            if coder.target('Rtw')
                coder.cinclude('MW_ETH.h');
                if obj.DirectionEnum == SVDTypes.MW_Input
                    obj.MW_TCPHANDLE = coder.opaque('MW_Handle_Type','NULL','HeaderFile','MW_SVD.h');
                    if isequal(obj.ConnectionMode,'Server')
                        obj.MW_TCPHANDLE = coder.ceval('MW_ETH_Open',uint8(1),uint8(0),int32(obj.LocalPort),uint8(0),cstr('255.255.255.255'));
                    else
                        obj.MW_TCPHANDLE = coder.ceval('MW_ETH_Open',uint8(1),uint8(1),int32(obj.LocalPort),uint32(obj.ServerIPPort),cstr(obj.RemoteIPAddress));
                    end
                else
                    obj.MW_TCPHANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                    if isequal(obj.ConnectionMode,'Server')
                        obj.MW_TCPHANDLE = coder.ceval('MW_ETH_Open',uint8(0),uint8(0),int32(obj.LocalPort),uint8(0),cstr('255.255.255.255'));
                    else
                        obj.MW_TCPHANDLE = coder.ceval('MW_ETH_Open',uint8(0),uint8(1),int32(obj.LocalPort),uint32(obj.ServerIPPort),cstr(obj.RemoteIPAddress));
                    end
                end
            else
                % Place simulation setup code here
                
                
            end
        end
        
        
        function close(obj)
            if ~(coder.target('MATLAB') || coder.target('Sfun'))
                % Init PWM
                coder.cinclude('MW_ETH.h');
                coder.ceval('MW_ETH_Close', obj.MW_TCPHANDLE);
            else
                % Place simulation setup code here
            end
        end
        
        function varargout= connect(obj)
            
            status = coder.nullcopy(uint8(0));
            if ~coder.target('MATLAB')
            status= coder.ceval('MW_ETH_connect',obj.MW_TCPHANDLE, ...
                uint32(obj.ServerIPPort));
            else
            end

            if nargout > 0
                varargout{1}=  status ;
            end
            
        end
        
        
        %         function accept(obj)
        %
        %             coder.ceval('MW_ETH_accept',obj.MW_TCPHANDLE);
        %
        %         end
        %
        %
        %         function varargout= bind(obj)
        %
        %          status = coder.nullcopy(uint8(0));
        %          status= coder.ceval('MW_ETH_bind',obj.MW_TCPHANDLE, ...
        %                         uint32(obj.LocalPort));
        %
        %          varargout{1}=  status ;
        %
        %         end
        %
        
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
            
            TCPDataOut = matlabshared.svd.TCP.getNumberOfBytes(obj,DataType);
            if coder.target('Rtw')% done only for code gen
                status = coder.ceval('MW_ETH_Receive',obj.MW_TCPHANDLE, ...
                    coder.wref(TCPDataOut), ...
                    uint32(DataLength * DataTypeLength), ...
                    uint32(obj.BlockingMode),double(timeout));
                
            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end
            
            if obj.ByteOrderEnum
                output = matlabshared.svd.ByteOrder.changeByteOrder(TCPDataOut, DataType);
            else
                % Reform the data to required data type
                output = matlabshared.svd.ByteOrder.concatenateBytes(TCPDataOut, DataType);
            end
            
            if nargout > 1
                varargout{1} = status;
            end
            
        end
        
        
        function varargout = send(obj,dataInp, dataType)
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
            
            dataSizeInBytes = matlabshared.svd.TCP.parseDataType(SwappedDataBytes);
            
            if coder.target('Rtw')% done only for code gen
                status = coder.ceval('MW_ETH_Send',obj.MW_TCPHANDLE, ...
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
            if isempty(coder.target)
                if (1 == getNumInputsImpl(obj))
                    validateattributes(varargin{1},{'numeric'},...
                        {'vector'},'','Data');
                end
            end
        end
        
        function validatePropertiesImpl(~)
        end
        
        
        
    end
    
    methods(Static, Access=protected)
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % Direction
            DirectionProp = matlab.system.display.internal.Property('Direction', 'Description', 'svd:svd:DirectionPrompt');
            RemoteIPAddressProp= matlab.system.display.internal.Property('RemoteIPAddress', 'Description', 'svd:svd:TCPRemoteIPAddressPrompt');
            ConnectionModeProp= matlab.system.display.internal.Property('ConnectionMode', 'Description', 'svd:svd:TCPConnectionModePrompt');
            ServerIPPortProp= matlab.system.display.internal.Property('ServerIPPort', 'Description', 'svd:svd:TCPServerIPPortPrompt');
            LocalPortProp= matlab.system.display.internal.Property('LocalPort', 'Description', 'svd:svd:TCPUDPLocalPortPrompt');
            ByteOrderProp=matlab.system.display.internal.Property('ByteOrder', 'Description', 'svd:svd:TCPUDPByteOrderPrompt');
            BlockingModeProp=matlab.system.display.internal.Property('BlockingMode', 'Description', 'svd:svd:TCPUDPBlockingModePrompt');
            BlockTimeoutProp=matlab.system.display.internal.Property('BlockTimeout', 'Description', 'svd:svd:TCPUDPBlockTimeoutPrompt');
            
            % Property list
            PropertyListOut = {DirectionProp,ConnectionModeProp,RemoteIPAddressProp,LocalPortProp,ServerIPPortProp, ByteOrderProp,BlockingModeProp,BlockTimeoutProp};
            
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

% LocalWords:  ISVALIDIP ETH TCPHANDLE nullcopy Sfun TCPUDP
