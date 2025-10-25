classdef (StrictDefaults)SCI < matlab.System 
    % Interfaces to access SCI bus
    %
    % Type <a href="matlab:methods('matlabshared.svd.SCI')">methods('matlabshared.svd.SCI')</a> for a list of methods of the SCI object.
    %
    % Type <a href="matlab:properties('matlabshared.svd.SCI')">properties('matlabshared.svd.SCI')</a> for a list of properties of the SCI object.
    
    %#codegen
    %#ok<*EMCA>
    
    % Copyright 2016-2019 The MathWorks, Inc.
    
    properties (Hidden)
        Hw = [];
    end
    
    properties (Abstract,Nontunable)
        %SCIModule SCI Module
        SCIModule;
    end
    
    % Public, nontunable properties.
    properties (Nontunable)
        %Baudrate Baudrate (in bits/s)
        Baudrate = 9600;
        %Parity Parity
        Parity = 'None';
        %StopBits Number of stop bits
        StopBits = '1';
        %HardwareFlowControl Hardware flow control
        HardwareFlowControl = 'None';
        %ByteOrder Byte order
        ByteOrder = 'LittleEndian';
    end
    
    properties (Nontunable)
        %Direction Direction
        Direction = 'Both';
    end
    
    % SCI Drop-down list
    properties (Constant, Hidden)
        DirectionSet = matlab.system.StringSet({'Receive','Transmit','Both'});
        ByteOrderSet = matlab.system.StringSet({'LittleEndian','BigEndian'});
        ParitySet = matlab.system.StringSet({'None','Even','Odd'});
        DataBitsSet = matlab.system.StringSet({'5','6','7','8','9'});
        StopBitsSet = matlab.system.StringSet({'0.5','1','1.5','2'});
        HardwareFlowControlSet = matlab.system.StringSet({'None','RTS/CTS'});
    end
    
    properties (Nontunable, Hidden)
        %DataBits Number of data bits
        DataBits = '8';
    end
    
    % SCI Constants
    properties (Constant)
        % Stop bits available
        STOPBITS_0_5 = 0.5;
        STOPBITS_1 = 1;
        STOPBITS_1_5 = 1.5;
        STOPBITS_2 = 2;
        % Parity modes
        PARITY_NONE = uint8(0);
        PARITY_EVEN = uint8(1);
        PARITY_ODD = uint8(2);
        % Data bits
        DATABITS_5 = uint8(5);
        DATABITS_6 = uint8(6);
        DATABITS_7 = uint8(7);
        DATABITS_8 = uint8(8);
        DATABITS_9 = uint8(9);
        % Hardware flow control
        FLOWCONTROL_NONE = uint8(0);
        FLOWCONTROL_RTS_CTS = uint8(1);
    end
    
    properties (Dependent, Access=protected)
        ByteOrderEnum
        ParityEnum
        DataBitsLengthEnum
        StopBitsEnum
        HardwareFlowControlEnum
    end
    
    properties (Access = protected)
        MW_SCIHANDLE;
    end
    
    %% Constructor, Get/Set functions
    methods
        % Constructor
        function obj = SCI(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.Baudrate(obj, value)
            coder.extrinsic('error');
            coder.extrinsic('message');
            validateattributes(value,{'numeric'}, {'nonnegative','scalar','real','finite','nonnan','nonempty'}, '', 'Baudrate (in bits/s)');
            
            hwobj = obj.Hw; %#ok<MCSUP>
            if ~isempty(hwobj)
                if value > getSCIMaximumBaudrate(hwobj, obj.SCIModule) %#ok<MCSUP>
                    error(message('svd:svd:AllowedBusSpeed','SCI',getSCIMaximumBaudrate(hwobj, obj.SCIModule))); %#ok<MCSUP>
                end
            end
            
            obj.Baudrate = double(value);
        end
        function ret = get.Baudrate(obj)
            ret = uint32(obj.Baudrate);
        end
        
        % Set function for Parity
        function set.ParityEnum(obj, value)
            if isnumeric(value)
                validateattributes(value,{'numeric'},{'nonnegative','scalar','integer','finite','nonnan','nonempty','<=',matlabshared.svd.SCI.PARITY_ODD}, '', 'Parity');
                switch (value)
                    case 0
                        obj.Parity = 'None';
                    case 1
                        obj.Parity = 'Even';
                    case 2
                        obj.Parity = 'Odd';
                    otherwise
                        obj.Parity = 'None';
                end
            else
                obj.Parity = value;
            end
        end
        
        % Set function for StopBits
        function set.StopBitsEnum(obj, value)
            if isnumeric(value)
                validateattributes(value,{'numeric'},{'nonnegative','scalar','real','finite','nonnan','nonempty','>=',obj.STOPBITS_0_5,'<=',obj.STOPBITS_2}, '', 'Stop bits');
                switch (value)
                    case obj.STOPBITS_0_5
                        obj.StopBits = '0.5';
                    case obj.STOPBITS_1
                        obj.StopBits = '1';
                    case obj.STOPBITS_1_5
                        obj.StopBits = '1.5';
                    case obj.STOPBITS_2
                        obj.StopBits = '2';
                    otherwise
                        obj.StopBits = '1';
                end
            else
                obj.StopBits = value;
            end
        end
        
        % Set function for DataBitsLength
        function set.DataBitsLengthEnum(obj, value)
            if isnumeric(value)
                validateattributes(value,{'numeric'},{'nonnegative','scalar','integer','finite','nonnan','nonempty','>=',matlabshared.svd.SCI.DATABITS_5,'<=',matlabshared.svd.SCI.DATABITS_9}, '', 'Data bits');
                switch (value)
                    case 5
                        obj.DataBits = '5';
                    case 6
                        obj.DataBits = '6';
                    case 7
                        obj.DataBits = '7';
                    case 8
                        obj.DataBits = '8';
                    case 9
                        obj.DataBits = '9';
                    otherwise
                        obj.DataBits = '8';
                end
            else
                obj.DataBits = value;
            end
        end
        
        % false if little endian
        % true if big endian
        function ret = get.ByteOrderEnum(obj)
            hwobj = obj.Hw;
            if ~isempty(hwobj)
                ret = logical(getSCIByteOrder(hwobj, obj.SCIModule));
            else
                if isequal(obj.ByteOrder, 'LittleEndian')
                    ret = false;
                else
                    ret = true;
                end
            end

        end
        
        % Set function for HardwareFlowControl
        function set.HardwareFlowControlEnum(obj, value)
            if isnumeric(value)
                validateattributes(value,{'numeric'},{'nonnegative','scalar','integer','finite','nonnan','nonempty','<=',matlabshared.svd.SCI.FLOWCONTROL_RTS_CTS}, '', 'Hardware flow control');
                switch (value)
                    case 0
                        obj.HardwareFlowControl = 'None';
                    case 1
                        obj.HardwareFlowControl = 'RTS/CTS';
                    otherwise
                        obj.HardwareFlowControl = 'None';
                end
            else
                obj.HardwareFlowControl = value;
            end
        end
        
        % Get function for Parity
        function ret = get.ParityEnum(obj)
            switch (obj.Parity)
                case 'None'
                    ret = obj.PARITY_NONE;
                case 'Even'
                    ret = obj.PARITY_EVEN;
                case 'Odd'
                    ret = obj.PARITY_ODD;
                otherwise
                    ret = obj.PARITY_NONE;
            end
        end
        
        % Get function for StopBits
        function ret = get.StopBitsEnum(obj)
            switch (obj.StopBits)
                case '0.5'
                    ret = obj.STOPBITS_0_5;
                case '1'
                    ret = obj.STOPBITS_1;
                case '1.5'
                    ret = obj.STOPBITS_1_5;
                case '2'
                    ret = obj.STOPBITS_2;
                otherwise
                    ret = obj.STOPBITS_1;
            end
        end
        
        % Get function for DataBitsLength
        function ret = get.DataBitsLengthEnum(obj)
            switch (obj.DataBits)
                case '5'
                    ret = obj.DATABITS_5;
                case '6'
                    ret = obj.DATABITS_6;
                case '7'
                    ret = obj.DATABITS_7;
                case '8'
                    ret = obj.DATABITS_8;
                case '9'
                    ret = obj.DATABITS_9;
                otherwise
                    ret = obj.DATABITS_8;
            end
        end
        
        % Get function for HardwareFlowControl
        function ret = get.HardwareFlowControlEnum(obj)
            switch (obj.HardwareFlowControl)
                case 'None'
                    ret = matlabshared.svd.SCI.FLOWCONTROL_NONE;
                case 'RTS/CTS'
                    ret = matlabshared.svd.SCI.FLOWCONTROL_RTS_CTS;
                otherwise
                    ret = matlabshared.svd.SCI.FLOWCONTROL_NONE;
            end
        end
    end
    
    %% SCI formal functions
    methods
        % Initialize the SCI device
        function open(obj)
            % Rx/Tx pin
            
            % The idea is that you can't have property access directly inside a function call like:% 
            %   foo(a.prop,...);
            % when a.prop is a handle class and you want foo to constant fold.% 
            % The workaround is to access the property before the call:
            % 
            %   p = a.prop;
            %   foo(p,...);
            hwobj = obj.Hw;
            if isempty(hwobj)
                % Rx pin
                RxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                % Tx pin
                TxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                % Rx Pin
                if isequal(obj.Direction,'Receive') || isequal(obj.Direction,'Both')
                    RxPin = getSCIReceivePin(hwobj, obj.SCIModule);
                    if isempty(RxPin)
                        RxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(RxPin)
                            RxPinLoc = uint32(RxPin);
                        else
                            RxPinLoc = coder.opaque('uint32_T', RxPin);
                        end
                    end
                else
                    RxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                end
                % Tx Pin
                if isequal(obj.Direction,'Transmit') || isequal(obj.Direction,'Both')
                    TxPin = getSCITransmitPin(hwobj, obj.SCIModule);
                    if isempty(TxPin)
                        TxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(TxPin)
                            TxPinLoc = uint32(TxPin);
                        else
                            TxPinLoc = coder.opaque('uint32_T', TxPin);
                        end
                    end
                else
                    TxPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                end
            end
            
            % Initialise SCI data frame size and mode
            if ~coder.target('MATLAB')
                % Init SCI device
                coder.cinclude('MW_SCI.h');
                obj.MW_SCIHANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                
                % Intialise SCI
                if isnumeric(obj.SCIModule)
                    % SCIModule is a numeric value and is represented as
                    % obj.SCIModule = 1
                    isString = false;
                    SCIModuleLoc = coder.opaque('uint32_T');
                    SCIModuleLoc = coder.ceval('(uint32_T)',obj.SCIModule);
                    obj.MW_SCIHANDLE = coder.ceval('MW_SCI_Open', coder.rref(SCIModuleLoc), isString, RxPinLoc, TxPinLoc);
                else
                    % obj.SCIModule is represented as non numeric.
                    % This can be in 2 different ways within a system obj:
                    % obj.SCIModule = '1' or obj.SCIModuel = '/dev/serial1'
                    % Use getSCIModuleNameIsString() API to check how
                    % SCIModules are represented within the target.
                    if ~isempty(hwobj)
                        isString = logical(getSCIModuleNameIsString(hwobj));
                    else
                        isString = false;
                    end
                    
                    if ~isString
                        % SCIModule is a numeric value for the target but
                        % in system obj it is represented as a char :
                        % obj.SCIModule = '1'
                        SCIModuleLoc = coder.opaque('uint32_T',obj.SCIModule);
                        obj.MW_SCIHANDLE = coder.ceval('MW_SCI_Open', coder.rref(SCIModuleLoc), isString, RxPinLoc, TxPinLoc);
                    else
                        % SCIModule is not a numeric value :
                        % obj.SCIModule = '/dev/serial1'
                        % In C++ codegen, SCIModule will be const char[]
                        % and cannot be casted to void* directly
                        SCIModuleLoc = [obj.SCIModule char(0)];
                        SCIModuleVoidPtr = coder.opaque('void*');
                        SCIModuleVoidPtr = coder.ceval('(void*)',SCIModuleLoc);
                        obj.MW_SCIHANDLE = coder.ceval('MW_SCI_Open', SCIModuleVoidPtr, isString, RxPinLoc, TxPinLoc);
                    end
                end
            else
                % Place simulation setup code here
                obj.MW_SCIHANDLE = coder.nullcopy(uint32(0));
            end
            
            % Initialise Bus speed
            setBaudrate(obj);
            
            % Initialise frame format
            setFrameFormat(obj);
            
            % Configure Hardware flow control
            if ~isequal(obj.HardwareFlowControl, 'None')
                configureHardwareFlowControl(obj);
            end
        end
        
        % Set the SCI bus speed when SCI is master
        function varargout = setBaudrate(obj, Baudrate)
            % Initialize status to success
            status = uint8(0);
            hwobj = obj.Hw;
            % Set the input bus speed
            if nargin > 1
                BaudrateHw = uint32(Baudrate);
                % Set the bus speed from the hardware
            else
                if ~isempty(hwobj) && ~getSCIParametersVisibility(hwobj, obj.SCIModule)
                    % Set the default Bus speed
                    BaudrateHw = uint32(getSCIBaudrate(hwobj, obj.SCIModule));
                else
                    BaudrateHw = uint32(obj.Baudrate);
                end
            end
            obj.Baudrate = BaudrateHw;
            
            if ~coder.target('MATLAB')
                coder.cinclude('MW_SCI.h');
                % Init Bus speed
                status = coder.ceval('MW_SCI_SetBaudrate', obj.MW_SCIHANDLE, obj.Baudrate);
            else
                % Place simulation setup code here
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Set serial port format
        % setFrameFormat(obj)
        % setFrameFormat(obj, Parity)
        % setFrameFormat(obj, Parity, StopBits)
        % setFrameFormat(obj, Parity, StopBits, DataBits)
        function varargout = setFrameFormat(obj, varargin)
            narginchk(1,4);
            nargoutchk(0,1);
            
            status = coder.nullcopy(uint8(0));
            hwobj = obj.Hw;
            % Parity
            if nargin > 1
                ParityLoc = varargin{2};
            else
                if ~isempty(hwobj) && ~getSCIParametersVisibility(hwobj, obj.SCIModule)
                    ParityLoc = getSCIParity(hwobj, obj.SCIModule);
                else
                    ParityLoc = obj.ParityEnum;
                end
            end
            obj.ParityEnum = ParityLoc;
            
            % Stop bits
            if nargin > 2
                StopBitsLoc = varargin{3};
            else
                if ~isempty(hwobj) && ~getSCIParametersVisibility(hwobj, obj.SCIModule)
                    StopBitsLoc = getSCIStopBits(hwobj, obj.SCIModule);
                else
                    StopBitsLoc = obj.StopBitsEnum;
                end
            end
            obj.StopBitsEnum = StopBitsLoc;
            
            % DataBits
            if nargin > 3
                DataBitsLoc = varargin{1};
            else
                if ~isempty(hwobj) && ~getSCIParametersVisibility(hwobj, obj.SCIModule)
                    DataBitsLoc = getSCIDataBits(hwobj, obj.SCIModule);
                    if (uint32(DataBitsLoc) < 5) || (uint32(DataBitsLoc) > 9)
                        error('svd:svd:AllowedSCIDataBits','SCI allows data bits between 5 to 9.');
                    end
                else
                    DataBitsLoc = obj.DataBitsLengthEnum;
                end
            end
            obj.DataBitsLengthEnum = DataBitsLoc;
            
            % Initialise SCI data frame size and mode
            if ~coder.target('MATLAB')
                % Init SCI device
                coder.cinclude('MW_SCI.h');
                
                % StopBits value
                StopBitsValue = coder.const(@obj.getSCIStopBitsTypeValue, obj.StopBits);
                StopBitsValue = coder.opaque('MW_SCI_StopBits_Type', StopBitsValue);
                % Parity value
                ParityValue = coder.const(@obj.getSCIParityTypeValue, obj.Parity);
                ParityValue = coder.opaque('MW_SCI_Parity_Type', ParityValue);
                % Intialise SCI
                status = coder.ceval('MW_SCI_SetFrameFormat', obj.MW_SCIHANDLE, uint8(obj.DataBitsLengthEnum), ParityValue, StopBitsValue);
            else
                % Place simulation code here
            end
            
            if nargout > 0
                varargout{1} = status;
            end
        end
        
        % Transmit the data over SCI
        function varargout = write(obj, TxData, DataType)
            nargoutchk(0,1);
            
            % Initiate write only if direction set for transmit or
            % both
            if isequal(obj.Direction, 'Transmit') || isequal(obj.Direction,'Both')
                % Validate the DataType
                if isequal(obj.DataBits, '8')
                    matlabshared.svd.SCI.allowedDataType(DataType);
                else
                    if (isequal(obj.DataBits, '9') && ~isequal(DataType,'uint16'))
                        error('svd:svd:AllowedSCIDataTypes', 'Allowed data types can be only ''uint16'' as Data bits length chosen are 9 bits.');
                    elseif ~isequal(DataType,'uint8')
                        error('svd:svd:AllowedSCIDataTypes', 'Allowed data types can be only ''uint8'' as Data bits length chosen are between 5 to 7 bits.');
                    end
                end
                
                % Convert to required TxData type
                if isequal(class(TxData), 'int8') || isequal(class(TxData), 'uint8')
                    TxDataLoc = TxData;
                else
                    TxDataLoc = cast(TxData, DataType);
                end
                
                % Send in required byte format
                if obj.ByteOrderEnum
                    TxDataLocChar = matlabshared.svd.ByteOrder.getSwappedBytes(TxDataLoc);
                else
                    TxDataLocChar = matlabshared.svd.ByteOrder.concatenateBytes(TxDataLoc, 'uint8');
                end
                
                % Init status output
                status = coder.nullcopy(uint8(0));
                if ~coder.target('MATLAB')
                    coder.cinclude('MW_SCI.h');
                    status = coder.ceval('MW_SCI_Transmit',obj.MW_SCIHANDLE,...
                        coder.rref(TxDataLocChar),uint32(numel(TxDataLocChar)));
                else
                    % Place simulation code here
                end
            else
                % Init status output
                status = uint8(16);
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Receive the data over SCI
        function [RxData, varargout] = read(obj, DataLength, DataType)
            nargoutchk(1,2);
            
            % Validate the DataType
            if isequal(obj.DataBits, '8')
                matlabshared.svd.SCI.allowedDataType(DataType);
            else
                if (isequal(obj.DataBits, '9') && ~isequal(DataType,'uint16'))
                    error('svd:svd:AllowedSCIDataTypes', 'Allowed data types can be only ''uint16'' as Data bits length chosen are 9 bits.');
                elseif ~isequal(DataType,'uint8')
                    error('svd:svd:AllowedSCIDataTypes', 'Allowed data types can be only ''uint8'' as Data bits length chosen are between 5 to 7 bits.');
                end
            end
            
            % Initiate read only if direction set for receive or
            % both
            if isequal(obj.Direction, 'Receive') || isequal(obj.Direction,'Both')
                RxDataLocChar = coder.nullcopy(cast(zeros(matlabshared.svd.SCI.getNumberOfBytes(DataType)*DataLength, 1), 'uint8'));
                
                % Receive the data from SCI
                status = coder.nullcopy(uint8(0));
                if ~coder.target('MATLAB')
                    coder.cinclude('MW_SCI.h');
                    status = coder.ceval('MW_SCI_Receive', obj.MW_SCIHANDLE,...
                        coder.wref(RxDataLocChar), uint32(numel(RxDataLocChar)));
                else
                    % Place simulation code here
                end
                
                % Arrange according to Byteorder
                if obj.ByteOrderEnum
                    RxData = matlabshared.svd.ByteOrder.changeByteOrder(RxDataLocChar, DataType);
                else
                    % Reform the data to required data type
                    RxData = matlabshared.svd.ByteOrder.concatenateBytes(RxDataLocChar, DataType);
                end
            else
                RxData = cast(zeros(DataLength,1),DataType);
                status = uint8(16);
            end
            
            if nargout > 1
                varargout{1} = status;
            end
        end
        
        % Configure hardware flow control pins
        function varargout = configureHardwareFlowControl(obj, varargin)
            narginchk(1,2);
            nargoutchk(0,1);
            
            hwobj = obj.Hw;
            
            % HardwareFlowControl
            if nargin > 1
                HardwareFlowControlLoc = varargin{1};
            else
                if ~isempty(hwobj) && ~getSCIParametersVisibility(hwobj, obj.SCIModule)
                    HardwareFlowControlLoc = getSCIHardwareFlowControl(hwobj, obj.SCIModule);
                else
                    HardwareFlowControlLoc = obj.HardwareFlowControlEnum;
                end
            end
            obj.HardwareFlowControlEnum = HardwareFlowControlLoc;
            
            % Configure Hardware flow control
            status = coder.nullcopy(uint8(0));
            if ~coder.target('MATLAB')
                coder.cinclude('MW_SCI.h');
                
                % Hardware flow control pins
                if isempty(hwobj)
                    % Rx pin
                    RtsPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    % Tx pin
                    CtsPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                else
                    % Rx Pin
                    RtsDtrPin = getSCIRtsPin(hwobj, obj.SCIModule);
                    if isempty(RtsDtrPin)
                        RtsPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(RtsDtrPin)
                            RtsPinLoc = uint32(RtsDtrPin);
                        else
                            RtsPinLoc = coder.opaque('uint32_T', RtsDtrPin);
                        end
                    end
                    % Tx Pin
                    CtsDsrPin = getSCICtsPin(hwobj, obj.SCIModule);
                    if isempty(CtsDsrPin)
                        CtsPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
                    else
                        if isnumeric(CtsDsrPin)
                            CtsPinLoc = uint32(CtsDsrPin);
                        else
                            CtsPinLoc = coder.opaque('uint32_T', CtsDsrPin);
                        end
                    end
                end
                
                % HardwareFlowControlValue value
                HardwareFlowControlValue = coder.const(@obj.getSCIHardwareFlowControlTypeValue, obj.HardwareFlowControl);
                HardwareFlowControlValue = coder.opaque('MW_SCI_HardwareFlowControl_Type', HardwareFlowControlValue);
                
                status = coder.ceval('MW_SCI_ConfigureHardwareFlowControl', obj.MW_SCIHANDLE, HardwareFlowControlValue, RtsPinLoc, CtsPinLoc);
            else
                % Place simulation code here
            end
            
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        % Get the status of SCI
        function status = getStatus(obj)
            status = uint8(0);
            if ~coder.target('MATLAB')
                % Init PWM
                coder.cinclude('MW_SCI.h');
                status = coder.ceval('MW_SCI_GetStatus', obj.MW_SCIHANDLE);
            else
                % Place simulation setup code here
            end
        end
        
        % Release the SCI module
        function close(obj)
            if ~coder.target('MATLAB')
                % DeInit SCI
                coder.cinclude('MW_SCI.h');
                
                coder.ceval('MW_SCI_Close', obj.MW_SCIHANDLE);
            else
                % Place simulation setup code here
            end
        end
        
        % Send break signal
        function sendBreak(obj)
            if ~coder.target('MATLAB')
                % DeInit SCI
                coder.cinclude('MW_SCI.h');
                
                coder.ceval('MW_SCI_SendBreak', obj.MW_SCIHANDLE);
            else
                % Place simulation setup code here
            end
        end
    end
    
    methods (Static)
        function allowedDataType(DataType)
            validatestring(DataType,{'int8','uint8','int16','uint16','int32','uint32','single','double'}, '', 'precision');
        end
        
        function NumberOfBytes = getNumberOfBytes(DataType)
            matlabshared.svd.SCI.allowedDataType(DataType);
            switch (DataType)
                case {'int8','uint8'}
                    NumberOfBytes = 1;
                case {'int16','uint16'}
                    NumberOfBytes = 2;
                case {'int32','uint32','single'}
                    NumberOfBytes = 4;
                case {'int64','uint64','double'}
                    NumberOfBytes = 8;
                otherwise
                    error('Invalid datatype');
            end
        end
    end
    
    % System object methods
    methods (Access = protected)
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

        function flag = isInactivePropertyImpl(obj,prop)
            switch prop
                case {'Baudrate','Parity','DataBits','StopBits','HardwareFlowControl','ByteOrder'}
                    if isempty(obj.Hw)
                        flag = false;
                    else
                        flag = ~logical(getSCIParametersVisibility(obj.Hw, obj.SCIModule));
                    end
                otherwise
                    flag = false;
            end
        end
    end
    
    methods (Access = protected, Static)
        function StopBitsValue = getSCIStopBitsTypeValue(StopBitsStr)
            coder.inline('always');
            switch StopBitsStr
                case '0.5'
                    StopBitsValue = 'MW_SCI_STOPBITS_0_5';
                case '1'
                    StopBitsValue = 'MW_SCI_STOPBITS_1';
                case '1.5'
                    StopBitsValue = 'MW_SCI_STOPBITS_1_5';
                case '2'
                    StopBitsValue = 'MW_SCI_STOPBITS_2';
                otherwise
                    StopBitsValue = 'MW_SCI_STOPBITS_1';
            end
        end
        
        function ParityValue = getSCIParityTypeValue(ParityStr)
            coder.inline('always');
            switch ParityStr
                case 'None'
                    ParityValue = 'MW_SCI_PARITY_NONE';
                case 'Even'
                    ParityValue = 'MW_SCI_PARITY_EVEN';
                case 'Odd'
                    ParityValue = 'MW_SCI_PARITY_ODD';
                otherwise
                    ParityValue = 'MW_SCI_PARITY_NONE';
            end
        end
        
        function HardwareFlowControlValue = getSCIHardwareFlowControlTypeValue(HardwareFlowControlStr)
            coder.inline('always');
            switch HardwareFlowControlStr
                case {false,'None'}
                    HardwareFlowControlValue = 'MW_SCI_FLOWCONTROL_NONE';
                case {true,'RTS/CTS'}
                    HardwareFlowControlValue = 'MW_SCI_FLOWCONTROL_RTS_CTS';
                otherwise
                    HardwareFlowControlValue = 'MW_SCI_FLOWCONTROL_NONE';
            end
        end
    end
    
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
            %SCIModule SCI module
            SCIModuleProp = matlab.system.display.internal.Property('SCIModule', 'Description', 'svd:svd:SCIModulePrompt');
            %Baudrate Baudrate (in bits/s)
            BaudrateProp = matlab.system.display.internal.Property('Baudrate', 'Description', 'svd:svd:SCIBaudRatePrompt');
            %Parity Parity
            ParityProp = matlab.system.display.internal.Property('Parity', 'Description', 'svd:svd:SCIParityPrompt');
            %StopBits Stop bits
            StopBitsProp = matlab.system.display.internal.Property('StopBits', 'Description', 'svd:svd:SCIStopBitsPrompt');
            %HardwareFlowControl Hardware flow control
            HardwareFlowControlProp = matlab.system.display.internal.Property('HardwareFlowControl', 'Description', 'svd:svd:SCIHardwareFlowControlPrompt');
            %ByteOrder Byte order
            ByteOrderProp = matlab.system.display.internal.Property('ByteOrder', 'Description', 'svd:svd:SCIByteOrderPrompt');
            
            % Property list
            PropertyListOut = {SCIModuleProp, BaudrateProp, ParityProp, StopBitsProp, HardwareFlowControlProp, ByteOrderProp};

            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;

            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end