function varargout = scanstr(obj,varargin)
%SCANSTR Parse formatted data from instrument.
% 
%   A = SCANSTR(OBJ) reads formatted data from the instrument connected 
%   to interface object, OBJ and parses the data using both a comma and 
%   a semicolon delimiter and returns to cell array, A. Each element of  
%   the cell array is determined to be either a double or a string.
%
%   A = SCANSTR(OBJ, 'DELIMITER') reads data from the instrument connected 
%   to interface object, OBJ, and parses the string into separate variables 
%   based on the DELIMITER string and returns to cell array, A. The DELIMITER
%   can be a single character or a string array. If the DELIMITER is a string
%   array then each character in the array is used as a delimiter. By default, 
%   a comma and a semicolon DELIMITER is used. Each element of the cell array
%   is determined to be either a double or a string.
%
%   A = SCANSTR(OBJ, 'DELIMITER', 'FORMAT') reads data from the instrument 
%   connected to interface object, OBJ, and converts it according to the
%   specified FORMAT string. A may be a matrix or a cell array depending
%   on FORMAT. See the TEXTREAD on-line help for complete details.
%
%   FORMAT is a string containing C language conversion specifications. 
%   Conversion specifications involve the character % and the conversion 
%   characters d, i, o, u, x, X, f, e, E, g, G, c, and s. Refer to the 
%	SSCANF format specification section for more details.
%
%   If the FORMAT is not sepcified then the best format, either a double
%   or a string, is chosen.
%
%   [A,COUNT]=SCANSTR(OBJ,...) returns the number of values read to COUNT.
%
%   [A,COUNT,MSG]=SCANSTR(OBJ,...) returns a message, MSG, if SCANSTR
%   did not complete successfully. If MSG is not specified a warning is 
%   displayed to the command line. 
%
%   OBJ's ValuesReceived property will be updated by the number of values
%   read from the instrument including the terminator.
% 
%   If OBJ's RecordStatus property is configured to on with the RECORD
%   function, the data received will be recorded in the file specified
%   by OBJ's RecordName property value.
%
%   Example:
%       g = gpib('ni', 0, 2);
%       fopen(g);
%       fprintf(g, '*IDN?');
%       idn = scanstr(g, ',');
%       fclose(g);
%       delete(g);
%
%   See also ICINTERFACE/FOPEN, ICINTERFACE/FSCANF, ICINTERFACE/RECORD, 
%   INSTRHELP, SSCANF, STRREAD, TEXTREAD.

%   Copyright 1999-2017 The MathWorks, Inc. 

% Error checking.
if nargout > 3
   error(message('instrument:scanstr:invalidSyntaxRet'));
end  

if ~isa(obj, 'icinterface')
   error(message('instrument:scanstr:invalidOBJInterface'));
end	

if length(obj)>1
    error(message('instrument:scanstr:invalidOBJDim'));
end

% convert to char in order to accept string datatype
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
otherwise
    error(message('instrument:scanstr:invalidSyntaxArgv'));
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
        out=strread(dataValue,format,'delimiter',delimiter);
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
    warnState = warning('backtrace', 'off');
    % Restore the warning state.
    warning('instrument:scanstr:unsuccessfulRead', warningstr);
    warning(warnState);
end

varargout = {dataValue, count, warningstr};
end