classdef (Sealed) tcpclient < matlabshared.testmeas.internal.SetGet & ...
                              matlabshared.testmeas.CustomDisplay & ...
                              matlabshared.transportlib.internal.compatibility.LegacyTcpclient & ...
                              matlabshared.testmeas.internal.mixins.CacheEnabler & ...
                              matlabshared.transportlib.internal.TagAccessor
                              
%TCPCLIENT Create TCP/IP client object
%
%   OBJ = TCPCLIENT("ADDRESS",PORT) constructs a TCP/IP object, OBJ,
%   associated with remote host, ADDRESS, and remote port value, PORT.
%
%   If an invalid argument is specified or the connection to the server
%   cannot be established, then the object will not be created.
%
%   OBJ = TCPCLIENT("ADDRESS",PORT,"NAME","VALUE",...) constructs a
%   TCPCLIENT object using one or more name-value pair arguments. If an
%   invalid property name or property value is specified the object will
%   not be created. tcpclient properties that can be set using name-value
%   pairs are Timeout, Tag, ConnectTimeout, and EnableTransferDelay.
%
%   TCPCLIENT methods:
%
%   READ METHODS
%   read                - Read data from the remote host
%   readline            - Read ASCII-terminated string data from the remote host
%   readbinblock        - Read one binblock of data from the remote host
%
%   WRITE METHODS
%   write               - Write data to the remote host
%   writeline           - Write ASCII-terminated string data to the remote host
%   writebinblock       - Write one binblock of data to the remote host
%
%   OTHER METHODS
%   writeread           - Write ASCII-terminated string COMMAND to remote host
%                         and read back an ASCII-terminated string RESPONSE
%   flush               - Clear the input and/or output buffers
%   configureTerminator - Set the read and write terminator properties
%   configureCallback   - Set the Bytes Available callback properties
%
%   TCPCLIENT properties:
%
%   Address                - Remote host name or IP address
%   Port                   - Remote port for connection
%   Timeout                - Waiting time to complete read and write operations
%   ConnectTimeout         - Maximum time (in seconds) to wait for a connection request to the specified
%                            remote host to succeed or fail. If the connection does not succeed or fail
%                            within the specified time a timeout error will occur and the object will
%                            not be created. Value must be greater than or equal to 1.
%                            If not specified, default value of ConnectTimeout is inf.
%   EnableTransferDelay    - Indicates whether Nagle's algorithm is on or off for the connection.
%   Tag                    - Unique identifier name for the resource
%   NumBytesAvailable      - Number of bytes available to be read from input buffer
%   NumBytesWritten        - Number of bytes written to the output buffer
%   ByteOrder              - Sequential order in which bytes are arranged into larger numerical values
%   UserData               - Application specific data for tcpclient
%   Terminator             - Read and write terminator for the ASCII-terminated string communication
%   BytesAvailableFcn      - Function handle to be called when a Bytes Available event occurs
%   BytesAvailableFcnCount - Number of bytes in the input buffer that triggers a Bytes Available event
%                            (Only applicable for BytesAvailableFcnMode = "byte")
%   BytesAvailableFcnMode  - Condition for firing BytesAvailableFcn callback
%   ErrorOccurredFcn       - Function handle to be called when an error event occurs
%
%   Examples:
%
%       % Assume there is an echo server at port 4012
%
%       % Construct a tcpclient object
%       t = tcpclient('localhost',4012);
%
%       % Write 1 to 10 "double" data to the host
%       write(t,1:10);
%
%       % Read 10 numbers of "double" data from the host
%       data = read(t,10,"double");
%
%       % Set the Terminator property
%       configureTerminator(t,"CR/LF");
%
%       % Write "hello" to the remote host with the Terminator included
%       writeline(t,"hello");
%
%       % Read ASCII-terminated string from the remote host
%       data = readline(t);
%
%       % Write 1, 2, 3, 4, 5 as a binblock of "uint8" data to the remote host
%       % WRITEBINBLOCK REQUIRES INSTRUMENT CONTROL TOOLBOX™.
%       writebinblock(t,1:5,"uint8");
%
%       % Read binblock of "uint8" data from the remote host
%       % READBINBLOCK REQUIRES INSTRUMENT CONTROL TOOLBOX™.
%       data = readbinblock(t,"uint8");
%
%       % Query the remote host by writing an ASCII-terminated
%       % string "*IDN?" to it, and reading back an ASCII
%       % terminated response
%       % WRITEREAD REQUIRES INSTRUMENT CONTROL TOOLBOX™.
%       response = writeread(t,"*IDN?");
%
%       % Set the Bytes Available Callback properties
%       configureCallback(t,"byte",50,@myCallbackFcn);
%
%       % Flush input and output buffer
%       flush(t);
%
%       % Disconnect and clear remote host connection
%       clear t

