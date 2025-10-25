classdef ClientImpl < handle
    %CLIENTIMPL contains the ASCII terminated communication methods
    % (readline and writeline) and methods writeread, readbinblock,
    % and writebinblock that require an ICT license.

    % Copyright 2019-2023 The MathWorks, Inc.

    properties (Access = private)
        % Used for reading and writing binary, ASCII and token data from the
        % AsyncIO Channel
        Transport

        % Supports ASCII terminated communication
        StringClient

        % Supports functions that require an ICT license such as
        % writebinblock, readbinblock and writeread
        InstrumentImpl

        % Throws errors/warnings specific to the interface
        UserNotificationHandler
    end

    properties(Dependent)
        % Specifies the read and write terminator for the
        % ASCII terminated string communication.
        % Read/Write Access - Read-only
        Terminator

        % Handle to callback function which will receive
        % SerialDataBlocks from the input stream.
        StringReadFcn

        % The buffer index of the peeked data for which the last callback
        % was issued.
        LastCallbackIdx
    end
    
    properties
        % Flag to show warnings instead of errors in case of a readline or
        % readbinblock timeout. 
        % true - Issue read timeout warnings.
        % false - Throw read timeout errors.
       ShowReadWarnings (1, 1) logical = true
    end

    %% Getters and Setters
    methods
        function value = get.Terminator(obj)
            value = obj.StringClient.UserTerminator;
        end

        function value = get.StringReadFcn(obj)
            value = obj.StringClient.StringReadFcn;
        end

        function set.StringReadFcn(obj, value)
            try
                obj.StringClient.StringReadFcn = value;
            catch mExcept
                throw(obj.UserNotificationHandler.translateErrorId(mExcept));
            end
        end

        function set.Terminator(obj, ~)
            % Throws error as Terminator can only be set using configureTerminator
            ex = MException(message('transportlib:client:ReadOnlyProperty', ...
                'Terminator', 'configureTerminator'));
            throw(obj.UserNotificationHandler.translateErrorId(ex));
        end

        function value = get.LastCallbackIdx(obj)
            value = obj.StringClient.LastCallbackIdx;
        end

        function set.LastCallbackIdx(obj, value)
            try
                obj.StringClient.LastCallbackIdx = value;
            catch mExcept
                throw(obj.UserNotificationHandler.translateErrorId(mExcept));
            end
        end
    end

    %% Lifetime
    methods
        function obj = ClientImpl(genericTransport, warningErrorHandler)
            if ~isa(genericTransport, "matlabshared.transportlib.internal.ITransport") || ...
                    ~isa(genericTransport, "matlabshared.transportlib.internal.ITokenReader")
                throw(MException(message('transportlib:client:InvalidTransportType')));
            end

            obj.Transport = genericTransport;

            obj.StringClient = matlabshared.transportclients.internal.StringClient.StringClient ...
                (obj.Transport);

            obj.UserNotificationHandler = warningErrorHandler;
        end
    end

    %% API
    methods
        function data = readline(obj, varargin)
            %READLINE Read ASCII-terminated string data from the transport
            %
            %   DATA = READLINE(OBJ) reads until the first occurrence of the
            %   terminator and returns the data back as a STRING. This
            %   function waits until the terminator is reached or a
            %   timeout occurs.
            %
            %   Output Arguments:
            %       DATA is a string of ASCII data. If no data was returned,
            %       this is an empty string.
            %
            %   Note:
            %       READLINE waits until the terminator is read from the transport.
            %
            %   Example:
            %       % Reads all data up to the first occurrence of the
            %       % terminator. Returns the data as a string with the
            %       % terminator removed.
            %       data = readline(obj);

            try
                narginchk(1, 1);
            catch
                obj.UserNotificationHandler.throwNarginErrorSingular('readline');
            end

            try
                precision = "string";
                data = read(obj.StringClient, precision);
            catch ex
                if obj.ShowReadWarnings && ex.identifier == "transportclients:string:timeoutToken"
                    data = [];
                    obj.UserNotificationHandler.displayReadWarning([], 'Readline');
                else
                    throwAsCaller(ex);
                end
            end
        end

        function configureTerminator(obj, varargin)
            %CONFIGURETERMINATOR Set the Terminator property for ASCII
            % terminated string communication on the transport.
            %
            %   CONFIGURETERMINATOR(OBJ,TERMINATOR) - Sets the Terminator
            %   property to TERMINATOR for the interface object. TERMINATOR
            %   applies to both Read and Write Terminators.
            %
            %   CONFIGURETERMINATOR(OBJ,READTERMINATOR,WRITETERMINATOR) -
            %   Sets the Terminator property of the interface object to a cell
            %   array of {READTERMINATOR,WRITETERMINATOR}. It sets the
            %   Read Terminator to READTERMINATOR and the Write Terminator to
            %   WRITETERMINATOR for the interface object.
            %
            %   Input Arguments:
            %       TERMINATOR: The terminating character for all ASCII
            %       terminated communication. This sets both Read and Write
            %       Terminators to TERMINATOR.
            %       Accepted Values - Integers ranging from 0 to 255
            %                         "CR", "LF", "CR/LF"
            %
            %       READTERMINATOR: The read terminating character for all ASCII
            %       terminated communication. This sets the Read Terminator to
            %       READTERMINATOR.
            %       Accepted Values - Integers ranging from 0 to 255
            %                         "CR", "LF", "CR/LF"
            %
            %       WRITETERMINATOR: The write terminating character for all ASCII
            %       terminated communication. This sets the write Terminator to
            %       WRITETERMINATOR.
            %       Accepted Values - Integers ranging from 0 to 255
            %                         "CR", "LF", "CR/LF"
            %
            %   Example:
            %       % Set both read and write terminators to "CR/LF"
            %       configureTerminator(obj,"CR/LF")
            %
            %       % Set read terminator to "CR" and write terminator to
            %       % ASCII value of 10
            %       configureTerminator(obj,"CR",10)

            try
                narginchk(2, 3);
            catch
                obj.UserNotificationHandler.throwNarginErrorPlural('configureTerminator');
            end

            try
                if nargin == 2
                    % Set both read and write terminators to 'value'.
                    value = obj.validateTerminator(varargin{1});
                    obj.StringClient.Terminator = value;
                else
                    % Set the different terminator values.
                    readTerminator = obj.validateTerminator(varargin{1});
                    writeTerminator = obj.validateTerminator(varargin{2});
                    obj.StringClient.Terminator = {readTerminator writeTerminator};
                end
            catch
                ex = MException(message ...
                    ('transportlib:client:InvalidTerminator'));
                throw(obj.UserNotificationHandler.translateErrorId(ex));
            end
        end

        function writeline(obj, varargin)
            %WRITELINE Write ASCII data followed by the terminator to the
            % transport.
            %
            %   WRITELINE(OBJ,DATA) writes the ASCII data, DATA, followed
            %   by the terminator, to the transport.
            %
            %   Input Arguments:
            %       DATA is the ASCII data that is written to the transport. This
            %       DATA is always followed by the write terminator character(s).
            %
            %   Notes:
            %       WRITELINE waits until the ASCII DATA followed by terminator
            %       is written to the transport.
            %
            %   Example:
            %       % writes "*IDN?" and adds the terminator to the end of
            %       % the line before writing to the transport.
            %       writeline(obj,"*IDN?");

            try
                narginchk(2, 2);
            catch
                obj.UserNotificationHandler.throwNarginErrorSingular('writeline');
            end

            try
                data = varargin{1};
                write(obj.StringClient, data);
            catch ex
                throw(obj.UserNotificationHandler.translateErrorId(ex));
            end
        end

        function data = readbinblock(obj, varargin)
            %READBINBLOCK Read one binblock of data from the transport.
            %
            %   DATA = READBINBLOCK(OBJ) reads the binblock data as UINT8
            %   and represents them as a DOUBLE array in row format.
            %
            %   DATA = READBINBLOCK(OBJ,PRECISION) reads the binblock data as
            %   PRECISION type.For numeric PRECISION types DATA is
            %   represented as a DOUBLE array in row format.
            %   For char and string PRECISION types, DATA is
            %   represented as is.
            %
            %   Input Arguments:
            %       PRECISION indicates the number of bits read for each value
            %       and the interpretation of those bits as a MATLAB data type.
            %       DATATYPE must be one of "UINT8", "INT8", "UINT16",
            %       "INT16", "UINT32", "INT32", "UINT64", "INT64", "SINGLE",
            %       "DOUBLE", "CHAR", or "STRING".
            %
            %   Default PRECISION: 'UINT8'
            %
            %   Output Arguments:
            %       DATA is a 1xN matrix of numeric or ASCII data. If no data
            %       was returned this is an empty array.
            %
            %   Notes:
            %       READBINBLOCK waits until a binblock is read from the
            %       transport.
            %       READBINBLOCK REQUIRES INSTRUMENT CONTROL TOOLBOX™.
            %
            %   Example:
            %       % Reads the raw bytes in the binblock as uint8, and
            %       % represents them as a double array in row format.
            %       data = readbinblock(obj);
            %
            %       % Reads the raw bytes in the binblock as uint16, and
            %       % represents them as a double array in row format.
            %       data = readbinblock(obj,"uint16")

            try
                instrumentImpl = obj.getInstrumentImpl;
            catch
                ex = instrument.internal.InstrumentBaseClass.getLicenseRequiredMException ...
                    ("readbinblock", "transportlib:client:NoICTLicense");
                throw(obj.UserNotificationHandler.translateErrorId(ex));
            end

            try
                narginchk(1, 2);
            catch
                obj.UserNotificationHandler.throwNarginErrorPlural('readbinblock');
            end

            if nargin == 1
                precision = 'uint8';
            else
                precision = varargin{1};
            end

            try
                data = instrumentImpl.readbinblock(precision);
                data = obj.convertNumericToDouble(data, precision);
            catch ex
                if obj.ShowReadWarnings && ex.identifier == "transportclients:binblock:timeoutToken"
                    data = [];
                    obj.UserNotificationHandler.displayReadWarning(data, 'Readbinblock');
                else
                    throwAsCaller(ex);
                end
            end
        end

        function writebinblock(obj, varargin)
            %WRITEBINBLOCK Write a binblock of data to the transport.
            %
            %   WRITEBINBLOCK(OBJ,DATA,PRECISION) writes DATA to the transport
            %   using the binblock protocol (IEEE 488.2 Definite Length Arbitrary
            %   Block Response Data). The data is cast to the specified precision
            %   PRECISION regardless of the actual precision.
            %
            %   Input Arguments:
            %       DATA is a 1xN matrix of numeric or ASCII data that is
            %       written as a binblock to the transport.
            %
            %       PRECISION is of type "UINT8", "INT8", "UINT16",
            %       "INT16", "UINT32", "INT32", "UINT64", "INT64", "SINGLE",
            %       "DOUBLE", "CHAR", or "STRING".
            %
            %   Notes:
            %       WRITEBINBLOCK waits until the binblock DATA is written
            %       to the transport.
            %       WRITEBINBLOCK REQUIRES INSTRUMENT CONTROL TOOLBOX™.
            %
            %   Example:
            %       % Converts 1, 2, 3, 4, 5 to a binblock and writes it to
            %       % the transport as uint8.
            %       writebinblock(obj,1:5,"uint8");

            try
                instrumentImpl = obj.getInstrumentImpl;
            catch
                ex = instrument.internal.InstrumentBaseClass.getLicenseRequiredMException ...
                    ("writebinblock", "transportlib:client:NoICTLicense");
                throw(obj.UserNotificationHandler.translateErrorId(ex));
            end

            try
                narginchk(3, 4);
            catch
                obj.UserNotificationHandler.throwNarginErrorPlural('writebinblock');
            end

            try
                instrumentImpl.writebinblock(varargin{:});
            catch ex
                throwAsCaller(ex);
            end
        end

        function response = writeread(obj, varargin)
            %WRITEREAD Write ASCII-terminated string COMMAND to transport and
            % reads back an ASCII-terminated string RESPONSE.
            % This function can be used to query an instrument connected to
            % the transport.
            %
            %   RESPONSE = WRITEREAD(OBJ,COMMAND) writes the COMMAND
            %   followed by the write terminator to the transport. It reads
            %   back the RESPONSE from the transport, which is an ASCII
            %   terminated string, and returns the RESPONSE after removing
            %   the read terminator.
            %
            %   Input Arguments:
            %       COMMAND: The terminated ASCII data that is written to the
            %       transport
            %
            %   Output Arguments:
            %       RESPONSE: The terminated ASCII data that is returned back
            %       from the transport.
            %
            %   Notes:
            %       WRITEREAD waits until the ASCII-terminated COMMAND is written
            %       and an ASCII-terminated RESPONSE is retuned from the transport.
            %       WRITEREAD REQUIRES INSTRUMENT CONTROL TOOLBOX™.
            %
            %   Example:
            %       % Query the transport for a response by sending "IDN?"
            %       % command.
            %       response = writeread(obj,"*IDN?");

            try
                instrumentImpl = obj.getInstrumentImpl;
            catch
                ex = instrument.internal.InstrumentBaseClass.getLicenseRequiredMException ...
                    ("writeread", "transportlib:client:NoICTLicense");
                throw(obj.UserNotificationHandler.translateErrorId(ex));
            end

            try
                narginchk(2, 2);
            catch
                obj.UserNotificationHandler.throwNarginErrorSingular('writeread');
            end

            try
                command = varargin{1};
                response = instrumentImpl.writeread(command);
            catch ex
                throwAsCaller(ex);
            end
        end
    end

    %% Helper functions
    methods (Access = private)
        function data = convertNumericToDouble(~, data, precision)
            % This helper function represents numeric 'precision' type data
            % as double for any read operation.

            if precision ~= "string" && precision ~= "char"
                data = double(data);
            end
        end

        function instrumentImpl = getInstrumentImpl(obj)
            % Creates and returns the Instance of InstrumentImpl for all
            % Instrument Functionalities.

            % Create the InstrumentImpl instance only if not previously
            % created.
            if isempty(obj.InstrumentImpl)
                try
                    obj.InstrumentImpl = ...
                        instrument.internal.InstrumentImpl(obj.Transport, obj.StringClient);
                catch ex
                    throw(obj.UserNotificationHandler.translateErrorId(ex));
                end
            end
            instrumentImpl = obj.InstrumentImpl;
        end

        function value = validateTerminator(~, value)
            if ~isnumeric(value)
                validateattributes(value, {'char', 'string'}, {'nonempty'}, ...
                    mfilename, 'Terminator');
                value = validatestring(value, ["LF", "CR", "CR/LF"], mfilename, 'Terminator');
            else
                validateattributes(value, {'numeric'}, {'finite', 'scalar', 'nonempty', 'nonnegative', 'integer'}, ...
                    mfilename, "Terminator");
            end
        end
    end
end

