classdef (Abstract) LegacyBinblockMixin < matlabshared.transportlib.internal.compatibility.LegacyNullMixin
    %LEGACYBINBLOCKMIXIN Shared implementation of legacy support for binblock
    %operations (binblockread and binblockwrite).
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2021-2023 The MathWorks, Inc.

    %%#codegen    (CANNOT SUPPORT CODEGEN b/c of try-catch)
    
    % Binblock
    methods (Sealed, Hidden)
        function varargout = binblockread(obj, varargin)
            % BINBLOCKREAD will be removed in a future release. Use
            % readbinblock instead.
            %
            %BINBLOCKREAD Read binblock from instrument.
            %
            %   A=BINBLOCKREAD(OBJ) reads a binblock from the instrument connected
            %   to interface object, OBJ and returns the values to A.
            %
            %   BINBLOCKREAD blocks until one of the following occurs:
            %       1. The binblock is completely read.
            %       2. A timeout occurs as specified by the Timeout property.
            %
            %   A connected interface object has a Status property value of open.
            %
            %   A=BINBLOCKREAD(OBJ,'PRECISION') reads the binblock with the specified
            %   precision, PRECISION. The precision argument controls the number of
            %   bits read for each value and the interpretation of those bits as
            %   character, integer or floating point values. The supported PRECISION
            %   strings are defined below. By default the 'uchar' PRECISION is used.
            %   By default, numeric values are returned in double precision arrays.
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
            %   [A,COUNT]=BINBLOCKREAD(OBJ,...) returns the number of values read
            %   to COUNT.
            %
            %   [A,COUNT,MSG]=BINBLOCKREAD(OBJ,...) returns a message, MSG, if
            %   BINBLOCKREAD did not complete successfully. If MSG is not specified
            %   a warning is displayed to the command line.
            %
            %   Some instruments may send a terminating character after the binblock.
            %   BINBLOCKREAD will not read the terminating character. The terminating
            %   character can be read with the FREAD function. Additionally, if OBJ
            %   is a VISA object, the CLRDEVICE function can be used to remove the
            %   terminating character.
            %
            %   Example:
            %       vd = visadev("GPIB0::11::INSTR");
            %       fprintf(vd, "Curve?");
            %       data = binblockread(g);
            %
            %   See also READBINBLOCK, WRITEBINBLOCK

            narginchk(1, 2)
            
            obj.respondToLegacyCall()
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            switch nargin
                case 1
                    precision = 'uchar';
                case 2
                    precision = varargin{1};
            end

            precision = matlabshared.transportlib.internal.compatibility.Utility.convertLegacyPrecision(precision);
            data = readbinblock(obj, precision);
            numBytes = length(data);

            % Return column data
            if size(data, 2) > 1
                data = data';
            end

            % Calculate length of block header:
            %   The binblock is defined using the formula:
            %   #<Non_Zero_Digit><Digit><A>
            %
            %   where:
            %     Non_Zero_Digit represents the number of <Digit> elements that follow.
            %     Digit represents the number of bytes <A> that follow.
            %
            %   For example, if A was defined as:
            %   - [0 5 5 0 5 5 0], the binblock would be defined as
            %     [double('#') 1 7 0 5 5 0 5 5 0].
            %   - 1:10000 => [# 6 1 0 0 0 0 0 1 2 3 ...]

            getNumDigits = @(n) ceil(log10(max(n + 1, 1)));

            numDigits = getNumDigits(numBytes);
            numNonZeroDigits = getNumDigits(numDigits);
            lengthHeader = 1 + numNonZeroDigits + numDigits;

            varargout = {data, numBytes + lengthHeader, ''};
        end

        function binblockwrite(obj, varargin)
            % BINBLOCKWRITE will be removed in a future release. Use
            % writebinblock instead.
            %            
            %BINBLOCKWRITE Write binblock to instrument.
            %
            %   BINBLOCKWRITE(OBJ, A) writes a binblock using the data, A, to the
            %   instrument connected to interface object, OBJ.
            %
            %   A connected interface object has a Status property value of open.
            %
            %   BINBLOCKWRITE(OBJ,A,'PRECISION') writes binary data
            %   translating MATLAB values to the specified precision,
            %   PRECISION. The supported PRECISION strings are defined
            %   below. By default the 'uchar' PRECISION is used.
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
            %   BINBLOCKWRITE(OBJ,A,'HEADER') writes binary data
            %   translating MATLAB values to the default precision,
            %   'uchar'. The HEADER is prepended to the binblock before
            %   writing. The HEADER is of ASCII string type.
            %
            %   BINBLOCKWRITE(OBJ,A,'PRECISION','HEADER') writes binary
            %   data translating MATLAB values to the specified precision,
            %   PRECISION. The HEADER is prepended to the binblock before
            %   writing. The HEADER is of ASCII string type.
            %
            %   Example:
            %       vd = visadev("GPIB0::11::INSTR");
            %
            %       % Write the command: [uint8('#14') 0 5 0 5] to the instrument.
            %       binblockwrite(vd, [0 5 0 5]);
            %
            %       % Write the command: [uint8('#14') 0 5 0 5] to the instrument.
            %       % Append the header "Header" before the uint8('#14').
            %       % The default precision is 'uchar'.
            %       binblockwrite(vd, [0 5 0 5], "Header");
            %
            %       % Write the command: [uint8('#14') 0 5 0 5] to the 
            %       % instrument as "uint8" precision. Append the header
            %       % "Header" before the uint8('#14'). 
            %       binblockwrite(vd, [0 5 0 5], "uint8", "Header");
            %
            %   See also WRITEBINBLOCK, READBINBLOCK

            narginchk(2, 5)

            obj.respondToLegacyCall()
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            data = varargin{1};
            hasHeaderFormat = false;
            header = '';
            precision = "uint8";
            switch nargin
                case 3
                    precision = varargin{2};
                    try
                        precision = matlabshared.transportlib.internal.compatibility.Utility.convertLegacyPrecision(precision);
                    catch e %#ok<NASGU>
                        % If this errors out, it is because a header value
                        % was passed instead of a precision
                        precision = "uint8";
                        header = varargin{2};
                    end
                case 4
                    precision = varargin{2};
                    header = varargin{3};
                case 5
                    precision = varargin{2};
                    header = varargin{3};
                    hasHeaderFormat = true;
            end

            % Error checking.
            if ~(isnumeric(data) || ischar(data))
                error(message('instrument:binblockwrite:invalidA'));
            end

            % issue warning that header format will be ignored
            if hasHeaderFormat
                obj.sendWarning('transportlib:legacy:HeaderFormatNotSupported');
            end

            precision = matlabshared.transportlib.internal.compatibility.Utility.convertLegacyPrecision(precision);
            writebinblock(obj, data, precision, header);
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyBinblockMixin
            coder.allowpcode('plain');
        end
    end
end