%   Copyright 2014-2024 The MathWorks, Inc.

%#codegen
    methods(Static)
        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'networklibcoder.tcpclient';
        end
    end

    properties (Hidden, Constant)
        ObjectType = "tcpclient"
    end

    properties (GetAccess = public, SetAccess = private, Dependent)
        % Address - Specifies the remote host name or IP address.
        % Read/Write Access - Read-only
        % Accepted values - Valid IP address or host name specified as a
        %                   character vector or string scalar.
        % Default - N/A
        Address

        % Port - Specifies the remote host port for connection.
        % Read/Write Access - Read-only
        % Accepted Values - Positive integers between 1 and 65535.
        % Default - N/A
        Port

        % NumBytesAvailable - Specifies the number of bytes available to be
        %                     read.
        % Read/Write Access - Read-only
        % Default - 0
        NumBytesAvailable

        % NumBytesWritten - Specifies the number of bytes written to the
        %                   output buffer.
        % Read/Write Access - Read-only
        % Default - 0
        NumBytesWritten

        % ConnectTimeout - Specifies the maximum time (in seconds) to wait for a
        %                  connection request to the specified remote host to succeed
        %                  or fail. Value must be greater than or equal to 1. If not
        %                  specified, default value of ConnectionTimeout is inf.
        % Read/Write Access - Read-only
        % Accepted Values - Positive values equal to or greater than 1.
        % Default - Inf
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

    properties (Access = public, Dependent)
        % Timeout - Specifies the waiting time (in seconds) to complete
        %           read and write operations.
        % Read/Write Access - Both
        % Accepted Values - Positive numeric values
        % Default - 10
        Timeout

        % UserData - To store application specific data for tcpclient.
        % Read/Write Access - Both
        % Accepted Values - Any MATLAB data type
        % Default - []
        UserData

        % ByteOrder - Sequential order in which bytes are
        %             arranged into larger numerical values.
        % Read/Write Access - Both
        % Accepted Values - "little-endian" or "big-endian" specified as
        %                   char or string
        % Default - "little-endian"
        ByteOrder

        % Terminator - Read and write terminator for ASCII-terminated
        %              string communication.
        % Read/Write Access - Read-only
        % Default - "LF"
        %
        % To set this property, see <a href="matlab:help tcpclient.configureTerminator">configureTerminator</a> function.
        Terminator

        % BytesAvailableFcn - Function handle to be called when a Bytes
        %                     Available event occurs.
        % Read/Write Access - Read-only
        % Valid Values - any function_handle
        % Default - []
        %
        % To set this property, see <a href="matlab:help tcpclient.configureCallback">configureCallback</a> function.
        BytesAvailableFcn

        % BytesAvailableFcnCount - Number of bytes in the input buffer that triggers a
        %                          Bytes Available event.(Only applicable for
        %                          BytesAvailableFcnMode = "byte")
        % Read/Write Access - Read-only
        % Accepted Values - Positive integer values
        % Default - 64
        %
        % To set this property, see <a href="matlab:help tcpclient.configureCallback">configureCallback</a> function.
        BytesAvailableFcnCount

        % BytesAvailableFcnMode - Condition for firing BytesAvailableFcn callback.
        % Read/Write Access - Read-only
        % Default - "off"
        %
        % To set this property, see <a href="matlab:help tcpclient.configureCallback">configureCallback</a> function.
        BytesAvailableFcnMode

        % ErrorOccurredFcn - Function handle to be called when an error
        %                    event occurs.
        % Read/Write Access - Both
        % Valid Values - function_handle
        % Default - []
        ErrorOccurredFcn
    end

    % DO NOT remove this section (see g2510034) for details
    %     properties (GetAccess = public, SetAccess = private, Dependent, Hidden)
    %         % BytesAvailable - Specifies the number of bytes available to be
    %         %                  read.
    %         % Read/Write Access - Read-only
    %         % Default - 0
    %         BytesAvailable
    %     end

    properties (Hidden, Access = private)
        % TCPCustomClient - Read and write functionality handler.
        % read allows 3 different syntaxes and write allows 2 different
        % syntaxes which are not compliant with the shared interface read
        % and write.
        TCPCustomClient
    end

    properties (Hidden, Constant)
        AllSupportedPrecision = ["uint8","int8","uint16","int16","uint32","int32","uint64","int64","single","double","char","string"]

        DefaultPropertyDisplay = ["Address", "Port", "Tag", "NumBytesAvailable"]

        CommunicationPropertiesList = ["ConnectTimeout", "Timeout", ...
            "ByteOrder", "Terminator"]

        BytesAvailablePropertiesList = ["BytesAvailableFcnMode", ...
            "BytesAvailableFcnCount", "BytesAvailableFcn", "NumBytesWritten"]

        AdditionalPropertiesList = ["EnableTransferDelay", "ErrorOccurredFcn", "UserData"]

        DefaultByteOrder = "little-endian"

        % List of property names whose names need to be changed before
        % calling "saveobj".
        ActualPropNames = ["Address", "Port"]

        % List of property names that are changed in "saveobj".
        ConvertedPropNames = ["RemoteHost", "RemotePort"];

        % Dictionary containing the changed property names as keys and
        % their associated converted property names as values. E.g.
        % "Address" property of tcpclient needs to be saved as "RemoteHost"
        % for backwards compatibility.
        ActualToConvertedDictionary = dictionary(tcpclient.ActualPropNames, tcpclient.ConvertedPropNames)
    end

    %% Getters/Setters 
    methods
        function value = get.Address(obj)
            value = getProperty(obj.TCPCustomClient, "RemoteHost");
        end

        function value = get.Port(obj)
            value = getProperty(obj.TCPCustomClient, "RemotePort");
        end

        function value = get.EnableTransferDelay(obj)
            value = getProperty(obj.TCPCustomClient, "TransferDelay");
        end

        function set.EnableTransferDelay(obj, value)
            setProperty(obj.TCPCustomClient, "TransferDelay", value);
        end

        % DO NOT remove this section (see g2510034) for details
