function obj = serialport(varargin)
%SERIALPORT Create serial client for communication with the serial port
%
%   s = SERIALPORT(PORT,BAUDRATE) constructs a serialport object, s,
%   associated with port value, PORT and a baud rate of BAUDRATE, and
%   automatically connects to the serial port.
%
%   s = SERIALPORT(PORT,BAUDRATE,"NAME","VALUE",...) constructs a
%   serialport object using one or more name-value pair arguments. If an
%   invalid property name or property value is specified the object will
%   not be created. Serialport properties that can be set using name-value
%   pairs are ByteOrder, DataBits, StopBits, Timeout, Tag, Parity, and
%   FlowControl.
%
%   s = SERIALPORT constructs a serialport object using the property
%   settings of the last cleared serialport object instance. The retained
%   properties are Port, BaudRate, ByteOrder, FlowControl, StopBits,
%   DataBits, Parity, Timeout, Tag, and Terminator.
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
%
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
%       % Send a serial break signal
%       serialbreak(s,time);  
%
%       % Disconnect and clear serialport connection
%       clear s
%
%   See also SERIALPORTLIST.

% Copyright 2019-2023 The MathWorks, Inc.

obj = internal.Serialport(varargin{:});
end