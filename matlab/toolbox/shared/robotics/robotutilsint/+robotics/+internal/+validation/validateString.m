function varargout = validateString(str, allowempty, varargin)
%This function is for internal use only. It may be removed in the future.

%validateString Verify that input is a scalar text (or empty)
%   STRCHAR = robotics.internal.validation.validateString(STR, ALLOWEMPTY, ...)
%   checks if STR is a character array row-vector or a scalar string object.
%   If ALLOWEMPTY is false, it also checks that STR is nonempty.
%   All remaining arguments are passed on to VALIDATEATTRIBUTES after the
%   ATTRIBUTES argument.
%   The function always returns the string as character vector STRCHAR.

%   Copyright 2016-2023 The MathWorks, Inc.

%#codegen

    strChar = convertStringsToChars(str);

    if nargin < 2
        allowempty = false;
    end
    if allowempty && isempty(strChar)
        validateattributes(strChar, {'char','string'}, {}, varargin{:});
    else
        validateattributes(strChar, {'char','string'}, {'nonempty','row'}, varargin{:});
    end

    if nargout > 0
        varargout{1} = strChar;
    end

end
