classdef (Abstract) LegacyBinaryMixin < matlabshared.transportlib.internal.compatibility.LegacyNullMixin
    %LEGACYBINARYMIXIN Shared implementation of legacy support for binary
    %operations (fwrite and fread).
    %
    %    This undocumented class may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    %#codegen

    % Binary
    methods (Sealed, Hidden)
        function fwrite(obj, varargin)
            % FWRITE will be removed in a future release. Use write instead.
            %
            %FWRITE Write binary data to instrument.
            %
            %   FWRITE(OBJ, A) writes the data, A, to the instrument connected to
            %   interface object, OBJ.
            %
            %   A connected interface object has a Status property value of open.
            %
            %   FWRITE(OBJ,A,'PRECISION') writes binary data translating MATLAB
            %   values to the specified precision, PRECISION. The supported
            %   PRECISION strings are defined below. By default the 'uchar'
            %   PRECISION is used.
            %
            %      MATLAB           Description
            %      'uchar'          unsigned character,  8 bits.
            %      'schar'          signed character,    8 bits.
            %      'int8'           integer,             8 bits.
            %      'int16'          integer,             16 bits.
            %      'int32'          integer,             32 bits.
            %      'uint8'          unsigned integer,    8 bits.
            %      'uint16'         unsigned integer,    16 bits.
            %      'uint32'         unsigned integer,    32 bits.
            %      'single'         floating point,      32 bits.
            %      'float32'        floating point,      32 bits.
            %      'double'         floating point,      64 bits.
            %      'float64'        floating point,      64 bits.
            %      'char'           character,           8 bits (signed or unsigned).
            %      'short'          integer,             16 bits.
            %      'int'            integer,             32 bits.
            %      'long'           integer,             32 or 64 bits.
            %      'ushort'         unsigned integer,    16 bits.
            %      'uint'           unsigned integer,    32 bits.
            %      'ulong'          unsigned integer,    32 bits or 64 bits.
            %      'float'          floating point,      32 bits.
            %
            %   FWRITE(OBJ, A, 'MODE')
            %   FWRITE(OBJ, A, 'PRECISION', 'MODE') writes data synchronously (object
            %   is always in 'sync' mode, irrespective of setting, meaning control is
            %   returned to the MATLAB command line after the specified data has been
            %   written to the instrument or a timeout occurs). Explicitly setting this
            %   value shall result in a warning.
            %
            %   The byte order of the instrument can be specified with OBJ's ByteOrder
            %   property.
            %
            %   Example:
            %       vd = visadev("GPIB0::11::INSTR"); 
            %       fwrite(vd, [0 5 5 0 5 5 0]);
            %
            %   See also WRITE, READ
            %            
            obj.respondToLegacyCall()
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            narginchk(2,4)

            switch nargin
                case 2
                    data = varargin{1};
                    precision = 'uint8';
                case 3
                    % Original assumption: fwrite(obj, cmd, precision);
                    [data, precision] = deal(varargin{1:2});

                    if ~(isa(precision, 'char') || isa(precision, 'double'))
                        error(message('instrument:fwrite:invalidArg'));
                    end

                    if strcmpi(precision, 'sync') || strcmpi(precision, 'async')
                        % Actual: fwrite(obj, cmd, mode);
                        obj.sendWarning('transportlib:legacy:SyncNotSupported');
                        precision = 'uint8';
                    end
                case 4
                    % Ex. fwrite(obj, format, cmd, mode);
                    [data, precision] = deal(varargin{1:2});
                    obj.sendWarning('transportlib:legacy:SyncNotSupported');
            end

            if ~(isnumeric(data) || ischar(data))
                error(message('instrument:fwrite:invalidA'));
            end

            precision = matlabshared.transportlib.internal.compatibility.Utility.convertLegacyPrecision(precision);

            writeHook(obj, data, precision);
        end

        function varargout = fread(obj, varargin)
            % FREAD will be removed in a future release. Use read instead.
            %
            %FREAD Read binary data from instrument.
            %
            %   A=FREAD(OBJ) reads values from the instrument connected to
            %   interface object, OBJ, and returns to A. The maximum number
            %   of values is given by the InputBufferSize property.
            %
            %   A=FREAD(OBJ,SIZE) reads at most the specified number of values,
            %   SIZE, from the instrument connected to interface object, OBJ,
            %   and returns to A.
            %
            %   For serialport, VISA-serial, tcpclient, and tcpserver
            %   objects, FREAD blocks until one of the following occurs:
            %       1. InputBufferSize values have been received
            %       2. SIZE values have been received
            %       3. A timeout occurs as specified by the Timeout property
            %
            %   For VISA (all besides serial), FREAD blocks until one of
            %   the following occurs:
            %       1. InputBufferSize values have been received
            %       2. SIZE values have been received
            %       3. The terminator is received as specified by the Terminator
            %          property
            %       4. A timeout occurs as specified by the Timeout property.
            %
            %   For udpport objects, FREAD blocks until one of the following occurs:
            %       1. InputBufferSize values have been received
            %       2. SIZE values have been received (if DatagramTerminateMode is off)
            %       3. A datagram has been received (if DatagramTerminateMode is on)
            %       4. A timeout occurs as specified by the Timeout property
            %
            %   A connected interface object has a Status property value of open.
            %
            %   Available options for SIZE include:
            %
            %      N      read at most N values into a column vector.
            %      [M,N]  read at most M * N values filling an M-by-N matrix,
            %             in column order.
            %
            %   SIZE cannot be set to INF. If SIZE is greater than the
            %   OBJ's InputBufferSize property value an error will be
            %   returned. Note that SIZE is specified in values while the
            %   InputBufferSize is specified in bytes.
            %
            %   A=FREAD(OBJ,SIZE,'PRECISION') reads binary data with the
            %   specified precision, PRECISION. The precision argument
            %   controls the number of bits read for each value and the
            %   interpretation of those bits as character, integer or
            %   floating point values. The supported PRECISION strings are
            %   defined below. By default the 'uchar' PRECISION is used. By
            %   default, numeric values are returned in double precision
            %   arrays.
            %
            %      MATLAB           Description
            %      'uchar'          unsigned character,  8 bits.
            %      'schar'          signed character,    8 bits.
            %      'int8'           integer,             8 bits.
            %      'int16'          integer,             16 bits.
            %      'int32'          integer,             32 bits.
            %      'uint8'          unsigned integer,    8 bits.
            %      'uint16'         unsigned integer,    16 bits.
            %      'uint32'         unsigned integer,    32 bits.
            %      'single'         floating point,      32 bits.
            %      'float32'        floating point,      32 bits.
            %      'double'         floating point,      64 bits.
            %      'float64'        floating point,      64 bits.
            %      'char'           character,           8 bits (signed or unsigned).
            %      'short'          integer,             16 bits.
            %      'int'            integer,             32 bits.
            %      'long'           integer,             32 or 64 bits.
            %      'ushort'         unsigned integer,    16 bits.
            %      'uint'           unsigned integer,    32 bits.
            %      'ulong'          unsigned integer,    32 bits or 64 bits.
            %      'float'          floating point,      32 bits.
            %
            %   [A,COUNT]=FREAD(OBJ,...) returns the number of values read to COUNT.
            %
            %   [A,COUNT,MSG]=FREAD(OBJ,...) returns a message, MSG, if
            %   FREAD did not complete successfully. If MSG is not
            %   specified a warning is displayed to the command line.
            %
            %   [A,COUNT,MSG,DATAGRAMADDRESS]=FREAD(OBJ,...) returns the
            %   datagram address to DATAGRAMADDRESS, if OBJ is a UDP
            %   object. If more than one datagram is read, DATAGRAMADDRESS
            %   is ''.
            %
            %   [A,COUNT,MSG,DATAGRAMADDRESS,DATAGRAMPORT]=FREAD(OBJ,...)
            %   returns the datagram port to DATAGRAMPORT, if OBJ is a UDP
            %   object. If more than one datagram is read, DATAGRAMPORT is
            %   [].
            %
            %   The byte order of the instrument can be specified with OBJ's
            %   ByteOrder property.
            %
            %   Example:
            %       vd = visadev("GPIB0::11::INSTR"); 
            %       fprintf(vd, 'Curve?');
            %       data = fread(vd, 512);
            %
            %   See also READ, WRITE

            obj.respondToLegacyCall()
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            % Parse the input.
            switch nargin
                case 1
                    numToRead = obj.InputBufferSize; % get(obj, 'InputBufferSize');
                    precision = "uint8"; % 'uchar';
                case 2
                    numToRead = varargin{1};
                    precision = "uint8";
                case 3
                    [numToRead, precision] = deal(varargin{:});
                otherwise
                    error(message('MATLAB:serial:fread:invalidSyntaxArgv'));
            end

            % validate size
            obj.NumToRead = numToRead;
            [precision, datasize] = matlabshared.transportlib.internal.compatibility.Utility.convertLegacyPrecision(precision);

            % Determine the total number of elements to read.
            switch length(numToRead)
                case 1
                    numRows = numToRead;
                    numCols = 1;
                case 2
                    numRows = numToRead(1);
                    numCols = numToRead(2);
                otherwise
                    error(message('MATLAB:serial:fread:invalidSIZE'));
            end

            % error if size * numelements > inputBufferSize
            numRead = numRows * numCols;
            if datasize * numRead > obj.InputBufferSize
                throw(obj.getInputBufferSizeExceededException('instrument:fread:opfailed'));                
            end

            data = readHook(obj, numRead, precision);

            % If data is:
            % - empty, then warn
            % - available, then convert the data, as needed, and then
            %   package (and reshape) it
            if isempty(data)            
                warningstr = lastwarn;
            else
                warningstr = '';

                if ~isa(data(1), 'double')
                    data = obj.convertReadDataHook(data);
                end
            end

            varargout = obj.packageReadDataHook(data, numRead, warningstr, numRows, numCols);
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyBinaryMixin
            coder.allowpcode('plain');
        end
    end

    methods (Access = protected)
        function writeHook(obj, data, precision)
            write(obj, data, precision);
        end

        function data = readHook(obj, numRead, precision)
            data = read(obj, numRead, precision);
        end

        function dataOut = convertReadDataHook(obj, dataIn) %#ok<INUSL> 
            % tcpclient returns uint8 data
            dataOut = double(dataIn);
        end

        function out = packageReadDataHook(obj, data, numRead, warningstr, numRows, numCols) %#ok<INUSL>            
            if isempty(warningstr)
                if numRows > 1 && numCols > 1
                    data = reshape(data, numRows, numCols);
                elseif isrow(data)
                    data = data';
                end
            end

            out = {data, numRead, warningstr};
        end
    end    
end