classdef (Sealed) tcpclient < handle
    %TCPCLIENT Create TCP/IP client object
    %
    %   OBJ = TCPCLIENT('ADDRESS', PORT) constructs a TCP/IP object, OBJ,
    %   associated with remote host, ADDRESS, and remote port value, PORT.
    %
    %   If an invalid argument is specified or the connection to the server
    %   cannot be established, then the object will not be created.
    %
    %   OBJ = TCPCLIENT('ADDRESS', PORT, 'P1',V1,'P2',V2,...) construct a
    %   TCPCLIENT object with the specified property values. If an invalid property
    %   name or property value is specified the object will not be created.
    %
    %   A property value pair of 'ConnectTimeout', TIMEOUT, will cause the
    %   object to wait for a maximum of TIMEOUT seconds for a response to the
    %   connection request sent to the remote host. If the connection
    %   does not succeed or fail within the specified time a timeout error will
    %   occur and the object will not be created. If 'ConnectTimeout' is not
    %   specified the object will wait for the connection to either succeed or
    %   fail before returning.
    %
    %    TCPCLIENT methods:
    %
    %    read - Reads data from the remote host.
    %    write - Writes data to the remote host.
    %
    %    TCPCLIENT properties:
    %
    %    Address - Specifies the remote host name or IP address.
    %    Port - Specifies the remote host port for connection.
    %    Timeout - Specifies the waiting time to complete read and write operations.
    %    BytesAvailable - Specifies the number of bytes available in the input buffer.
    %    ConnectTimeout - Specifies the maximum time (in seconds) to wait for
    %                     a connection request to the specified remote host to succeed
    %                     or fail. Value must be greater than or equal to 1. If
    %                     not specified, default value of ConnectionTimeout is
    %                     inf.
    %    EnableTransferDelay - Indicates whether Nagle's algorithm is on or off for the connection.
    %
    %   Example:
    %       % Assume there is an echo server at port 4012.
    %       % Construct a TCPClient object.
    %       t = tcpclient('localhost', 4012);
    %
    %       % Write double data to the host.
    %       write(t, 1:10);
    %
    %       % Read data from the host.
    %       data = read(t, 10, 'double');
    
    %   Copyright 2019-2023 The MathWorks, Inc.
    
    %#codegen
    properties (GetAccess = public, SetAccess = private, Dependent)
        % Address - Specifies the remote host name or IP address.
        Address
        
        % Port - Specifies the remote host port for connection.
        Port
    end
    
    properties (Access = public, Dependent)
        % Timeout - Specifies the waiting time (in seconds) to complete
        %   read and write operations.
        Timeout
    end
    
    properties (GetAccess = public, SetAccess = private, Dependent)
        % BytesAvailable - Specifies the number of bytes available in the
        %   input buffer.
        BytesAvailable
        
        % ConnectTimeout - Specifies the maximum time (in seconds) to
        %   wait for a connection request to the specified remote host to succeed
        %   or fail. Value must be greater than or equal to 1. If not
        %   specified, default value of ConnectionTimeout is inf.
        ConnectTimeout
    end

    properties (SetAccess = immutable, Dependent)
        % EnableTransferDelay - Indicates whether Nagle's algorithm is
        %                       on or off for the connection. If this
        %                       property is set to true, small segments of
        %                       outstanding data are collected and sent in
        %                       a single packet when acknowledgment (ACK)
        %                       arrives from the server. If false, data is
        %                       sent immediately to the network.
        % Read/Write Access - Read-only
        % Accepted Values - true, false
        % Default - true
        EnableTransferDelay
    end

    properties (Access = public)
        % ByteOrder - Sequential order in which bytes are
        % arranged into larger numerical values.
        ByteOrder

        % NumBytesAvailable - Specifies the number of bytes available to be
        % read.
        NumBytesAvailable

        % NumBytesWritten - Specifies the number of bytes written to the
        % output buffer.
        NumBytesWritten

        % UserData - To store application specific data for tcpclient.
        UserData

        % Terminator - Read and write terminator for ASCII-terminated
        % string communication.
        Terminator

        % BytesAvailableFcn - Function handle to be called when a Bytes
        % Available event occurs.
        BytesAvailableFcn

        % BytesAvailableFcnCount - Number of bytes in the input buffer that triggers a
        % Bytes Available event.(Only applicable for BytesAvailableFcnMode = "byte")
        BytesAvailableFcnCount

        % BytesAvailableFcnMode - Condition for firing BytesAvailableFcn callback.
        BytesAvailableFcnMode

        % ErrorOccurredFcn - Function handle to be called when an error
        % event occurs.
        ErrorOccurredFcn

        % Tag - Unique identifier for a tcpclient connection.
        Tag
    end
    
    properties (Hidden, Access = private)
        TCPClientObj
    end
    
    % Getters/Setters
    methods
        function value = get.Address(obj)
            value = obj.TCPClientObj.RemoteHost;
        end
        
        function value = get.Port(obj)
            value = obj.TCPClientObj.RemotePort;
        end

        function value = get.EnableTransferDelay(obj)            
            coder.extrinsic('networklibcoder.internal.getSelectedHardware');
            hardwareName = coder.const(networklibcoder.internal.getSelectedHardware);
            % Error out for Raspi codegen, the property is not available
            % for Raspi implementation
            coder.internal.assert(~isequal(hardwareName, 'Raspberry Pi'),...
                'MATLAB:networklib:tcpclient:PropertyNotSupportedByCoderTarget', 'EnableTransferDelay', 'Raspberry Pi');
            value = obj.TCPClientObj.TransferDelay;
        end

        function set.EnableTransferDelay(obj, value)            
            coder.extrinsic('networklibcoder.internal.getSelectedHardware');
            hardwareName = coder.const(networklibcoder.internal.getSelectedHardware);
            % Error out for Raspi codegen, the property is not available
            % for Raspi implementation
            coder.internal.assert(~isequal(hardwareName, 'Raspberry Pi'),...
                'MATLAB:networklib:tcpclient:PropertyNotSupportedByCoderTarget', 'EnableTransferDelay', 'Raspberry Pi');
            obj.TCPClientObj.TransferDelay = value;
        end
        
        function value = get.BytesAvailable(obj)
            value = obj.TCPClientObj.BytesAvailable;
        end
        
        function value = get.Timeout(obj)
            value = obj.TCPClientObj.Timeout;
        end
        
        function set.Timeout(obj, value)
            obj.TCPClientObj.Timeout = value;
        end
        
        function set.ConnectTimeout(obj, value)
            obj.TCPClientObj.ConnectTimeout = value;
        end
        
        function value = get.ConnectTimeout(obj)
            value = obj.TCPClientObj.ConnectTimeout;
        end

        function value = get.ByteOrder(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'ByteOrder');
        end

        function set.ByteOrder(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'ByteOrder');
        end

        function value = get.Tag(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'Tag');
        end

        function set.Tag(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'Tag');
        end
        
        function value = get.NumBytesAvailable(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'NumBytesAvailable');
        end

        function set.NumBytesAvailable(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'NumBytesAvailable');
        end

        function value = get.NumBytesWritten(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'NumBytesWritten');
        end

        function set.NumBytesWritten(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'NumBytesWritten');
        end

        function value = get.UserData(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'UserData');
        end

        function set.UserData(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'UserData');
        end

        function value = get.Terminator(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'Terminator');
        end

        function set.Terminator(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'Terminator');
        end

        function value = get.BytesAvailableFcn(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'BytesAvailableFcn');
        end

        function set.BytesAvailableFcn(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'BytesAvailableFcn');
        end
        
        function value = get.BytesAvailableFcnCount(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'BytesAvailableFcnCount');
        end

        function set.BytesAvailableFcnCount(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'BytesAvailableFcnCount');
        end

        function value = get.BytesAvailableFcnMode(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'BytesAvailableFcnMode');
        end

        function set.BytesAvailableFcnMode(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'BytesAvailableFcnMode');
        end

        function value = get.ErrorOccurredFcn(~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'ErrorOccurredFcn');
        end

        function set.ErrorOccurredFcn(~,~)
            coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'ErrorOccurredFcn');
        end
    end
    
    methods (Access = public)
        function obj = tcpclient(address, port, varargin)
            %TCPCLIENT Constructs TCP/IP client object.
            %
            %   OBJ = TCPCLIENT('ADDRESS',  PORT) constructs a
            %   TCPClient object, OBJ, associated with remote host, ADDRESS,
            %   and remote port value, PORT.
            %
            % Inputs:
            %   ADDRESS specifies the remote host name or IP dotted decimal
            %   address. An example of dotted decimal address is
            %   144.212.100.10.
            %
            %   PORT specifies the remote host port for connection. Port
            %   number should be between 1 and 65535.
            
            % convert to char in order to accept string datatype
            addressChar = char(address);
            
            %Create the TCPClientObj based on the hardware selected. If not
            %hardware is selected, default to the host tcpclient Object
            coder.extrinsic('networklibcoder.internal.getSelectedHardware');
            hardwareName = coder.const(networklibcoder.internal.getSelectedHardware);
            
            %Currently, tcpclient codegen is supported only for Raspberry
            %Pi. If hardware selected is not Raspberry Pi, default to host
            %implementation
            
            if isequal(hardwareName, 'Raspberry Pi')
                obj.TCPClientObj = raspi.internal.codegen.TCPReadWrite('RemoteHost',addressChar,'RemotePort', port);
            else
                obj.TCPClientObj = matlabshared.network.internal.TCPClient(addressChar, port);
            end
            
            % Validate the N-V pairs
            coder.internal.assert(mod(numel(varargin), 2)==0, 'MATLAB:networklib:tcpclient:unmatchedPVPairs');
            
            % Set name-value pairs if provided.
            if ~isempty(varargin)                
                params = struct( ...
                    'Timeout', uint32(0), ...
                    'ConnectTimeout', uint32(0), ...
                    'EnableTransferDelay', true, ...
                    'ByteOrder', 'little-endian', ...
                    'Tag', "");
                popt = struct( ...
                    'CaseSensitivity', false, ...
                    'StructExpand',    true, ...
                    'PartialMatching', 'unique');
                optarg = coder.internal.parseParameterInputs(params, popt, varargin{1:end});

                byteOrder = coder.internal.getParameterValue(optarg.ByteOrder, 'little-endian', varargin{1:end});
                if ~strcmp(byteOrder, 'little-endian')
                    coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'ByteOrder');
                end

                tag = coder.internal.getParameterValue(optarg.Tag, "", varargin{1:end});
                if ~strcmp(tag, "")
                    coder.internal.assert(false, 'network:tcpclient:PropertyNotSupportedByCodegen', 'Tag');
                end

                obj.Timeout = coder.internal.getParameterValue(optarg.Timeout, obj.TCPClientObj.DefaultTimeout, varargin{1:end});
                obj.TCPClientObj.ConnectTimeout = coder.internal.getParameterValue(optarg.ConnectTimeout, obj.TCPClientObj.DefaultConnectTimeout, varargin{1:end});
                if ~isequal(hardwareName, 'Raspberry Pi')
                    % Transfer delay option is only supported by host codegen
                    obj.EnableTransferDelay = coder.internal.getParameterValue(optarg.EnableTransferDelay, obj.TCPClientObj.DefaultTransferDelay, varargin{1:end});
                end
            end

            connect(obj.TCPClientObj);
        end
        
        function data = read(obj, varargin)
            %READ Reads data from the remote host.
            %
            %   DATA = READ(OBJ) reads values from the tcpclient object
            %   connected to the remote host, OBJ, and returns to DATA. The
            %   number of values read is given by the BytesAvailable property.
            %
            %   DATA = READ(OBJ, SIZE) reads the specified number of values,
            %   SIZE, from the tcpclient object connected to the remote host,
            %   OBJ, and returns to DATA.
            %
            %   DATA = READ(OBJ, SIZE, DATATYPE) reads the specified
            %   number of values, SIZE, with the specified precision,
            %   DATATYPE, from the tcpclient object connected to the
            %   remote host, OBJ, and returns to DATA.
            %
            % Inputs:
            %   SIZE indicates the number of items to read. SIZE cannot be
            %   set to INF. If SIZE is greater than the OBJ's
            %   BytesAvailable property, then this function will wait until
            %   the specified amount of data is read.
            %
            %   DATATYPE indicates the number of bits read for each value
            %   and the interpretation of those bits as a MATLAB data type.
            %   DATATYPE must be one of 'UINT8', 'INT8', 'UINT16',
            %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE',
            %   or 'DOUBLE'.
            %
            % Outputs:
            %   DATA is a 1xN matrix of numeric data. If no data was returned
            %   this will be an empty array.
            %
            % Notes:
            %   READ will wait until the requested number of values are
            %   read from the remote host.
            narginchk(1,3);
            
            switch nargin
                case 1
                    numValuesToRead = obj.BytesAvailable;
                    dataType = 'uint8';
                case 2
                    numValuesToRead = varargin{1};
                    dataType = 'uint8';
                case 3
                    numValuesToRead = varargin{1};
                    dataType = char(varargin{2});
            end
            
            data = receive(obj.TCPClientObj, numValuesToRead, dataType);
        end
        
        function write(obj, data)
            %WRITE Writes data to the remote host.
            %
            %   WRITE(OBJ, DATA) sends the N dimensional matrix of data to
            %   the remote host.
            %
            % Inputs:
            %   DATA an 1xN matrix of numeric data.
            %
            % Notes:
            %   WRITE will wait until the requested number of values are
            %   written to the remote host.
            
            validateattributes(data, {'numeric'}, {'nonempty'}, 'write', 'DATA', 2);
            
            send(obj.TCPClientObj, data);
        end

        function data = readline(~,~)
            coder.internal.assert(false, 'network:tcpclient:FunctionNotSupportedByCodegen', 'readline');
        end

        function data = readbinblock(~,~)
            coder.internal.assert(false, 'network:tcpclient:FunctionNotSupportedByCodegen', 'readbinblock');
        end
        
        function writeline(~,~)
            coder.internal.assert(false, 'network:tcpclient:FunctionNotSupportedByCodegen', 'writeline');
        end

        function writebinblock(~,~,~,~)
            coder.internal.assert(false, 'network:tcpclient:FunctionNotSupportedByCodegen', 'writebinblock');
        end

        function flush(~,~)
            coder.internal.assert(false, 'network:tcpclient:FunctionNotSupportedByCodegen', 'flush');
        end

        function configureCallback(~,~,~,~)
            coder.internal.assert(false, 'network:tcpclient:FunctionNotSupportedByCodegen', 'configureCallback');
        end

        function configureTerminator(~,~,~)
            coder.internal.assert(false, 'network:tcpclient:FunctionNotSupportedByCodegen', 'configureTerminator');
        end

        function response = writeread(~,~)
            coder.internal.assert(false, 'network:tcpclient:FunctionNotSupportedByCodegen', 'writeread');
        end
    end
    
    methods (Access = private)
        function delete(obj)
            % delete is the de-facto destructor in codegen mode
            % Release the TCP connection
            obj.TCPClientObj.disconnect();
        end
    end
end
