classdef (Sealed) Serialport < matlabshared.testmeas.internal.SetGet & ...
        matlabshared.testmeas.CustomDisplay & ...
        matlabshared.transportlib.internal.compatibility.LegacySerial & ...
        matlabshared.testmeas.internal.mixins.CacheEnabler & ...
        matlabshared.transportlib.internal.TagAccessor

    %SERIALPORT Create serial client for communication with the serial port
    %
    %   OBJ = SERIALPORT(PORT,BAUDRATE) constructs a serialport object, OBJ,
    %   associated with port value, PORT and a baud rate of BAUDRATE, and
    %   automatically connects to the serial port.
    %
    %   s = SERIALPORT(PORT,BAUDRATE,"NAME","VALUE",...) constructs a
    %   serialport object using one or more name-value pair arguments. If
    %   an invalid property name or property value is specified the object
    %   will not be created. Serialport properties that can be set using
    %   name-value pairs are ByteOrder, DataBits, StopBits, Timeout, Tag,
    %   Parity, and FlowControl.
    %
    %   s = SERIALPORT constructs a serialport object using the property
    %   settings of the last cleared serialport object instance. The
    %   retained properties are Port, BaudRate, ByteOrder, FlowControl,
    %   StopBits, DataBits, Parity, Timeout, Tag, and Terminator.
    %
    %   SERIALPORT methods:
    %
    %   READ METHODS
    %   <a href="matlab:help internal.Serialport.read">read</a>                - Read data from the serialport device
    %   <a href="matlab:help internal.Serialport.readline">readline</a>            - Read ASCII-terminated string data from the serialport device
    %   <a href="matlab:help internal.Serialport.readbinblock">readbinblock</a>        - Read binblock data from the serialport device
    %
    %   WRITE METHODS
    %   <a href="matlab:help internal.Serialport.write">write</a>               - Write data to the serialport device
    %   <a href="matlab:help internal.Serialport.writeline">writeline</a>           - Write ASCII-terminated string data to the serialport device
    %   <a href="matlab:help internal.Serialport.writebinblock">writebinblock</a>       - Write binblock data to the serialport device
    %
    %   OTHER METHODS
    %   <a href="matlab:help internal.Serialport.writeread">writeread</a>           - Write ASCII-terminated string data to the serialport device
    %                         and read ASCII-terminated string data back as a response
    %   <a href="matlab:help internal.Serialport.configureCallback">configureCallback</a>   - Set the Bytes Available callback properties
    %   <a href="matlab:help internal.Serialport.configureTerminator">configureTerminator</a> - Set the serialport read and write terminator properties
    %   <a href="matlab:help internal.Serialport.flush">flush</a>               - Clear the input and/or output buffers of the serialport device
    %   <a href="matlab:help internal.Serialport.getpinstatus">getpinstatus</a>        - Get the serialport pin status
    %   <a href="matlab:help internal.Serialport.serialbreak">serialbreak</a>         - Sends a break signal to the serialport device
    %   <a href="matlab:help internal.Serialport.setDTR">setDTR</a>              - Set the serialport DTR (Data Terminal Ready) pin
    %   <a href="matlab:help internal.Serialport.setRTS">setRTS</a>              - Set the serialport RTS (Ready To Send) pin
    %   SERIALPORT properties:
    %
    %   <a href="matlab:help internal.Serialport.Port">Port</a>                    - Serial port for connection
    %   <a href="matlab:help internal.Serialport.BaudRate">BaudRate</a>                - Speed of communication (in bits per second)
    %   <a href="matlab:help internal.Serialport.Parity">Parity</a>                  - Parity to check whether data has been lost or written
    %   <a href="matlab:help internal.Serialport.DataBits">DataBits</a>                - Number of bits used to represent one character of data
    %   <a href="matlab:help internal.Serialport.StopBits">StopBits</a>                - Pattern of bits that indicates the end of a character or of the whole transmission
    %   <a href="matlab:help internal.Serialport.FlowControl">FlowControl</a>             - Mode of managing the rate of data transmission
    %   <a href="matlab:help internal.Serialport.ByteOrder">ByteOrder</a>               - Sequential order in which bytes are arranged into larger numerical values
    %   <a href="matlab:help internal.Serialport.Timeout">Timeout</a>                 - Waiting time to complete read and write operations
    %   <a href="matlab:help internal.Serialport.Tag">Tag</a>                     - Unique identifier name for the serialport connection
    %   <a href="matlab:help internal.Serialport.NumBytesAvailable">NumBytesAvailable</a>       - Number of bytes available to be read
    %   <a href="matlab:help internal.Serialport.NumBytesWritten">NumBytesWritten</a>         - Number of bytes written to the serial port
    %   <a href="matlab:help internal.Serialport.Terminator">Terminator</a>              - Read and write terminator for the ASCII-terminated string communication
    %   <a href="matlab:help internal.Serialport.BytesAvailableFcn">BytesAvailableFcn</a>       - Function handle to be called when a Bytes Available event occurs
    %   <a href="matlab:help internal.Serialport.BytesAvailableFcnCount">BytesAvailableFcnCount</a>  - Number of bytes in the input buffer that triggers a Bytes Available event
    %                             (Only applicable for BytesAvailableFcnMode = "byte")
    %   <a href="matlab:help internal.Serialport.BytesAvailableFcnMode">BytesAvailableFcnMode</a>   - Condition for firing BytesAvailableFcn callback
    %   <a href="matlab:help internal.Serialport.ErrorOccurredFcn">ErrorOccurredFcn</a>        - Function handle to be called when an error event occurs
    %   <a href="matlab:help internal.Serialport.UserData">UserData</a>                - Application specific data for the serialport
    %
    %   Examples:
    %
    %       % Construct a serialport object.
    %       s = serialport("COM1",38400);
    %
    %       % Write 1, 2, 3, 4, 5 as "uint8" data to the serial port.
    %       write(s,1:5,"uint8");
    %
    %       % Read 10 numbers of "uint16" data from the serial port.
    %       data = read(s,10,"uint16");
    %
    %       % Set the Terminator property
    %       configureTerminator(s,"CR/LF");
    %
    %       % Write "hello" to the serial port with the Terminator included.
    %       writeline(s,"hello");
    %
    %       % Read ASCII-terminated string from the serial port.
    %       data = readline(s);
    %
    %       % Write 1, 2, 3, 4, 5 as a binblock of "uint8" data to the serial
    %       % port.
    %       writebinblock(s,1:5,"uint8");
    %
    %       % Read binblock of "uint8" data from the serial port.
    %       data = readbinblock(s,"uint8");
    %
    %       % Query the serial port by writing an ASCII-terminated
    %       % string "*IDN?" to the serial port, and reading back an ASCII
    %       % terminated response from the serial port.
    %       response = writeread(s,"*IDN?");
    %
    %       % Set the Bytes Available Callback properties
    %       configureCallback(s,"byte",50,@myCallbackFcn);
    %
    %       % Flush output buffer
    %       flush(s,"output");
    %
    %       % Get the value of serialport pins
    %       status = getpinstatus(s);
    %
    %       % Set the DTR pin
    %       setDTR(s,true);
    %
    %       % Set the RTS pin
    %       setRTS(s,true);
    %
    %       % Set the serial break
    %       serialbreak(s,time);
    %
    %       % Disconnect and clear serialport connection
    %       clear s
    %
    %   See also SERIALPORTLIST.

    %   Copyright 2019-2024 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = private, Dependent)
        % Port - Specifies the serial port for connection.
        % Read/Write Access - Read-only
        % Accepted Values - Port name as a string or char array
        % Default - NA
        Port
    end

    properties (Access = public, Dependent)
        % BaudRate - Specifies the speed of communication (in bits per
        %            second) for the serial port.
        % Read/Write Access - Both
        % Accepted Values - Positive integer values
        % Default - NA
        BaudRate

        % Timeout - Specifies the waiting time (in seconds) to complete
        %           read and write operations.
        % Read/Write Access - Both
        % Accepted Values - Positive numeric values
        % Default - 10
        Timeout

        % FlowControl - Specifies the mode of managing the rate of data
        %               transmission.
        % Read/Write Access - Both
        % Accepted Values - "none", "hardware", "software" (string or char)
        % Default - "none"
        FlowControl

        % Parity - Specifies the parity to check whether data has been lost
        %          or written.
        % Read/Write Access - Both
        % Valid Values - "none", "even", "odd" (string or char)
        % Default - "none"
        Parity

        % StopBits - Specifies the pattern of bits that indicates the end
        %            of a character or of the whole transmission.
        % Read/Write Access - Both
        % Accepted Values - 1, 1.5, and 2
        % Default - 1
        StopBits

        % DataBits - Specifies the number of bits used to represent one
        %            character of data.
        % Read/Write Access - Both
        % Accepted Values - 5, 6, 7, 8
        % Default - 8
        DataBits

        % ByteOrder - Specifies the sequential order in which bytes are
        %             arranged into larger numerical values.
        % Read/Write Access - Both
        % Accepted Values - "little-endian", "big-endian" (char and string)
        % Default - "little-endian"
        ByteOrder

        % UserData - To store application specific data
        % Read/Write Access - Both
        % Accepted Values - Any MATLAB type
        % Default - []
        UserData

        % Note - SetAccess for BytesAvailableFcnMode, BytesAvailableFcn,
        % BytesAvailableFcnCount and Terminator, which are read-only
        % properties, is public to be able to throw custom and more
        % meaningful errors for setting these properties.

        % Terminator - Specifies the read and write terminator for the
        % ASCII terminated string communication.
        % Read/Write Access - Read-only
        % Default - "LF"
        %
        % To set this property, see <a href="matlab:help internal.Serialport.configureTerminator">configureTerminator</a> function.
        Terminator

        % BytesAvailableFcnCount - For BytesAvailableFcnMode = "byte", the
        %                          number of bytes in the input buffer that
        %                          triggers BytesAvailableFcn.
        % Read/Write Access - Read-only
        % Default - 64
        %
        % To set this property, see <a href="matlab:help internal.Serialport.configureCallback">configureCallback</a> function.
        BytesAvailableFcnCount

        % BytesAvailableFcnMode - Specifies the condition when the bytes
        %                         available callback is to be fired:
        %                         a. when BytesAvailableFcnCount number of
        %                            bytes are available to be read, or
        %                         b. when the terminator is reached, or
        %                         c. disables BytesAvailable callback.
        % Read/Write Access - Read-only
        % Default - "off"
        %
        % To set this property, see <a href="matlab:help internal.Serialport.configureCallback">configureCallback</a> function.
        BytesAvailableFcnMode

        % BytesAvailableFcn - The callback function that gets fired when
        %                     BytesAvailable event occurs.
        % Read/Write Access - Read-only
        % Valid Values - any function_handle
        % Default - []
        %
        % To set this property, see <a href="matlab:help internal.Serialport.configureCallback">configureCallback</a> function.
        BytesAvailableFcn

        % ErrorOccurredFcn - The function that gets called when an error
        %                    event occurs.
        % Read/Write Access - Both
        % Valid Values - function_handle
        % Default - []
        ErrorOccurredFcn
    end

    properties (GetAccess = public, SetAccess = private, Dependent)
        % NumBytesAvailable - Specifies the number of bytes available to be
        %                     read.
        % Read/Write Access - Read-only
        % Default - 0
        NumBytesAvailable

        % NumBytesWritten - Specifies the number of bytes written to the
        %                   serial port.
        % Read/Write Access - Read-only
        % Default - 0
        NumBytesWritten
    end

    properties (Hidden, Access = ...
            {?internal.Serialport, ?instrument.internal.ITestable})
        % PrefsHandler - The handle to the Serialport Preferences Handler.
        PrefsHandler

        % The handle to the GenericClient instance
        Client
    end

    properties(Hidden, Constant)
        %% Serialport properties used for displaying error messages and serialport data
        SelectPropertyList = {'Port', 'BaudRate', 'Tag', 'NumBytesAvailable'}

        CommunicationPropertiesList = {'ByteOrder', 'DataBits', ...
            'StopBits', 'Parity', 'FlowControl', 'Timeout', 'Terminator'}

        BytesAvailablePropertiesList = {'BytesAvailableFcnMode', ...
            'BytesAvailableFcnCount', 'BytesAvailableFcn', 'NumBytesWritten'}

        AdditionalPropertiesList = {'ErrorOccurredFcn', 'UserData'}

        CustomExamples = struct( ...
            "serialport", ("s = serialport()" + newline + "s = serialport(PORT,BAUDRATE)" ...
            + newline + "s = serialport(PORT,BAUDRATE,NAME,VALUE)"))
    end

    properties (Hidden, Constant)
        %% Serialport error and warning message IDs to be translated

        TransportlibErrorIDs (1, :) string = ["IncorrectInputArgumentsSingular", "IncorrectInputArgumentsPlural", ...
           "IncorrectBytesAvailableModeSyntax", "InvalidBytesAvailableFcn", "InvalidTerminator", ...
           "NoICTLicense", "InvalidErrorOccurredFcn", "ReadOnlyProperty"]
        GenericClientErrorIDs (1, :) string = ["expectedInteger", "expectedNonZero", "invalidType"]

        WarningIDs (1, :) string = ["ReadWarning", "ReadlineWarning", "ReadbinblockWarning"]
    end

    properties (Hidden, Constant)
        ObjectType = "serialport"
    end

    methods (Access = public)
        function obj = Serialport(varargin)
            %Serialport Constructs Serialport object.
            %
            %   OBJ = Serialport constructs a Serialport object, OBJ, using
            %   the previously cleared serialport object properties - PORT,
            %   BAUDRATE, BYTEORDER, FLOWCONTROL, STOPBITS, DATABITS,
            %   PARITY, TIMEOUT, and TERMINATOR.
            %
            %   OBJ = Serialport(PORT,BAUDRATE) constructs a
            %   Serialport object, OBJ, associated with serial port, PORT
            %   and BaudRate, BAUDRATE
            %
            %   OBJ = Serialport(PORT,BAUDRATE,'NAME','VALUE', ...)
            %   constructs a Serialport object, OBJ, associated with serial
            %   port, PORT and BaudRate, BAUDRATE, and one or more
            %   name-value pair arguments. Serialport properties that can
            %   be set using name-value pairs are ByteOrder, DataBits,
            %   StopBits, Timeout, Parity, and FlowControl.
            %
            % Input Arguments:
            %   PORT specifies the serial port to connect to
            %   BAUDRATE specifies the Baud rate for the serial communication.
            %
            %   Other writable Serialport properties can be passed in as an NV
            %   pair to the Serialport constructor, are "FLOWCONTROL", "STOPBITS",
            %   "DATABITS", "PARITY", "BYTEORDER", and "TIMEOUT".
            %
            % Example:
            %      % Create a serialport connection on COM1 with a Baud Rate
            %      % of 38400.
            %      s = serialport("COM1",38400);
            %
            %      % Create a serialport connection on COM3, Baud Rate of
            %      % 9600, and a Byte Order of "big-endian".
            %      s = serialport("COM3",9600,"ByteOrder","big-endian");

            if nargin == 1
                % This is an error condition
                funcName = 'serialport';
                throwAsCaller(MException(message...
                    ('serialport:serialport:IncorrectInputArgumentsPlural', ...
                    funcName, internal.Serialport.CustomExamples.(funcName))));
            end
            % Create instance of Serialport Preferences Handler
            obj.PrefsHandler = internal.SerialportPrefHandler();

            try
                terminator = [];
                if nargin == 0
                    % Use the serialport values saved in preferences
                    [port, baudrate, terminator, varargin] = ...
                        obj.PrefsHandler.parsePreferencesHandler();
                else
                    % Set the first argument to port, and second to
                    % BaudRate. Save the remaining (if any) as varargin.
                    port = varargin{1};
                    baudrate = varargin{2};
                    varargin = varargin(3:end);
                end

                port = instrument.internal.stringConversionHelpers.str2char(port);
                varargin = instrument.internal.stringConversionHelpers.str2char(varargin);
                validateattributes(port, {'char'}, {'nonempty'}, 'Serialport', 'PORT', 1);
                validateattributes(baudrate, {'double'}, {'nonempty', 'positive', 'scalar'} ...
                    , 'Serialport', 'BAUDRATE', 2);

                % Create the Generic Client instance
                transportProperties = obj.getTransportProperties(port);
                obj.Client = internal.SerialportClient(transportProperties);

                % Set the BaudRate
                obj.BaudRate = baudrate;

                % Validate that number of names and number of values match
                % for the NV pairs.
                if mod(numel(varargin), 2)
                    throwAsCaller(MException(message('serialport:serialport:UnmatchedPVPairs')));
                end

                % Initialize all properites to the default, or requested
                % state
                initProperties(obj, varargin);

                % Set Custom Display properties
                setCustomDisplay(obj);
            catch ex
                throwAsCaller(ex);
            end

            try
                % Establish a connection
                connect(obj.Client);
            catch ex
                errText = string(message('serialport:serialport:ConnectionFailed', port).getString);

                % For linux, append the ex.message to the original error
                % text
                if ~ismac && isunix
                    errText = errText + ...
                        newline + message('serialport:serialport:ConnectErrorSuffix').string + blanks(1) + string(ex.message);
                end
                % Retrieves troubleshooting doc link
                docRef = instrument.internal.errorMessagesHelpers.getConnectErrorDocLink("serialport");

                % Formats error message string
                if ~contains(errText, docRef)
                    strComplete = string(errText) + newline + docRef;
                else
                    strComplete = string(errText);
                end

                % Throws connection errors with troubleshooting doc link appended
                throwAsCaller(MException('serialport:serialport:ConnectionFailed', strComplete));
            end
            % Allow for partial reads. This ensures that in case of
            % incomplete reads, we get the requested data back along
            % with the timeout warning.
            setProperty(obj.Client, "AllowPartialReads", true);

            % Make the writes synchronous
            setProperty(obj.Client, "WriteAsync", false);

            if ~isempty(terminator)
                if isscalar(terminator)
                    configureTerminator(obj.Client, terminator);
                else
                    configureTerminator(obj.Client, terminator{1}, terminator{2});
                end
            end
        end

        function delete(obj)
            clientAlive = ~isempty(obj.Client) && isvalid(obj.Client);

            if clientAlive

                % If the client is still alive and connected, update the
                % preferences to be used for the next time the serialport
                % default constructor is invoked.
                if obj.Client.ClientConnected
                    obj.updatePreferences();
                end

                % Client cleanup
                disconnect(obj.Client);
                obj.Client = [];
            end
            obj.PrefsHandler = [];
        end

        function data = read(obj, varargin)
            %READ Read data from the serial port.
            %
            %   DATA = READ(OBJ,COUNT,PRECISION) reads the specified
            %   number of values, COUNT, with the specified precision,
            %   PRECISION, from the device connected to the
            %   serial port, OBJ, and returns to DATA. For numeric PRECISION
            %   types DATA is represented as a DOUBLE array in row format.
            %   For char and string PRECISION types, DATA is represented as
            %   is.
            %
            % Input Arguments:
            %   COUNT indicates the number of items to read. COUNT cannot be
            %   set to INF or NAN. If COUNT is greater than the
            %   NumBytesAvailable property of OBJ, then this function
            %   waits until the specified amount of data is read or a
            %   timeout occurs.
            %
            %   PRECISION indicates the number of bits read for each value
            %   and the interpretation of those bits as a MATLAB data type.
            %   PRECISION must be one of 'UINT8', 'INT8', 'UINT16',
            %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE',
            %   'DOUBLE', 'CHAR', or 'STRING'.
            %
            % Output Arguments:
            %   DATA is a 1xN matrix of numeric or ASCII data. If no data
            %   was returned, this is an empty array.
            %
            % Note:
            %   READ waits until the requested number of values are read
            %   from the serial port.
            %
            % Example:
            %      % Read 5 count of data as "uint32" (5*4 = 20 bytes).
            %      data = read(s,5,"uint32");
            try
                data = read(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function data = readline(obj, varargin)
            %READLINE Read ASCII-terminated string data from the serial
            %         port device
            %
            %   DATA = READLINE(OBJ) reads until the first occurrence of the
            %          terminator and returns the data back as a STRING. This
            %          function waits until the terminator is reached or a
            %          timeout occurs.
            %
            % Output Arguments:
            %   DATA is a string of ASCII data. If no data was returned,
            %   this is an empty string.
            %
            % Note:
            %   READLINE waits until the terminator is read from the serial
            %   port.
            %
            % Example:
            %      % Reads all data up to the first occurrence of the
            %      % terminator. Returns the data as a string with the
            %      % terminator removed.
            %      data = readline(s);
            try
                data = readline(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function data = readbinblock(obj, varargin)
            %READBINBLOCK Read one binblock of data from the serial port.
            %
            %   DATA = READBINBLOCK(OBJ) reads the binblock data as UINT8
            %          and represents them as a DOUBLE array in row format.
            %
            %   DATA = READBINBLOCK(OBJ,PRECISION) reads the binblock data as
            %          PRECISION type.For numeric PRECISION types DATA is
            %          represented as a DOUBLE array in row format.
            %          For char and string PRECISION types, DATA is
            %          represented as is.
            %
            % Input Arguments:
            %   PRECISION indicates the number of bits read for each value
            %   and the interpretation of those bits as a MATLAB data type.
            %   DATATYPE must be one of 'UINT8', 'INT8', 'UINT16',
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
            %   serial port.
            %   READBINBLOCK REQUIRES INSTRUMENT CONTROL TOOLBOX™.
            %
            % Example:
            %      % Reads the raw bytes in the binblock as uint8, and
            %      % represents them as a double array in row format.
            %      data = readbinblock(s);
            %
            %      % Reads the raw bytes in the binblock as uint16, and
            %      % represents them as a double array in row format.
            %      data = readbinblock(s,"uint16")

            try
                data = readbinblock(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function write(obj, varargin)
            %WRITE Write data to the serial port.
            %   WRITE(OBJ,DATA,PRECISION) sends the 1xN matrix of data to
            %   the serial port. The data is cast to the specified
            %   precision PRECISION regardless of the actual precision.
            %
            % Input Arguments:
            %   DATA is a 1xN matrix of numeric or ASCII data.
            %
            %   PRECISION controls the number of bits written for each value
            %   and the interpretation of those bits as integer, floating-point,
            %   or character values.
            %   PRECISION must be one of 'CHAR','STRING','UINT8', 'INT8', 'UINT16',
            %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE', or
            %   'DOUBLE'.
            %
            % Notes:
            %   WRITE waits until the requested number of values are
            %   written to the serial port.
            %
            % Example:
            %      % Writes 1, 2, 3, 4, 5 as uint8. (5*1 = 5 bytes total)
            %      % to the serial port.
            %      write(s, 1:5, "uint8");

            try
                write(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function writeline(obj, varargin)
            %WRITELINE Write ASCII data followed by the terminator to the serial
            %   port.
            %
            %   WRITELINE(OBJ,DATA) writes the ASCII data, DATA, followed
            %   by the terminator, to the serial port.
            %
            % Input Arguments:
            %   DATA is the ASCII data that is written to the serial port. This
            %   DATA is always followed by the write terminator character(s).
            %
            % Notes:
            %   WRITELINE waits until the ASCII DATA followed by terminator
            %   is written to the serial port.
            %
            % Example:
            %      % writes "*IDN?" and adds the terminator to the end of
            %      % the line before writing to the serial port.
            %      writeline(s,"*IDN?");
            %
            try
                writeline(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function writebinblock(obj, varargin)
            %WRITEBINBLOCK Write a binblock of data to the serial port.
            %
            %   WRITEBINBLOCK(OBJ,DATA,PRECISION) converts DATA into a
            %   binblock and writes it to the serial port. The data is
            %   cast to the specified precision PRECISION regardless of the
            %   actual precision.
            %
            %   WRITEBINBLOCK(OBJ,DATA,PRECISION,HEADER) converts DATA into
            %   a binblock and writes it to the serial port. The data is
            %   cast to the specified precision PRECISION regardless of the
            %   actual precision. The HEADER is prepended to the binblock
            %   before writing.
            %
            % Input Arguments:
            %   DATA is a 1xN matrix of numeric or ASCII data that is
            %   written as a binblock to the serial port.
            %
            %   PRECISION - Specifies the data type to interpret DATA as
            %   when converting to a uint8 array for writing.
            %   PRECISION must be one of 'CHAR', 'STRING', 'UINT8', 'INT8', 'UINT16',
            %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE', or
            %   'DOUBLE'.
            %
            %   HEADER is the optional custom header to prepend to the
            %   binblock before writing. HEADER must be an ASCII string.
            %
            % Notes:
            %   WRITEBINBLOCK waits until the binblock DATA is written
            %   to the serial port.
            %   WRITEBINBLOCK REQUIRES INSTRUMENT CONTROL TOOLBOX™.
            %
            % Example:
            %      % Converts 1, 2, 3, 4, 5 to a binblock and writes it to
            %      % the serial port as uint8.
            %      writebinblock(s,1:5,"uint8");
            %
            %      % Converts 1, 2, 3, 4, 5 to a binblock and writes it to
            %      % the serial port as uint8 with the custom header
            %      % "MyHeader" prepended to the binblock packet before
            %      % writing.
            %      writebinblock(s,1:5,"uint8","MyHeader");

            try
                writebinblock(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function response = writeread(obj, varargin)
            %WRITEREAD Write ASCII-terminated string COMMAND to serial port and
            %reads back an ASCII-terminated string RESPONSE.
            %This function can be used to query an instrument connected to
            %the serial port.
            %
            %   RESPONSE = WRITEREAD(OBJ,COMMAND) writes the COMMAND
            %   followed by the write terminator to the serial port. It reads
            %   back the RESPONSE from the serial port, which is an ASCII
            %   terminated string, and returns the RESPONSE after removing
            %   the read terminator.
            %
            % Input Arguments:
            %   COMMAND: The terminated ASCII data that is written to the
            %   serial port
            %
            % Output Arguments:
            %   RESPONSE: The terminated ASCII data that is returned back
            %   from the serialport.
            %
            % Notes:
            %   WRITEREAD waits until the ASCII-terminated COMMAND is written
            %   and an ASCII-terminated RESPONSE is retuned from the serial port.
            %   WRITEREAD REQUIRES INSTRUMENT CONTROL TOOLBOX™.
            %
            % Example:
            %      % Query the serial port for a response by sending "IDN?"
            %      % command.
            %      response = writeread(s,"*IDN?");
            %

            try
                response = writeread(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function configureCallback(obj, varargin)
            %CONFIGURECALLBACK Set the BytesAvailable properties:
            % 1. <a href="matlab:help internal.Serialport.BytesAvailableFcnMode">BytesAvailableFcnMode</a>
            % 2. <a href="matlab:help internal.Serialport.BytesAvailableFcnCount">BytesAvailableFcnCount</a>
            % 3. <a href="matlab:help internal.Serialport.BytesAvailableFcn">BytesAvailableFcn</a>
            %
            % CONFIGURECALLBACK(OBJ,MODE) - For this syntax, the only
            % possible value for MODE is "off". This turns the BytesAvailable
            % callbacks off.
            %
            % CONFIGURECALLBACK(OBJ,MODE,CALLBACKFCN) - For this syntax,
            % the only possible value for MODE is "terminator". This sets the
            % BytesAvailableFcnMode property to "terminator". CALLBACKFCN
            % is the function handle that is assigned to BytesAvailableFcn.
            % CALLBACKFCN is triggered whenever a terminator is available
            % to be read.
            %
            % CONFIGURECALLBACK(OBJ,MODE,COUNT,CALLBACKFCN) - For this
            % syntax, the only possible value for MODE is "BYTE". This sets
            % the BytesAvailableFcnMode property to "BYTE". CALLBACKFCN is
            % the function handle that is assigned to BytesAvailableFcn.
            % CALLBACKFCN is triggered whenever COUNT number of bytes are
            % available to be read. BytesAvailableFcnCount is set to COUNT.
            %
            % Input Arguments:
            %   MODE: The BytesAvailableFcnMode. Possible values are "off",
            %   "terminator", and "byte".
            %
            %   COUNT: The BytesAvailableFcnCount. This can be set to any
            %   positive integer value. Valid only for MODE = "byte"
            %
            %   CALLBACKFCN: The BytesAvailableFcn. This can be set to a
            %   function_handle.
            %
            % Example:
            %      % Turn the callback off
            %      configureCallback(s,"off")
            %
            %      % Set the BytesAvailableFcnMode to "terminator". This
            %      % triggers the callback function "callbackFcn" when a
            %      % terminator is available to be read.
            %      configureCallback(s,"terminator",@callbackFcn)
            %
            %      % Set the BytesAvailableFcnMode to "byte". This
            %      % triggers the callback function "callbackFcn" when 50
            %      % bytes of data are available to be read.
            %      configureCallback(s,"byte",50,@callbackFcn)
            try
                configureCallback(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function configureTerminator(obj, varargin)
            %CONFIGURETERMINATOR Set the Terminator property for ASCII
            % terminated string communication on the serial port.
            %
            % CONFIGURETERMINATOR(OBJ,TERMINATOR) - Sets the Terminator
            % property to TERMINATOR for the serialport object. TERMINATOR
            % applies to both Read and Write Terminators.
            %
            % CONFIGURETERMINATOR(OBJ,READTERMINATOR,WRITETERMINATOR) -
            % Sets the Terminator property of the serialport to a cell
            % array of {READTERMINATOR,WRITETERMINATOR}. It sets the
            % Read Terminator to READTERMINATOR and the Write Terminator to
            % WRITETERMINATOR for the serialport object.
            %
            % Input Arguments:
            %   TERMINATOR: The terminating character for as ASCII
            %   terminated communication. This sets both Read and Write
            %   Terminators to TERMINATOR.
            %   Accepted Values - Integers ranging from 0 to 255
            %                     "CR", "LF", "CR/LF"
            %
            %   READTERMINATOR: The read terminating character for as ASCII
            %   terminated communication. This sets the Read Terminator to
            %   READTERMINATOR.
            %   Accepted Values - Integers ranging from 0 to 255
            %                     "CR", "LF", "CR/LF"
            %
            %   WRITETERMINATOR: The write terminating character for as ASCII
            %   terminated communication. This sets the write Terminator to
            %   WRITETERMINATOR.
            %   Accepted Values - Integers ranging from 0 to 255
            %                     "CR", "LF", "CR/LF"
            %
            % Example:
            %      % Set both read and write terminators to "CR/LF"
            %      configureTerminator(s,"CR/LF")
            %
            %      % Set read terminator to "CR" and write terminator to
            %      % ASCII value of 10
            %      configureTerminator(s,"CR",10)

            try
                configureTerminator(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function flush(obj, varargin)
            %FLUSH Clear the input buffer, output buffer, or both, based
            % on the value of BUFFER.
            %
            % FLUSH(OBJ) clears both the input and output buffers.
            %
            % FLUSH(OBJ,BUFFER) clears the serial input buffer or output
            % buffer, based on the value of BUFFER.
            %
            % Input Arguments:
            %   BUFFER is the type of buffer that needs to be flushed.
            %   Accepted Values - "input", "output".
            %
            % Example:
            %      % Flush the input buffer
            %      flush(s,"input");
            %
            %      % Flush the output buffer
            %      flush(s,"output");
            %
            %      % Flush both the input and output buffers
            %      flush(s);
            try
                flush(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function status = getpinstatus(obj, varargin)
            %GETPINSTATUS Get the serial pin status.
            %
            % STATUS = GETPINSTATUS(OBJ) gets the serial pin status and
            % returns it as a struct to STATUS.
            %
            % Output Arguments:
            %   STATUS: 1x1 struct with the fields, ClearToSend,
            %   DataSetReady, CarrierDetect, and RingIndicator.
            %
            % Example:
            %      % Get the pin status
            %      status = getpinstatus(s);

            try
                status = getpinstatus(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function setRTS(obj, varargin)
            %SETRTS Set/reset the serial RTS (Ready to Send) pin
            %
            % SETRTS(OBJ,FLAG) sets or resets the serial RTS pin, based
            % on the value of FLAG.
            %
            % Input Arguments:
            %   FLAG: Logical true or false. FLAG set to true sets the
            %   RTS pin, false resets it.
            %
            % Example:
            %      % Set the RTS pin
            %      setRTS(s,true);
            %
            %      % Reset the RTS pin
            %      setRTS(s,false);

            try
                setRTS(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function setDTR(obj, varargin)
            %SETDTR Set/reset the serial DTR (Data Terminal Ready) pin
            %
            % SETDTR(OBJ, FLAG) sets or resets the serial DTR pin, based
            % on the value of FLAG.
            %
            % Input Arguments:
            %   FLAG: Logical true or false. FLAG set to true sets the
            %   DTR pin, false resets it.
            %
            % Example:
            %      % Set the DTR pin
            %      setDTR(s, true);
            %
            %      % Reset the RTS pin
            %      setDTR(s, false);

            try
                setDTR(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function serialbreak(obj, varargin)
            % SERIALBREAK Send a serial break signal
            %
            % serialbreak(OBJ,TIME) sends a serial break signal by setting
            % the transmit pin (TXD) to high for the duration specified by
            % TIME in milliseconds.
            %
            % Input Arguments:
            % TIME: Positive integer that specifies the duration of the
            % serial break signal in milliseconds.
            %
            % Example:
            %      Send a serial break to the device
            %      serialbreak(s, time);
            try
                serialbreak(obj.Client, varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end
    end

    methods (Access = private)
        %% Private methods
        function setCustomDisplay(obj)
            % Set the matlabshared.testmeas.CustomDisplay properties
            obj.PropertyGroupList = {obj.SelectPropertyList, obj.CommunicationPropertiesList, ...
                obj.BytesAvailablePropertiesList, obj.AdditionalPropertiesList};
            obj.PropertyGroupNames = ["" "" "" ""];
        end

        function initProperties(obj, inputs)
            % INITPROPERITES Partial match contructor N-V pairs and assign
            % to properties
            p = inputParser;
            p.PartialMatching = true;
            addParameter(p, 'DataBits', 8, @isscalar);
            addParameter(p, 'Parity', 'none', @(x) validateattributes(x,{'char','string'},{'nonempty'}));
            addParameter(p, 'StopBits', 1, @isscalar);
            addParameter(p, 'FlowControl', 'none', @(x) validateattributes(x,{'char','string'},{'nonempty'}));
            addParameter(p, 'ByteOrder', 'little-endian', @(x) validateattributes(x,{'char','string'},{'nonempty'}));
            addParameter(p, 'Timeout', 10, @isscalar);
            addParameter(p, 'Tag', "", @(x) isstring(x) || ischar(x));
            parse(p, inputs{:});
            output = p.Results;

            % Set the properties.
            obj.DataBits  = output.DataBits;
            obj.Parity    = output.Parity;
            obj.StopBits  = output.StopBits;
            obj.FlowControl = output.FlowControl;
            obj.ByteOrder = output.ByteOrder;
            obj.Timeout   = output.Timeout;
            obj.Tag = output.Tag;
        end
    end

    methods (Hidden)
        function value = instrhwinfo(obj, propertyName)
            % instrhwinfo fucntion displays the properties of the serialport
            % object for instrhwinfo(s). For instrhwinfo(s, <propertyName>),
            % it displays the value of that particular proeprty.
            % E.g.
            % instrhwinfo(s, "BaudRate")
            % ans =
            %      9600
            try
                value = obj.(propertyName);
            catch ex
                throwAsCaller(ex);
            end
        end

        function s = saveobj(obj)
            % Save the existing serialport properties as a struct that can
            % be used to re-create the serialport object when loaded.
            allProps = properties(obj);
            excludedProps = ["NumBytesAvailable", "NumBytesWritten", "UserData"];
            for i = 1 : length(allProps)

                % Do not save the properties if one of excludedProps.
                if ~ismember(allProps{i}, excludedProps)
                    s.(allProps{i}) = obj.(allProps{i});
                end
            end
        end

    end

    methods (Static, Hidden)
        function result = clearPreferences()
            % Hidden method to clear all Preferences data for serialport.
            result = internal.SerialportPrefHandler.clearPreferences();
        end

        function serialPortInstance = loadobj(obj)
            % Load a new serialport instance based on property values saved
            % using saveobj.

            % Create a new serialport object using the saved struct in
            % saveobj.
            if isstruct(obj)
                % Create serialport object.
                serialPortInstance = serialport(obj.Port, obj.BaudRate, ...
                    "Parity", obj.Parity, ...
                    "DataBits", obj.DataBits, ...
                    "StopBits", obj.StopBits, ...
                    "ByteOrder", obj.ByteOrder, ...
                    "FlowControl", obj.FlowControl, ...
                    "Timeout", obj.Timeout, ...
                    "Tag", obj.Tag);

                serialPortInstance.ErrorOccurredFcn = obj.ErrorOccurredFcn;
                switch string(obj.BytesAvailableFcnMode)
                    case "off"
                        configureCallback(serialPortInstance, obj.BytesAvailableFcnMode);
                    case "byte"
                        configureCallback(serialPortInstance, obj.BytesAvailableFcnMode, obj.BytesAvailableFcnCount, obj.BytesAvailableFcn);
                    case "terminator"
                        configureCallback(serialPortInstance, obj.BytesAvailableFcnMode, obj.BytesAvailableFcn);
                end

                if iscell(obj.Terminator)
                    configureTerminator(serialPortInstance, obj.Terminator{1}, obj.Terminator{2});
                else
                    configureTerminator(serialPortInstance, obj.Terminator);
                end

            elseif isa(obj, "internal.Serialport")
                % If load automatically creates a serialport object instead
                % of the struct, return the serialport object back.
                serialPortInstance = obj;
            end
        end
    end

    methods (Access = private, Hidden)

        function transportProperties = getTransportProperties(obj, port)
            % Prepare and return the transport properties.
            transportProperties = ...
                matlabshared.transportlib.internal.client.PropertiesFactory.getInstance("transport");
            transportProperties.CallbackSource = obj;
            transportProperties.InterfaceName = "serialport";
            transportProperties.InterfaceObjectName = "s";
            transportProperties.Transport = matlabshared.transportlib.internal.TransportFactory.getTransport("serial", port);
            transportProperties.PrecisionRequired = true;

            % Create the error registry
            transportProperties.ErrorRegistry = ...
                matlabshared.transportlib.internal.client.utility.ErrorRegistry(getErrorEntries(obj));

            % Create the warning registry
            transportProperties.WarningRegistry = getWarningEntries(obj);

            %% NESTED FUNCTION
            function entries = getErrorEntries(~)
                entries = containers.Map;
                for id = internal.Serialport.TransportlibErrorIDs
                    entries("transportlib:client:" + id) = ...
                        matlabshared.transportlib.internal.client.utility.ErrorEntry( ...
                        "serialport:serialport:" + id);
                end

                for id = internal.Serialport.GenericClientErrorIDs
                    entries("MATLAB:GenericClient:" + id) = ...
                        matlabshared.transportlib.internal.client.utility.ErrorEntry( ...
                        "MATLAB:Serialport:" + id);
                end
            end

            %% NESTED FUNCTION
            function entries = getWarningEntries(~)
                entries = dictionary;
                for id = internal.Serialport.WarningIDs
                    entries("transportlib:client:" + id) = "serialport:serialport:" + id;
                end

                % Other entries, if any.
            end
        end

        function updatePreferences(obj)
            % Helper function to update the preferences data for
            % Serialport.

            properties = obj.PrefsHandler.PreferencesPropertiesList;
            preferencesData = struct;
            for i = 1 : length(properties)
                preferencesData.(properties{i}) = obj.(properties{i});
            end
            obj.PrefsHandler.updatePreferences(preferencesData);
        end
    end

    %% Getters/Setters
    methods

        %% Getters
        function value = get.Port(obj)
            value = string(getProperty(obj.Client, "Port"));
        end

        function value = get.NumBytesAvailable(obj)
            value = getProperty(obj.Client, "NumBytesAvailable");
        end

        function value = get.BytesAvailableFcn(obj)
            value = getProperty(obj.Client, "BytesAvailableFcn");
        end

        function value = get.BytesAvailableFcnCount(obj)
            value = getProperty(obj.Client, "BytesAvailableFcnCount");
        end

        function value = get.BytesAvailableFcnMode(obj)
            value = getProperty(obj.Client, "BytesAvailableFcnMode");
        end

        function value = get.Timeout(obj)
            value = getProperty(obj.Client, "Timeout");
        end

        function value = get.BaudRate(obj)
            value = getProperty(obj.Client, "BaudRate");
        end

        function value = get.FlowControl(obj)
            value = string(getProperty(obj.Client, "FlowControl"));
        end

        function value = get.Parity(obj)
            value = string(getProperty(obj.Client, "Parity"));
        end

        function value = get.StopBits(obj)
            value = getProperty(obj.Client, "StopBits");
        end

        function value = get.ByteOrder(obj)
            value = string(getProperty(obj.Client, "ByteOrder"));
        end

        function value = get.DataBits(obj)
            value = getProperty(obj.Client, "DataBits");
        end

        function value = get.Terminator(obj)
            value = getProperty(obj.Client, "Terminator");
        end

        function value = get.UserData(obj)
            value = getProperty(obj.Client, "UserData");
        end

        function value = get.NumBytesWritten(obj)
            value = getProperty(obj.Client, "NumBytesWritten");
        end

        function value = get.ErrorOccurredFcn(obj)
            value = getProperty(obj.Client, "ErrorOccurredFcn");
        end

        %% Setters
        function set.Timeout(obj, value)
            try
                setProperty(obj.Client, "Timeout", value);
            catch ex
                if ex.identifier == "Stream:timeout:invalidTime"
                    ex = MException(ex.identifier,message('serialport:serialport:IncorrectTimeout').getString);
                end
                throwAsCaller(ex);
            end
        end

        function set.BaudRate(obj, value)
            try
                % Validate the value.
                validateattributes(value, {'numeric'}, {'scalar', 'nonnegative', 'finite', ...
                    'nonzero', 'integer'}, mfilename, 'BaudRate');
            catch %#ok<CTCH>
                throwAsCaller(MException(message( ...
                    'serialport:serialport:InvalidBaudRate')));
            end
            try
                setProperty(obj.Client, "BaudRate", value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.FlowControl(obj, value)
            try
                setProperty(obj.Client, "FlowControl", value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.Parity(obj, value)
            try
                setProperty(obj.Client, "Parity", value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.StopBits(obj, value)
            try
                setProperty(obj.Client, "StopBits", value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.DataBits(obj, value)
            try
                setProperty(obj.Client, "DataBits", value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.ByteOrder(obj, value)
            try
                setProperty(obj.Client, "ByteOrder", value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.UserData(obj, value)
            setProperty(obj.Client, "UserData", value);
        end

        function set.ErrorOccurredFcn(obj, value)
            try
                setProperty(obj.Client, "ErrorOccurredFcn", value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.Terminator(obj, value)
            try
                setProperty(obj.Client, "Terminator", value);
            catch ex
                throwAsCaller(ex);
            end
        end

        function set.BytesAvailableFcnCount(~, ~)
            throwAsCaller(MException(message('serialport:serialport:ReadOnlyProperty', ...
                'BytesAvailableFcnCount', 'configureCallback')));
        end

        function set.BytesAvailableFcnMode(~, ~)
            throwAsCaller(MException(message('serialport:serialport:ReadOnlyProperty', ...
                'BytesAvailableFcnMode', 'configureCallback')));
        end

        function set.BytesAvailableFcn(~, ~)
            throwAsCaller(MException(message('serialport:serialport:ReadOnlyProperty', ...
                'BytesAvailableFcn', 'configureCallback')));
        end
    end
end
