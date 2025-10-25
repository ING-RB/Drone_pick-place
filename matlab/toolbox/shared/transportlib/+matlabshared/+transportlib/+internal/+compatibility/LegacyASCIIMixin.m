classdef (Abstract) LegacyASCIIMixin < matlabshared.transportlib.internal.compatibility.LegacyNullMixin
    %LEGACYASCIIMIXIN Shared implementation of legacy support for ASCII
    %operations (fprintf, fscanf, fgetl, fgets, and scanstr).
    %
    %    This undocumented class may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    %%#codegen    (CANNOT SUPPORT CODEGEN b/c of try-catch)

    % ASCII
    methods (Sealed, Hidden)
        function fprintf(obj, varargin)
            % FPRINTF will be removed in a future release. Use writeline
            % instead.
            %
            %FPRINTF Write text to instrument.
            %
            %   FPRINTF(OBJ,'CMD') writes the string, CMD, to the
            %   instrument connected to interface object, OBJ. OBJ must be
            %   a 1-by-1 interface object.
            %
            %   A connected interface object has a Status property value of
            %   open.
            %
            %   FPRINTF(OBJ,'FORMAT','CMD') writes the string CMD, to the
            %   instrument connected to interface object, OBJ, with the
            %   format, FORMAT. By default, the %s\n FORMAT string is used.
            %   The SPRINTF function is used to format the data written to
            %   the instrument.
            %
            %   For all interfaces, each occurrence of \n in CMD is
            %   replaced with OBJ's Terminator property value. When using
            %   the default FORMAT, %s\n, all commands written to the
            %   instrument will end with the Terminator value.
            %
            %   FORMAT is a string containing C language conversion
            %   specifications. Conversion specifications involve the
            %   character % and the conversion characters d, i, o, u, x, X,
            %   f, e, E, g, G, c, and s. Refer to the
            %	SPRINTF format specification section for more details.
            %
            %   FPRINTF(OBJ, 'CMD', 'MODE') FPRINTF(OBJ, 'FORMAT', 'CMD',
            %   'MODE') By default, the data is written with the 'sync'
            %   MODE, meaning control is returned to the MATLAB command
            %   line after the specified data has been written to the
            %   instrument or a timeout occurs. Explicitly setting this
            %   value shall result in a warning.
            %
            %   Example:
            %       s = serialport("COM1");
            %       fprintf(s, 'Freq 2000');
            %
            %   See also WRITELINE

            narginchk(2, 4)

            obj.respondToLegacyCall()
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            % Parse the input.
            switch nargin
                case 2
                    % Ex. fprintf(obj, cmd);
                    cmd = varargin{1};
                    format = '%s\n';
                case 3
                    % Original assumption: fprintf(obj, format, cmd);
                    [format, cmd] = deal(varargin{1:2});
                    if ~(isa(cmd, 'char') || isa(cmd, 'double'))
                        error(message('MATLAB:serial:fprintf:invalidArg'));
                    end

                    if strcmpi(cmd, 'sync') || strcmpi(cmd, 'async')
                        % Actual: fprintf(obj, cmd, mode);
                        % warn user that we ignore the 'mode' command
                        % mode = 0;
                        cmd = format;
                        format = '%s\n';
                        obj.sendWarning('transportlib:legacy:SyncNotSupported');
                    end

                    if any(strcmp(format, {'%c', '%s'}))
                        % Check if cmd contains elements greater than one byte.
                        if any(cmd(:) > 255)
                            % Turn off backtrace momentarily and warn user
                            warning('off', 'backtrace');
                            warning(message('MATLAB:serial:fprintf:DataGreaterThanOneByte'));
                            warning('on', 'backtrace');
                            % Upper limit of cmd values should be 255.
                            cmd(cmd > 255) = 255;
                        end
                    end
                case 4
                    % Ex. fprintf(obj, format, cmd, mode);
                    [format, cmd] = deal(varargin{1:2});
                    % warn user that we ignore the 'mode' command
                    obj.sendWarning('transportlib:legacy:SyncNotSupported');
            end

            % validate format
            obj.Format = format;

            isCmdChar = isa(cmd, 'char');
            isCmdDouble = isa(cmd, 'double');

            if ~(isCmdChar || isCmdDouble)
                error(message('MATLAB:serial:fprintf:invalidCMD'));
            end

            % If command is a character vector, replace any newline
            % characters contained with terminator characters.
            if isCmdChar && contains(cmd, '\n')
                t = obj.getTerminator("write");

                switch char(t)
                    case 'LF'
                        % do nothing: leave '\n'
                        cmd = sprintf(cmd);
                    case 'CR'
                        cmd = sprintf(replace(cmd, '\n', '\r'));
                    case 'CR/LF'
                        cmd = sprintf(replace(cmd, '\n', '\r\n'));
                    otherwise
                        cmd = replace(sprintf(cmd), newline, char(t));
                end
            end

            % format command
            % - Non-terminated commands should call write.
            % - Terminated decimal values should not contain the final
            % terminator (sent via writeline)

            formattedCmd = sprintf(format, cmd);

            % If format ends in '\n', call writeline.
            if endsWith(format, '\n')
                % Remove the final '\n' from double-valued commands.
                formattedCmd = extractBefore(formattedCmd, strlength(formattedCmd));
                writeline(obj, formattedCmd);
            else
                write(obj, formattedCmd, "char");
            end
        end

        function varargout = fscanf(obj, varargin)
            % FSCANF will be removed in a future release. Use readline
            % instead.
            %
            %FSCANF Read data from instrument and format as text.
            %
            %   A=FSCANF(OBJ) reads data from the instrument connected to instrument
            %   object, OBJ, and formats the data as text and returns to A.
            %
            %   For serialport, visadev, tcpclient, and tcpserver objects,
            %   FSCANF blocks until one of the following occurs:
            %       1. The terminator is received as specified by the
            %       Terminator property.
            %       2. A timeout occurs as specified by the Timeout
            %       property. 
            %       3. The input buffer is filled.
            %
            %   For udpport objects, FSCANF blocks until one of the
            %   following occurs:
            %       1. The terminator is received as specified by the
            %       terminator property (if DatagramTerminateMode is off).
            %       2. A timeout occurs as specified by the Timeout
            %       property.
            %
            %   For all interface objects, the terminator is defined by
            %   setting the Terminator property.
            %
            %   A=FSCANF(OBJ,'FORMAT') reads data from the instrument
            %   connected to interface object, OBJ, and converts it
            %   according to the specified FORMAT string. By default, the
            %   %c FORMAT string is used. The SSCANF function is used to
            %   format the data read from the instrument.
            %
            %   FORMAT is a string containing C language conversion
            %   specifications. Conversion specifications involve the
            %   character % and the conversion characters d, i, o, u, x, X,
            %   f, e, E, g, G, c, and s. Refer to the
            %	SSCANF format specification section for more details.
            %
            %   A=FSCANF(OBJ,'FORMAT',SIZE) reads the specified number of
            %   values, SIZE, from the instrument connected to interface
            %   object, OBJ.
            %
            %   For serialport, visadev, tcpclient, and tcpserver objects,
            %   FSCANF blocks until one of the following occurs:
            %       1. The terminator is received as specified by the
            %       Terminator property.
            %       2. A timeout occurs as specified by the Timeout
            %       property. 
            %       3. SIZE values have been received.
            %
            %   For udpport objects, FSCANF blocks until one of the
            %   following occurs:
            %       1. SIZE values have been received (if
            %       DatagramTerminateMode if off).
            %       2. The terminator is received as specified by the
            %       Terminator property (if DatagramTerminateMode is off).
            %       3. A timeout occurs as specified by the Timeout
            %       property.
            %
            %   Available options for SIZE include:
            %
            %      N      read at most N values into a column vector. 
            %      [M,N]  read at most M * N values filling an M-by-N
            %             matrix, in column order.
            %
            %   SIZE cannot be set to INF. If SIZE is greater than OBJ's
            %   InputBufferSize property value an error will be returned.
            %
            %   If the matrix A results from using character conversions
            %   only and SIZE is not of the form [M,N] then a row vector is
            %   returned.
            %
            %   [A,COUNT]=FSCANF(OBJ,...) returns the number of values read
            %   to COUNT.
            %
            %   [A,COUNT,MSG]=FSCANF(OBJ,...) returns a message, MSG, if
            %   FSCANF did not complete successfully. If MSG is not
            %   specified a warning is displayed to the command line.
            %   Examples:
            %       vd = visadev("ASRL1::INSTR");
            %       fprintf(vd, "*IDN?");
            %       idn = fscanf(vd);
            %
            %   See also READLINE

            narginchk(1, 3)

            obj.respondToLegacyCall()
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            % Parse the input.
            switch nargin
                case 1
                    % Ex. fscanf(obj);
                    % Use readline
                    format = '%c';
                    numRequested = 0;
                    totalValuesToRead = obj.InputBufferSize;
                case 2
                    % Ex. fscanf(obj, format);
                    % use readline
                    format = varargin{1};
                    numRequested = 0;
                    totalValuesToRead = obj.InputBufferSize;
                case 3
                    % Ex. fscanf(obj, format, size);
                    % use read (this isn't strictly correct because the
                    % read should stop if a terminator is received)
                    [format, numRequested] = deal(varargin{1:2});
                    % validate size
                    obj.NumToRead = numRequested;

                    switch length(numRequested)
                        case 1
                            totalValuesToRead = numRequested;
                        case 2
                            totalValuesToRead = prod(numRequested);
                        otherwise
                            error(message('instrument:fscanf:invalidSIZE'));
                    end
            end

            % validate format
            obj.Format = format;

            % 1. Call readline, which will block until either
            %    a. A timeout occurs (warning / no data returned)
            %    b. A terminator is found
            % 2. If a terminator is found, format the data read and return
            %    it
            % 3. If a terminator is not found, read available samples and
            %    return them.

            warningState = warning('off','backtrace');
            serialReadlineWarningState = warning('off', 'serialport:serialport:ReadlineWarning');
            readlineWarningState = warning('off', 'transportlib:client:ReadlineWarning');
            oc1 = onCleanup(@() warning(warningState));
            oc2 = onCleanup(@() warning(serialReadlineWarningState));
            oc3 = onCleanup(@() warning(readlineWarningState));

            % If size is specified, then we don't need the current
            % timeout: just check whether there's terminated data
            % available.
            %
            % If size is not specified (*numRequested* is 0),
            % then honor the current timeout.

            timeout = obj.Timeout;

            % The duration of this timeout should be selected by the
            % interface (Serialport might need 100 ms).
            if numRequested ~= 0
                obj.Timeout = obj.getFscanfMinTimeout();
            end

            % normally, readline can warn, but is not expected to throw an
            % error (this warning is disabled, so warnings are not expected
            % either)
            data = readline(obj);

            if ~isempty(data)
                % format any available data
                t = obj.getTerminator();

                switch char(t)
                    case 'off'
                        % If EOSMode is none or write, then there is no
                        % terminator defined for read operations. In this
                        % case, do not modify the data                    
                    case 'LF'
                        data = compose("%s\n", data);
                    case 'CR'
                        data = compose("%s\r", data);
                    case 'CR/LF'
                        data = compose("%s\r\n", data);
                end
            else
                % readline timed out (no data was returned)
                try
                    data = read(obj, totalValuesToRead, "char");
                catch e
                    % tcpclient can throw
                    throwAsCaller(e)
                end
            end

            obj.Timeout = timeout;

            % empty data indicates that the read timed out, possibly with a
            % warning
            if isempty(data)                
                [wmsg, wid] = lastwarn;
                if ~isempty(wid)
                    error(wid, wmsg)
                end
            end

            if numRequested == 0
                [scanData, scanCount, scanErrMsg] = sscanf(data, format);
            else
                [scanData, scanCount, scanErrMsg] = sscanf(data, format, numRequested);
            end

            if isempty(scanErrMsg)
                outputData = scanData;
                outputCount = scanCount;
            else
                if isempty(scanData)
                    outputData = data;
                    outputCount = length(data);
                else
                    outputData = scanData;
                    outputCount = scanCount;
                end
            end

            outputMessage = '';
            varargout = obj.packageScanDataHook(outputData, outputCount, outputMessage);
        end

        function varargout = fgetl(obj)
            % FGETL will be removed in a future release. Use readline
            % instead.
            %
            %FGETL Read one line of text from instrument, discard
            %terminator.
            %
            %   TLINE=FGETL(OBJ) reads one line of text from the instrument
            %   connected to interface object, OBJ and returns to TLINE.
            %   The returned data does not include the terminator with the
            %   text line. To include the terminator, use FGETS.
            %
            %   For serialport, visadev, tcpclient, and tcpserver objects,
            %   FGETL blocks until one of the following occurs:
            %       1. The terminator is received as specified by the
            %       Terminator property
            %       2. A timeout occurs as specified by the Timeout
            %       property 
            %       3. The input buffer is filled
            %
            %   For udpport objects, FGETL blocks until one of the
            %   following occurs:
            %       1. The terminator is received as specified by the
            %       terminator property (DatagramTerminateMode is always
            %       off).
            %       2. A timeout occurs as specified by the Timeout
            %       property.
            %
            %   A connected interface object has a Status property value of
            %   open.
            %
            %   [TLINE,COUNT]=FGETL(OBJ) returns the number of values read
            %   to COUNT. COUNT includes the terminator.
            %
            %   [TLINE,COUNT,MSG]=FGETL(OBJ) returns a message, MSG, if
            %   FGETL did not complete successfully. If MSG is not
            %   specified a warning is displayed to the command line.
            %
            %   Examples:
            %       vd = visadev("GPIB0::11::INSTR"); 
            %       fprintf(vd, "*IDN?");
            %       idn = fgetl(vd);
            %
            %   See also READLINE, WRITELINE

            obj.respondToLegacyCall()
            [data, count, msg] = readlineWithCount(obj);

            % If any data was returned, then the count returned must
            % account for the terminator characters.
            if count > 0
                switch char(obj.getTerminator())
                    case {'LF', 'CR'}
                        numTermChars = 1;
                    case 'CR/LF'
                        numTermChars = 2;
                    case 'off'
                        % If EOSMode is none or write, then there is no
                        % terminator defined for read operations. 
                        numTermChars = 0;
                    otherwise
                        numTermChars = 1;
                end

                count = count + numTermChars;
            end

            varargout = {data, count, msg};
        end

        function varargout = fgets(obj)
            % FGETS will be removed in a future release. Use readline
            % instead.
            %            
            %FGETS Read one line of text from instrument, keep terminator.
            %
            %   TLINE=FGETS(OBJ) reads one line of text from the instrument
            %   connected to interface object, OBJ and returns to TLINE.
            %   The returned data does include the terminator with the text
            %   line. To exclude the terminator, use FGETL.
            %
            %   For serialport, visadev, tcpclient, and tcpserver objects,
            %   FGETS blocks until one of the following occurs:
            %       1. The terminator is received as specified by the
            %       Terminator
            %          property
            %       2. A timeout occurs as specified by the Timeout
            %       property 3. The input buffer is filled
            %
            %   For udpport objects, FGETS blocks until one of the
            %   following occurs:
            %       1. The terminator is received as specified by the
            %       terminator
            %          property (DatagramTerminateMode is always off).
            %       2. A timeout occurs as specified by the Timeout
            %       property.
            %
            %   A connected interface object has a Status property value of
            %   open.
            %
            %   [TLINE,COUNT]=FGETS(OBJ) returns the number of values read
            %   to COUNT. COUNT includes the terminator.
            %
            %   [TLINE,COUNT,MSG]=FGETS(OBJ) returns a message, MSG, if
            %   FGETS did not complete successfully. If MSG is not
            %   specified a warning is displayed to the command line."
            %
            %   Examples:
            %       vd = visadev("GPIB0::11::INSTR");
            %       fprintf(vd, "*IDN?");
            %       idn = fgets(vd);
            %
            %   See also READLINE, WRITELINE

            obj.respondToLegacyCall()
            [data, count, msg] = readlineWithCount(obj);

            if count > 0
                t = obj.getTerminator();
                switch char(t)
                    case 'off'
                        % If EOSMode is none or write, then there is no
                        % terminator defined for read operations. In this
                        % case, do not modify the data
                    case 'LF'
                        data = sprintf('%s\n', data);
                    case 'CR'
                        data = sprintf('%s\r', data);
                    case 'CR/LF'
                        data = sprintf('%s\r\n', data);
                    otherwise
                        data = sprintf('%s%c', data, char(t));
                end

                count = length(data);
            end

            varargout = {data, count, msg};
        end

        function varargout = scanstr(obj, varargin)
            % SCANSTR will be removed in a future release. Use readline
            % and textscan instead.
            %
            %SCANSTR Parse formatted data from instrument.
            %
            %   A = SCANSTR(OBJ) reads formatted data from the instrument
            %   connected to interface object, OBJ and parses the data
            %   using both a comma and a semicolon delimiter and returns to
            %   cell array, A. Each element of the cell array is determined
            %   to be either a double or a string.
            %
            %   A = SCANSTR(OBJ, 'DELIMITER') reads data from the
            %   instrument connected to interface object, OBJ, and parses
            %   the string into separate variables based on the DELIMITER
            %   string and returns to cell array, A. The DELIMITER can be a
            %   single character or a string array. If the DELIMITER is a
            %   string array then each character in the array is used as a
            %   delimiter. By default, a comma and a semicolon DELIMITER is
            %   used. Each element of the cell array is determined to be
            %   either a double or a string.
            %
            %   A = SCANSTR(OBJ, 'DELIMITER', 'FORMAT') reads data from the
            %   instrument connected to interface object, OBJ, and converts
            %   it according to the specified FORMAT string. A may be a
            %   matrix or a cell array depending on FORMAT. See the
            %   TEXTREAD on-line help for complete details.
            %
            %   FORMAT is a string containing C language conversion
            %   specifications. Conversion specifications involve the
            %   character % and the conversion characters d, i, o, u, x, X,
            %   f, e, E, g, G, c, and s. Refer to the
            %	SSCANF format specification section for more details.
            %
            %   If the FORMAT is not specified then the best format, either
            %   a double or a string, is chosen.
            %
            %   Example:
            %       vd = visadev("GPIB0::11::INSTR"); 
            %       fprintf(vd, "*IDN?");
            %       idn = scanstr(vd, ',');
            %
            %   See also READLINE, TEXTSCAN

            narginchk(1, 3)
            nargoutchk(0, 3)

            if length(obj) > 1
                error(message('instrument:scanstr:invalidOBJDim'));
            end

            obj.respondToLegacyCall()
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            % Parse the input.
            switch nargin
                case 1
                    delimiter = ',;';
                    format = '%s';
                case 2
                    delimiter = varargin{1};
                    format = '%s';
                case 3
                    [delimiter, format] = deal(varargin{1:2});
            end

            % Error checking.
            if ~ischar(delimiter)
                error(message('instrument:scanstr:invalidDELIMITER'));
            end

            if ~ischar(format)
                error(message('instrument:scanstr:invalidFORMAT'));
            end

            % Read the data.
            [dataValue, count, warningstr] = fscanf(obj, '%c');

            if ~isempty(dataValue)
                % Parse the data.
                try
                    out = strread(dataValue,format,'delimiter',delimiter); %#ok<DSTRRD>
                    if nargin < 3
                        for i = 1:length(out)
                            if ~isnan(str2double(out{i}))
                                out{i} = str2double(out{i});
                            end
                        end
                    end
                catch aException
                    out = dataValue;
                    warningstr = aException.message;
                end
                dataValue = out;
            end

            if nargout < 3 && ~isempty(warningstr)
                warnState = warning('backtrace', 'off'); %#ok<NASGU>
                oc1 = onCleanup(@() warning(warningState));
                % Restore the warning state.
                warning('instrument:scanstr:unsuccessfulRead', warningstr);
            end
            varargout = {dataValue, count, warningstr};
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyASCIIMixin
            coder.allowpcode('plain');
        end
    end

    methods (Access = protected)
        function out = packageScanDataHook(obj, outputData, outputCount, outputMessage) %#ok<INUSL>
            out = {outputData, outputCount, outputMessage};
        end

        function timeout = getFscanfMinTimeout(obj)
            timeout = 0.100;
        end
    end

    methods (Access = private)
        function [data, count, msg] = readlineWithCount(obj)
            data = readline(obj);

            % if timeout occurs, the data is empty
            if isempty(data)
                count = 0;
                msg = lastwarn;
            else
                count = strlength(data);
                msg = '';
            end

            data = char(data);
        end
    end
end