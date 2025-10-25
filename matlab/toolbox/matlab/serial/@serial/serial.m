classdef serial < icinterface & instrument.internal.ICTRemoveFunctionalityHelper
    %SERIAL Construct serial port object.
    %
    %   SERIAL will be removed in a future release. Use <a href="matlab:help serialport">serialport</a> instead.
    %
    %   S = SERIAL('PORT') constructs a serial port object associated with
    %   port, PORT. If PORT does not exist or is in use you will not be able
    %   to connect the serial port object to the device.
    %
    %   In order to communicate with the device, the object must be connected
    %   to the serial port with the FOPEN function.
    %
    %   When the serial port object is constructed, the object's Status property
    %   is closed. Once the object is connected to the serial port with the
    %   FOPEN function, the Status property is configured to open. Only one serial
    %   port object may be connected to a serial port at a time.
    %
    %   S = SERIAL('PORT','P1',V1,'P2',V2,...) constructs a serial port object
    %   associated with port, PORT, and with the specified property values. If
    %   an invalid property name or property value is specified the object will
    %   not be created.
    %
    %   Note that the property value pairs can be in any format supported by
    %   the SET function, i.e., param-value string pairs, structures, and
    %   param-value cell array pairs.
    %
    % SERIAL Functions
    % SERIAL object construction.
    %   serial        - Construct serial port object.
    %
    % Getting and setting parameters.
    %   get           - Get value of serial port object property.
    %   set           - Set value of serial port object property.
    %
    % State change.
    %   fopen         - Connect object to device.
    %   fclose        - Disconnect object from device.
    %   record        - Record data from serial port session.
    %
    % Read and write functions.
    %   fprintf       - Write text to device.
    %   fgetl         - Read one line of text from device, discard terminator.
    %   fgets         - Read one line of text from device, keep terminator.
    %   fread         - Read binary data from device.
    %   fscanf        - Read data from device and format as text.
    %   fwrite        - Write binary data to device.
    %   readasync     - Read data asynchronously from device.
    %
    % SERIAL port functions.
    %   serialbreak   - Send break to device.
    %
    % General.
    %   delete        - Remove serial port object from memory.
    %   inspect       - Open inspector and inspect instrument object properties.
    %   instrcallback - Display event information for the event.
    %   instrfind     - Find serial port objects with specified property values.
    %   instrfindall  - Find all instrument objects regardless of ObjectVisibility.
    %   isvalid       - True for serial port objects that can be connected to
    %                   device.
    %   stopasync     - Stop asynchronous read and write operation.
    %
    % SERIAL Properties
    %   BaudRate                  - Specify rate at which data bits are transmitted.
    %   BreakInterruptFcn         - Callback function executed when break interrupt
    %                               occurs.
    %   ByteOrder                 - Byte order of the device.
    %   BytesAvailable            - Specifies number of bytes available to be read.
    %   BytesAvailableFcn         - Callback function executed when specified number
    %                               of bytes are available.
    %   BytesAvailableFcnCount    - Number of bytes to be available before
    %                               executing BytesAvailableFcn.
    %   BytesAvailableFcnMode     - Specifies whether the BytesAvailableFcn is
    %                               based on the number of bytes or terminator
    %                               being reached.
    %   BytesToOutput             - Number of bytes currently waiting to be sent.
    %   DataBits                  - Number of data bits that are transmitted.
    %   DataTerminalReady         - State of the DataTerminalReady pin.
    %   ErrorFcn                  - Callback function executed when an error occurs.
    %   FlowControl               - Specify the data flow control method to use.
    %   InputBufferSize           - Total size of the input buffer.
    %   Name                      - Descriptive name of the serial port object.
    %   ObjectVisibility          - Control access to an object by command-line users and
    %                               GUIs.
    %   OutputBufferSize          - Total size of the output buffer.
    %   OutputEmptyFcn            - Callback function executed when output buffer is
    %                               empty.
    %   Parity                    - Error detection mechanism.
    %   PinStatus                 - State of hardware pins.
    %   PinStatusFcn              - Callback function executed when pin in the
    %                               PinStatus structure changes value.
    %   Port                      - Description of a hardware port.
    %   ReadAsyncMode             - Specify whether an asynchronous read operation
    %                               is continuous or manual.
    %   RecordDetail              - Amount of information recorded to disk.
    %   RecordMode                - Specify whether data is saved to one disk file
    %                               or to multiple disk files.
    %   RecordName                - Name of disk file to which data sent and
    %                               received is recorded.
    %   RecordStatus              - Indicates if data is being written to disk.
    %   RequestToSend             - State of the RequestToSend pin.
    %   Status                    - Indicates if the serial port object is connected
    %                               to serial port.
    %   StopBits                  - Number of bits transmitted to indicate the end
    %                               of data transmission.
    %   Tag                       - Label for object.
    %   Terminator                - Character used to terminate commands sent to
    %                               serial port.
    %   Timeout                   - Seconds to wait to receive data.
    %   TimerFcn                  - Callback function executed when a timer event
    %                               occurs.
    %   TimerPeriod               - Time in seconds between timer events.
    %   TransferStatus            - Indicate the asynchronous read or write
    %                               operations that are in progress.
    %   Type                      - Object type.
    %   UserData                  - User data for object.
    %   ValuesReceived            - Number of values read from the device.
    %   ValuesSent                - Number of values written to device.
    %
    %   Example:
    %       % To construct a serial port object:
    %         s1 = serial('COM1');
    %         s2 = serial('COM2', 'BaudRate', 1200);
    %
    %       % To connect the serial port object to the serial port:
    %         fopen(s1)
    %         fopen(s2)
    %
    %       % To query the device.
    %         fprintf(s1, '*IDN?');
    %         idn = fscanf(s1);
    %
    %       % To disconnect the serial port object from the serial port.
    %         fclose(s1);
    %         fclose(s2);
    %
    %   See also SERIAL/FOPEN.
    %
    
    %   Copyright 1999-2021 The MathWorks, Inc.
    
    properties(Hidden, SetAccess = 'public', GetAccess = 'public')
        icinterface
    end
    
    methods
        function obj = serial(varargin)

            % Create the class that will throw a warning and error as part of the
            % legacy interface remove functionality "Warn" phase and "Error" phases.
            obj = obj@instrument.internal.ICTRemoveFunctionalityHelper("serial");
            
            obj = obj@icinterface('serial'); %#ok<PROP>
            
            try
                obj.icinterface =  icinterface('serial');
            catch %#ok<CTCH>
                error(message('MATLAB:serial:serial:nojvm'));
            end
            
            % convert to char in order to accept string datatype
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);
            
            switch (nargin)
                case 0
                    error(message('MATLAB:serial:serial:invalidSyntax'));
                case 1
                    if (ischar(varargin{1}))
                        % Ex. s = serial('COM1')
                        % Call the java constructor and store the java object in the
                        % serial object.
                        if isempty(varargin{1})
                            error(message('MATLAB:serial:serial:invalidPORTempty'));
                        end
                        try
                            obj.jobject = handle(javaObject('com.mathworks.toolbox.instrument.SerialComm',varargin{1}));
                        catch aException
                            error(message('MATLAB:serial:serial:cannotCreate', aException.message));
                        end
                    elseif strcmp(class(varargin{1}), 'serial')
                        obj = varargin{1};
                    elseif isa(varargin{1}, 'com.mathworks.toolbox.instrument.SerialComm')
                        obj.jobject = handle(varargin{1});
                    elseif isa(varargin{1}, 'javahandle.com.mathworks.toolbox.instrument.SerialComm')
                        obj.jobject = varargin{1};
                    elseif ishandle(varargin{1})
                        % True if loading an array of objects and the first is a GPIB object.
                        if isa(varargin{1}(1), 'javahandle.com.mathworks.toolbox.instrument.SerialComm')
                            obj.jobject = varargin{1};
                        else
                            error(message('MATLAB:serial:serial:invalidPORT'));
                        end
                    else
                        error(message('MATLAB:serial:serial:invalidPORT'));
                    end
                otherwise
                    % Ex. s = serial('COM1', 'BaudRate', 4800);
                    try
                        % See g405634 for why we use javaObject
                        obj.jobject = handle(javaObject('com.mathworks.toolbox.instrument.SerialComm',varargin{1}));
                    catch aException
                        error(message('MATLAB:serial:serial:cannotCreate', aException.message));
                    end
                    % Try setting the object properties.
                    try
                        set(obj, varargin{2:end});
                    catch aException
                        delete(obj);
                        localFixError(aException);
                    end
            end
            
            % Set the doc ID for the interface object. This sets values for
            % DocIDNoData and DocIDSomeData
            obj = obj.setDocID('serial');
            
            % Set Constructor types
            setMATLABClassName( obj.jobject(1),obj.constructor);
            
            if isvalid(obj)
                % Pass the OOPs object to java. Used for callbacks.
                obj.jobject(1).setMATLABObject(obj);
            end
        end
    end
    
    % Separate Files
    methods(Static = true, Hidden = true)
        obj = loadobj(B);
    end
    methods(Hidden = true)
        out = igetfield(obj, field);
        obj = isetfield(obj, field, value);
        val = class(obj,varargin);
        obj = ctranspose(obj);
        display(obj);
        endval = end(obj,k,n);
        iseq=eq(arg1, arg2);
        out = fieldnames(obj, flag);
        output = get(obj, varargin);
        out = horzcat(varargin);
        result=isa(arg1, arg2);
        out = isequal(varargin);
        isneq=ne(arg1, arg2);
        openvar(~, obj);
        prefspanel(obj);
        outputStruct = set(obj, varargin);
        Obj = subsasgn(Obj, Struct, Value);
        result = subsref(obj, Struct);
        out = vertcat(varargin);
    end
end


% *******************************************************************
% Fix the error message.
function localFixError(aException)

errmsg = aException.message;

% Remove the trailing carriage returns from errmsg.
while errmsg(end) == sprintf('\n')
    errmsg = errmsg(1:end-1);
end

throwAsCaller(MException(aException.identifier, errmsg));

end


