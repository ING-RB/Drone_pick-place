function varargout = binblockread(obj, varargin)
%BINBLOCKREAD Read binblock from instrument.
%
%   A=BINBLOCKREAD(OBJ) reads a binblock from the instrument connected
%   to interface object, OBJ and returns the values to A.
%
%   The binblock is defined using the formula:
%   #<Non_Zero_Digit><Digit><A>
%
%   where:
%     Non_Zero_Digit represents the number of <Digit> elements that follow.
%     Digit represents the number of bytes <A> that follow.
%
%   For example, if A was defined as [0 5 5 0 5 5 0], the binblock would
%   be defined as [double('#') 1 7 0 5 5 0 5 5 0].
%
%   BINBLOCKREAD blocks until one of the following occurs:
%       1. The binblock is completely read.
%       2. A timeout occurs as specified by the Timeout property.
%
%   The interface object must be connected to the instrument with
%   the FOPEN function before any data can be read from the instrument
%   otherwise an error is returned. A connected interface object
%   has a Status property value of open.
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
%   OBJ's ValuesReceived property will be updated by the number of
%   values read from the instrument.
%
%   If OBJ's RecordStatus property is configured to on with the RECORD
%   function, the data received will be recorded in the file specified
%   by OBJ's RecordName property value.
%
%   Some instruments may send a terminating character after the binblock.
%   BINBLOCKREAD will not read the terminating character. The terminating
%   character can be read with the FREAD function. Additionally, if OBJ
%   is a GPIB, VISA-GPIB, VISA-VXI, VISA-USB or VISA-RSIB object, the
%   CLRDEVICE function can be used to remove the terminating character.
%
%   UDP BINBLOCKREAD and BINBLOCKWRITE will be removed in a future
%   release.  Use a more reliable interface such as TCPIP for binblocks.

%
%   Example:
%       g = gpib('iotech', 1, 2);
%       fopen(g);
%       fprintf(g, 'Curve?');
%       data = binblockread(g);
%       fclose(g);
%
%   See also CLRDEVICE, ICINTERFACE/FOPEN, ICINTERFACE/FCLOSE,
%   ICINTERFACE/BINBLOCKWRITE, ICINTERFACE/FREAD, ICINTERFACE/RECORD,
%   INSTRUMENT/PROPINFO, INSTRHELP.

%   Copyright 1999-2018 The MathWorks, Inc.

% License checking.
[s,m] = license('checkout','Instr_Control_Toolbox');
if ~isequal(s,1) || ~isempty(m)
    throwAsCaller(MException(message('instrument:Interface:noICT',mfilename)));
end

% Error checking.

if nargout > 3
    error(message('instrument:binblockread:invalidSyntaxRet'));
end

if ~isa(obj, 'icinterface')
    error(message('instrument:binblockread:invalidOBJInterface'));
end

if length(obj)>1
    error(message('instrument:binblockread:invalidOBJDim'));
end

% convert to char in order to accept string datatype
varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

% Parse the input.
switch nargin
    case 1
        precision = 'uchar';
    case 2
        precision = varargin{1};
    otherwise
        error(message('instrument:binblockread:invalidSyntaxArgv'));
end

% Error checking.
if ~isa(precision, 'char')
    error(message('instrument:binblockread:invalidPRECISIONstring'));
end

% Define the type of data to be read.
switch precision
    case {'uchar', 'char'}
        type = 5;
        signed = 0;
    case 'schar'
        type = 5;
        signed = 1;
    case 'int8'
        type = 0;
        signed = 1;
    case {'int16', 'short'}
        type = 1;
        signed = 1;
    case {'int32', 'int', 'long'}
        type = 2;
        signed = 1;
    case 'uint8'
        type = 0;
        signed = 0;
    case {'uint16', 'ushort'}
        type = 1;
        signed = 0;
    case {'uint32', 'uint', 'ulong'}
        type = 2;
        signed = 0;
    case {'single', 'float32', 'float'}
        type = 3;
        signed = 1;
    case {'double' ,'float64'}
        type = 4;
        signed = 1;
    otherwise
        error(message('instrument:binblockread:invalidPRECISION'));
end

% The Terminating character needs to be disabled for VISA Generic Object
% binary reads otherwise a binary read will end when a LF or CR was
% encountered. This may have been a firmware bug.
if strcmp(obj.jobject.Type,'visa-generic')
    OldEOSMode = obj.jobject.EOSMode;
    obj.jobject.EOSMode = 'none';
end

% Call the binblockread java method.
try
    % Out contains the data and the number of data ready.
    out = binblockread(igetfield(obj, 'jobject'), type, signed);
catch aException
    % Restore the VISA Generic object's terminating character.
    if strcmp(obj.jobject.Type,'visa-generic')
        obj.jobject.EOSMode = OldEOSMode;
    end
    newExc = MException('instrument:binblockread:opfailed', aException.message);
    throw(newExc);
end

% Restore the VISA Generic object's terminating character.
if strcmp(obj.jobject.Type,'visa-generic')
    obj.jobject.EOSMode = OldEOSMode;
end

% Parse the result from the java binblockread method.
data = out(1);
numRead = out(2);
warningstr = out(3);

% Transpose data.
if size(data, 2) > 1
    data = data';
end

try
    switch precision
        case {'uint8', 'uchar', 'char'}
            data = double(data);
            data = data + (data<0).*256;
        case {'uint16', 'ushort'}
            data = double(data);
            data = data + (data<0).*65536;
        case {'uint32', 'uint', 'ulong'}
            data = double(data);
            data = data + (data<0).*(2^32);
        case {'int8', 'schar'}
            data = double(data);
            data = data - (data>127)*256;
        otherwise
            data = double(data);
    end

    % Data was successfully read and formatted.  Return the formatted
    % data, the number of values read and any errors that occurred
    % in the java code.

catch
    % An error occurred. Return the data as an array.
    data = double(data);
end

% Warn if the MSG output variable is not specified.
if ~isempty(warningstr)
    % Store the warning state.
    warnState = warning('backtrace', 'off');
    if isempty(data)
        warningstr = instrument.internal.warningMessagesHelpers.getReadWarning(warningstr, obj.class, obj.DocIDNoData, 'nodata');
    else
        warningstr = instrument.internal.warningMessagesHelpers.getReadWarning(warningstr, obj.class, obj.DocIDSomeData, 'somedata');
    end

    if nargout < 3
        warning('instrument:binblockread:unsuccessfulRead', warningstr);
    end

    % Restore the warning state.
    warning(warnState);
end
varargout = {data, numRead, warningstr};