%         function value = get.BytesAvailable(obj)
%             % Contains the same value as NumBytesAvailable which can be
%             % accessed directly.
%             value = obj.NumBytesAvailable;
%         end        

        function value = get.NumBytesAvailable(obj)
            value = getProperty(obj.TCPCustomClient, "NumBytesAvailable");
        end

        function value = get.NumBytesWritten(obj)
            value = getProperty(obj.TCPCustomClient, "NumBytesWritten");
        end

        function value = get.Timeout(obj)
            value = getProperty(obj.TCPCustomClient, "Timeout");
        end

        function set.Timeout(obj, value)
            try
                obj.TCPCustomClient.TranslateSetPropertyError = false;
                setProperty(obj.TCPCustomClient,"Timeout",value);
                obj.TCPCustomClient.TranslateSetPropertyError = true;
            catch ex
                obj.TCPCustomClient.TranslateSetPropertyError = true;
                if ex.identifier == "Stream:timeout:invalidTime"
                    ex = MException(ex.identifier,message('MATLAB:networklib:tcpclient:incorrectTimeout').getString);
                end
                throwAsCaller(ex);
            end
        end

        function value = get.ConnectTimeout(obj)
            value = getProperty(obj.TCPCustomClient, "ConnectTimeout");
        end

        function set.ConnectTimeout(obj, value)
            try
                setProperty(obj.TCPCustomClient,"ConnectTimeout",value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function value = get.Terminator(obj)
            value = getProperty(obj.TCPCustomClient,"Terminator");
        end

        function set.Terminator(obj, value)
            try
                setProperty(obj.TCPCustomClient, "Terminator",value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function value = get.ByteOrder(obj)
            value = string(getProperty(obj.TCPCustomClient, "ByteOrder"));
        end

        function set.ByteOrder(obj,value)
            try
                setProperty(obj.TCPCustomClient, "ByteOrder",value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function value = get.UserData(obj)
            value = getProperty(obj.TCPCustomClient, "UserData");
        end

        function set.UserData(obj,value)
            try
                setProperty(obj.TCPCustomClient, "UserData",value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function value = get.ErrorOccurredFcn(obj)
            value = getProperty(obj.TCPCustomClient, "ErrorOccurredFcn");
        end

        function set.ErrorOccurredFcn(obj,value)
            try
                setProperty(obj.TCPCustomClient, "ErrorOccurredFcn",value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function value = get.BytesAvailableFcn(obj)
            value = getProperty(obj.TCPCustomClient, "BytesAvailableFcn");
        end

        function set.BytesAvailableFcn(obj, value)
            try
                setProperty(obj.TCPCustomClient, "BytesAvailableFcn",value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function value = get.BytesAvailableFcnMode(obj)
            value = getProperty(obj.TCPCustomClient, "BytesAvailableFcnMode");
        end

        function set.BytesAvailableFcnMode(obj, value)
            try
                setProperty(obj.TCPCustomClient, "BytesAvailableFcnMode",value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function value = get.BytesAvailableFcnCount(obj)
            value = getProperty(obj.TCPCustomClient, "BytesAvailableFcnCount");
        end

        function set.BytesAvailableFcnCount(obj, value)
            try
                setProperty(obj.TCPCustomClient, "BytesAvailableFcnCount",value);
            catch ex
                throwAsCaller(ex);
            end
        end
    end

    %% Lifetime
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
            address = instrument.internal.stringConversionHelpers.str2char(address);
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            try
                validateattributes(address, {'char'}, {'nonempty'}, 'tcpclient', 'ADDRESS', 1);
                validateattributes(port, {'numeric'}, {'>=', 1, '<=', 65535, 'scalar'}, 'tcpclient', 'PORT', 2);

                % Create TCPCustomClient
                obj.TCPCustomClient = getCustomClient(obj, address, port);

                % Validate the N-V pairs
                if mod(numel(varargin), 2)
                    error(message('MATLAB:networklib:tcpclient:unmatchedPVPairs'));
                end

                % Set name-value pairs if provided.
                if ~isempty(varargin)

                    % Parse the n-v pairs
                    p = inputParser;
                    p.PartialMatching = true;

                    % Detailed parameter validation will be done by TCPClient when
                    % assigned below.
                    addParameter(p, 'Timeout',getProperty(obj.TCPCustomClient, "DefaultTimeout"),@isnumeric);
                    addParameter(p, 'ConnectTimeout',getProperty(obj.TCPCustomClient, "DefaultConnectTimeout"), @isnumeric);
                    addParameter(p, 'EnableTransferDelay',true,@(x)islogical(x)&&isscalar(x));
                    addParameter(p, 'ByteOrder',obj.DefaultByteOrder);
                    addParameter(p, 'Tag', "", @(x) isstring(x) || ischar(x));

                    parse(p, varargin{:});
                    output = p.Results;
                    
                    obj.Timeout = output.Timeout;
                    obj.ConnectTimeout = output.ConnectTimeout;
                    obj.EnableTransferDelay = output.EnableTransferDelay;
                    obj.ByteOrder = output.ByteOrder;
                    obj.Tag = output.Tag;
                end
                connect(obj.TCPCustomClient);
                setProperty(obj.TCPCustomClient, "AllowPartialReads", false);

                % Make the writes synchronous
                setProperty(obj.TCPCustomClient, "WriteAsync", false);
                setCustomDisplay(obj);
            catch creationException
                % Replace '\' with '\\' if the error message contains anys
                % path information.
                formattedMessage = strrep(creationException.message, '\', '\\');
                throwAsCaller(MException('MATLAB:networklib:tcpclient:cannotCreateObject', ...
                    formattedMessage));
            end
        end
    end

    %% MATLAB API
    methods (Access = public)
        function data = read(obj, varargin)
        %READ Reads data from the remote host.
        %
        %   DATA = READ(OBJ) reads values from the tcpclient object
        %   connected to the remote host, OBJ, and returns to DATA. The
        %   number of values read is given by the BytesAvailable property.
        %
        %   DATA = READ(OBJ,SIZE) reads the specified number of values,
        %   SIZE, from the tcpclient object connected to the remote host,
        %   OBJ, and returns to DATA.
        %
        %   DATA = READ(OBJ,SIZE,DATATYPE) reads the specified
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
        %   'DOUBLE','CHAR', or 'STRING'.
        %
        % Outputs:
        %   DATA is a 1xN matrix of numeric or ASCII data. If no data was
        %   returned this will be an empty array.
        %
        % Notes:
        %   READ will wait until the requested number of values are
        %   read from the remote host.
        %
        % Example:
        %      % Read data available in the input buffer as "uint8".
        %      data = read(t);
        %
        %      % Read 5 count of data "uint8".
        %      data = read(t,5);
        %
        %      % Read 5 count of data, or 20 bytes, as "uint32".
        %      % (5*4 = 20 bytes)
        %      data = read(t,5,"uint32");

            try
                data = read(obj.TCPCustomClient,varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function data = readline(obj,varargin)
        %READLINE Reads ASCII-terminated string data from the remote host.
        %
        %   DATA = READLINE(OBJ) reads until the first occurrence of the
        %   terminator and returns the DATA back as a STRING. This
        %   function waits until the terminator is reached or a
        %   timeout occurs.
        %
        % Output Arguments:
        %   DATA is a string of ASCII data. If no data was returned,
        %   this is an empty string.
        %
        % Note:
        %   READLINE waits until the terminator is read from the input
        %   buffer or a timeout occurs.
        %
        % Example:
        %      % Reads all data up to the first occurrence of the
        %      % terminator. Returns the data as a string with the
        %      % terminator removed.
        %      data = readline(t);

            try
                data = readline(obj.TCPCustomClient,varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function write(obj, varargin)
        %WRITE Writes data to the remote host.
        %
        %   WRITE(OBJ,DATA) sends the N dimensional matrix of data to
        %   the remote host.
        %
        %   WRITE(OBJ,DATA,PRECISION) sends the 1xN matrix of data to
        %   the remote host. The data is cast to the specified
        %   precision PRECISION regardless of the actual precision.
        %
        % Inputs:
        %   DATA is a 1xN matrix of numeric or ASCII data. ASCII data is
        %   applicable only when precision is specified.
        %
        %   PRECISION controls the number of bits written for each value
        %   and the interpretation of those bits as integer, floating-point,
        %   or character values.
        %   PRECISION must be one of 'CHAR', 'STRING', 'UINT8', 'INT8', 'UINT16',
        %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE', or
        %   'DOUBLE'.
        %
        % Notes:
        %   WRITE will wait until the requested number of values are
        %   written to the remote host.
        %
        % Example:
        %      % Writes 1, 2, 3, 4, 5 as "double". (5*8 = 40 bytes total)
        %      % to the remote host.
        %      write(t,1:5);
        %
        %      % Writes 1, 2, 3, 4, 5 as "uint8". (5*1 = 5 bytes total)
        %      % to the remote host.
        %      write(t,1:5,"uint8");

            try
                write(obj.TCPCustomClient,varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function writeline(obj,varargin)
        %WRITELINE Writes ASCII data followed by the terminator to the
        % remote host.
        %
        %   WRITELINE(OBJ,DATA) writes the ASCII data, DATA, followed 
        %   by the terminator, to the remote host.
        %
        % Input Arguments:
        %   DATA is the ASCII data that is written to the remote host. This
        %   DATA is always followed by the write terminator character(s).
        %
        % Notes:
        %   WRITELINE waits until the ASCII DATA and the terminator are
        %   written to the remote host.
        %
        % Example:
        %      % writes "*IDN?" and adds the terminator to the end of
        %      % the line before writing to the remote host.
        %      writeline(t,"*IDN?");

            try
                writeline(obj.TCPCustomClient,varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function configureTerminator(obj, varargin)
        %CONFIGURETERMINATOR Sets the Terminator property for
        % ASCII-terminated string communication on the remote host.
        %
        %   CONFIGURETERMINATOR(OBJ,TERMINATOR) - Sets the Terminator
        %   property to TERMINATOR for the tcpclient object. TERMINATOR
        %   applies to both Read and Write Terminators.
        %
        %   CONFIGURETERMINATOR(OBJ,READTERMINATOR,WRITETERMINATOR) -
        %   Sets the Terminator property of the tcpclient to a cell
        %   array of {READTERMINATOR,WRITETERMINATOR}. It sets the
        %   Read Terminator to READTERMINATOR and the Write Terminator to
        %   WRITETERMINATOR for the tcpclient object.
        %
        % Input Arguments:
        %   TERMINATOR: The terminating character for as ASCII-terminated
        %   communication. This sets both Read and Write
        %   Terminators to TERMINATOR.
        %   Accepted Values - Integers ranging from 0 to 255
        %                     "CR", "LF", "CR/LF"
        %
        %   READTERMINATOR: The read terminating character for as ASCII-terminated
        %   communication. This sets the Read Terminator to READTERMINATOR.
        %   Accepted Values - Integers ranging from 0 to 255
        %                     "CR", "LF", "CR/LF"
        %
        %   WRITETERMINATOR: The write terminating character for as ASCII-terminated
        %   communication. This sets the write Terminator to WRITETERMINATOR.
        %   Accepted Values - Integers ranging from 0 to 255
        %                     "CR", "LF", "CR/LF"
        %
        % Example:
        %      % Set both read and write terminators to "CR/LF"
        %      configureTerminator(t,"CR/LF")
        %
        %      % Set read terminator to "CR" and write terminator to
        %      % ASCII value of 10
        %      configureTerminator(t,"CR",10)

            try
                configureTerminator(obj.TCPCustomClient,varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function configureCallback(obj, varargin)
        %CONFIGURECALLBACK Sets the BytesAvailable properties:
        %   1. <a href="matlab:help tcpclient.BytesAvailableFcnMode">BytesAvailableFcnMode</a>
        %   2. <a href="matlab:help tcpclient.BytesAvailableFcnCount">BytesAvailableFcnCount</a>
        %   3. <a href="matlab:help tcpclient.BytesAvailableFcn">BytesAvailableFcn</a>
        %
        %   CONFIGURECALLBACK(OBJ,MODE) - For this syntax, the only
        %   possible value for MODE is "off". This turns the BytesAvailable
        %   callbacks off.
        %
        %   CONFIGURECALLBACK(OBJ,MODE,CALLBACKFCN) - For this syntax,
        %   the only possible value for MODE is "terminator". This sets the
        %   BytesAvailableFcnMode property to "terminator". CALLBACKFCN
        %   is the function handle that is assigned to BytesAvailableFcn.
        %   CALLBACKFCN is triggered whenever a terminator is available
        %   to be read.
        %
        %   CONFIGURECALLBACK(OBJ,MODE,COUNT,CALLBACKFCN) - For this
        %   syntax, the only possible value for MODE is "BYTE". This sets
        %   the BytesAvailableFcnMode property to "BYTE". CALLBACKFCN is
        %   the function handle that is assigned to BytesAvailableFcn.
        %   CALLBACKFCN is triggered whenever COUNT number of bytes are
        %   available to be read. BytesAvailableFcnCount is set to COUNT.
        %
        % Input Arguments:
        %   MODE: The BytesAvailableFcnMode. Possible values are "off",
        %   "terminator", and "byte".
        %
        %   COUNT: The BytesAvailableFcnCount. This can be set to any
        %   positive integer value. Valid only for MODE = "byte".
        %
        %   CALLBACKFCN: The BytesAvailableFcn. This can be set to a
        %   function_handle.
        %
        % Example:
        %      % Turn the callback off
        %      configureCallback(t,"off")
        %
        %      % Set the BytesAvailableFcnMode to "terminator". This
        %      % triggers the callback function "callbackFcn" when a
        %      % terminator is available to be read.
        %      configureCallback(t,"terminator",@callbackFcn)
        %
        %      % Set the BytesAvailableFcnMode to "byte". This
        %      % triggers the callback function "callbackFcn" when 50
        %      % bytes of data are available to be read.
        %      configureCallback(t,"byte",50,@callbackFcn)

            try
                configureCallback(obj.TCPCustomClient, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function flush(obj, varargin)
        %FLUSH Clears the input buffer, output buffer, or both, based
        % on the value of BUFFER.
        %
        %   FLUSH(OBJ) clears both the input and output buffers.
        %
        %   FLUSH(OBJ,BUFFER) clears the input buffer or output
        %   buffer, based on the value of BUFFER.
        %
        % Input Arguments:
        %   BUFFER is the type of buffer that needs to be flushed.
        %   Accepted Values - "input", "output".
        %
        % Example:
        %      % Flush the input buffer
        %      flush(t,"input");
        %
        %      % Flush the output buffer
        %      flush(t,"output");
        %
        %      % Flush both the input and output buffers
        %      flush(t);

            try
                flush(obj.TCPCustomClient, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end
    end

    %% Methods that require Instrument Control Toolbox
    methods (Access = public)
        function data = readbinblock(obj,varargin)
        %READBINBLOCK Reads one binblock of data from the remote host.
        %
        %   DATA = READBINBLOCK(OBJ) reads the binblock data as UINT8
        %   and represents them as a DOUBLE array in row format.
        %
        %   DATA = READBINBLOCK(OBJ,PRECISION) reads the binblock data as
        %   PRECISION type. For numeric PRECISION types DATA is
        %   represented as a DOUBLE array in row format.
        %   For char and string PRECISION types, DATA is
        %   represented as is.
        %
        % Input Arguments:
        %   PRECISION indicates the number of bits read for each value
        %   and the interpretation of those bits as a MATLAB data type.
        %   PRECISION must be one of 'UINT8', 'INT8', 'UINT16',
        %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE',
        %   'DOUBLE', 'CHAR', or 'STRING'.
        %
        %   Default PRECISION: 'UINT8'
        %
        % Output Arguments:
        %   DATA is a 1xN matrix of numeric or ASCII data. If no data
        %   was returned this is an empty array.
        %
        % Notes:
        %   READBINBLOCK waits until a binblock is read from the
        %   input buffer.
        %   READBINBLOCK REQUIRES INSTRUMENT CONTROL TOOLBOX™.
        %
        % Example:
        %      % Reads the raw bytes in the binblock as uint8, and
        %      % represents them as a double array in row format.
        %      data = readbinblock(t);
        %
        %      % Reads the raw bytes in the binblock as uint16, and
        %      % represents them as a double array in row format.
        %      data = readbinblock(t,"uint16")

            try
                data = readbinblock(obj.TCPCustomClient,varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function writebinblock(obj,varargin)
        %WRITEBINBLOCK Writes a binblock of data to the remote host.
        %
        %   WRITEBINBLOCK(OBJ,DATA,PRECISION) writes DATA to the remote
        %   host using the binblock protocol (IEEE 488.2 Definite Length Arbitrary
        %   Block Response Data). The data is cast to the specified precision
        %   PRECISION regardless of the actual precision.
        %
        %   WRITEBINBLOCK(OBJ,DATA,PRECISION,HEADER) writes DATA to the
        %   remote host using the binblock protocol (IEEE 488.2 Definite
        %   Length Arbitrary Block Response Data). The data is cast to the
        %   specified precision PRECISION regardless of the actual
        %   precision. The HEADER is prepended to the binblock before
        %   writing.
        %
        % Input Arguments:
        %   DATA is a 1xN matrix of numeric or ASCII data that is
        %   written as a binblock to the remote host.
        %
        %   PRECISION controls the number of bits written for each value
        %   and the interpretation of those bits as integer, floating-point,
        %   or character values.
        %   PRECISION must be one of 'CHAR', 'STRING', 'UINT8', 'INT8', 'UINT16',
        %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE', or
        %   'DOUBLE'.
        %
        %   HEADER is the optional custom header to prepend to the binblock
        %   before writing. HEADER must be an ASCII string.
        %
        % Notes:
        %   WRITEBINBLOCK waits until the binblock DATA is written
        %   to the remote host.
        %   WRITEBINBLOCK REQUIRES INSTRUMENT CONTROL TOOLBOX™.
        %
        % Example:
        %      % Converts 1, 2, 3, 4, 5 to a binblock and writes it to
        %      % the remote host as uint8.
        %      writebinblock(t,1:5,"uint8");
        %
        %      % Converts 1, 2, 3, 4, 5 to a binblock and writes it to the
        %      % remote host as uint8 with the custom header "MyHeader"
        %      % prepended to the binblock packet before writing.
        %      writebinblock(t,1:5,"uint8","MyHeader");

            try
                writebinblock(obj.TCPCustomClient,varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function response = writeread(obj,varargin)
        %WRITEREAD Writes ASCII-terminated string command to remote host and
        % reads back an ASCII-terminated string.
        % This function can be used to query the remote host.
        %
        %   RESPONSE = WRITEREAD(OBJ,COMMAND) writes the COMMAND
        %   followed by the write terminator to the remote host. It reads
        %   back the RESPONSE from the remote host, which is an
        %   ASCII-terminated string, and returns the RESPONSE after removing
        %   the read terminator.
        %
        % Input Arguments:
        %   COMMAND: The ASCII-terminated data that is written to the
        %   remote host.
        %
        % Output Arguments:
        %   RESPONSE: The ASCII-terminated data that is returned back
        %   from the remote host.
        %
        % Notes:
        %   WRITEREAD waits until the ASCII-terminated COMMAND is written
        %   and an ASCII-terminated RESPONSE is retuned from the remote host.
        %   WRITEREAD REQUIRES INSTRUMENT CONTROL TOOLBOX™.
        %
        % Example:
        %      % Query the remote host for a response by sending "IDN?"
        %      % command.
        %      response = writeread(t,"*IDN?");

            try
                response = writeread(obj.TCPCustomClient,varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end
    end

    %% Saveobj Hidden Method
    methods (Hidden)
        function sObj = saveobj(obj)
            % Save the existing class properties as a struct that can
            % be used to re-create the object when loaded.

            allProps = string(properties(obj))';
            excludedProps = ["NumBytesAvailable", "NumBytesWritten", "UserData"];

            for prop = allProps
                if ismember(prop, obj.ActualPropNames)
                    sObj.(obj.ActualToConvertedDictionary(prop)) = obj.(prop);
                elseif ~ismember(prop, excludedProps)
                    sObj.(prop) = obj.(prop);
                end
            end
        end
    end

    %% Static Hidden Methods
    methods (Static, Hidden)
        function instance = loadobj(tObj)
            % Load a new tcpclient instance based on property values saved
            % using saveobj.

            instance = [];

            % Create a new tcpclient object using the saved struct in
            % saveobj.
            if isstruct(tObj)

                % "ByteOrder" is a newly saved-property. For previous
                % versions of MATLAB, ByteOrder will not be part of the
                % saved object. For this case, load only using the legacy
                % properties.
                if ~isfield(tObj, "ByteOrder")
                    instance = legacyLoadTcpclient(tObj);
                    return
                end

                instance = tcpclient(tObj.RemoteHost, tObj.RemotePort, ...
                    ConnectTimeout = tObj.ConnectTimeout, ...
                    ByteOrder = tObj.ByteOrder, ...
                    EnableTransferDelay = tObj.EnableTransferDelay, ...
                    Timeout = tObj.Timeout, ...
                    Tag = tObj.Tag);

                instance.ErrorOccurredFcn = tObj.ErrorOccurredFcn;

                switch string(tObj.BytesAvailableFcnMode)
                    case "off"
                        configureCallback(instance, tObj.BytesAvailableFcnMode);
                    case "byte"
                        configureCallback(instance, tObj.BytesAvailableFcnMode, tObj.BytesAvailableFcnCount, tObj.BytesAvailableFcn);
                    case "terminator"
                        configureCallback(instance, tObj.BytesAvailableFcnMode, tObj.BytesAvailableFcn);
                end

                if iscell(tObj.Terminator)
                    configureTerminator(instance, tObj.Terminator{1}, tObj.Terminator{2});
                else
                    configureTerminator(instance, tObj.Terminator);
                end

            elseif isa(tObj, "tcpclient")
                % If load receives a tcpclient object instead of struct,
                % then return the object as it is
                instance = tObj;
            end

            function out = legacyLoadTcpclient(tObj)
                if isfield(tObj, "ConnectTimeout")
                    out = tcpclient(tObj.RemoteHost, tObj.RemotePort, ConnectTimeout = tObj.ConnectTimeout);
                else
                    out = tcpclient(tObj.RemoteHost, tObj.RemotePort);
                end
                out.Timeout = tObj.Timeout;
            end
        end
    end

    methods (Access = private)
        function tcpCustomClient = getCustomClient(obj, address, port)
            % TCPCustomClient creation
            clientProperties = matlabshared.transportlib.internal.client.PropertiesFactory.getInstance("transport");
            clientProperties.Transport = matlabshared.transportlib.internal.TransportFactory. ...
                getTransport("tcpip", address, port);
            clientProperties.InterfaceName = "tcpclient";
            clientProperties.InterfaceObjectName = "t";
            clientProperties.CallbackSource = obj;
            tcpCustomClient = matlab.internal.tcpclient.TCPCustomClient(clientProperties);
        end

        function obj = setCustomDisplay(obj)
            % The list of properties to display under each corresponding
            % group name. The first group will be showed by default.
            obj.PropertyGroupList = {obj.DefaultPropertyDisplay, obj.CommunicationPropertiesList, ...
                obj.BytesAvailablePropertiesList, obj.AdditionalPropertiesList};

            % The group names for the above PropertyGroupList.
            % PropertyGroupNames for a list can also be an empty string as
            % shown below.
            obj.PropertyGroupNames = ["", "", "", ""];

            % Show the "all methods" in the footer
            obj.ShowAllMethodsInFooter = true;
        end
        
    end
end
