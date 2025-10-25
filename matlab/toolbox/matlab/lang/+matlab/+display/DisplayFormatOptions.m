classdef (Sealed) DisplayFormatOptions
% matlab.display.DisplayFormatOptions Display-related format settings
%
% f = matlab.display.DisplayFormatOptions constructs a format options
% object with current values of the display-related format settings.
%
% f = matlab.display.DisplayFormatOptions("NumericFormat", formatValue)
% constructs a format options object with the specified numeric display
% format.  The formatValue must be a valid numeric display format.
%
% f = matlab.display.DisplayFormatOptions(...,"LineSpacing", spacingValue)
% constructs a format options object with the specified line spacing.  The
% lineSpacing must be one of "loose" or "compact".
%
% Objects of the DisplayFormatOptions class are returned by the format
% function to describe the current display-related formatting options, and
% can be passed as input into the format function to specify new formatting
% options.
%
% Example 1:
% >> currentFormat = format;
%
% Example 2:
% >> newFormat = matlab.display.DisplayFormatOptions("NumericFormat",...
%        "longEng", "LineSpacing","compact");
% >> currentFormat = format(newFormat);
%
% DisplayFormatOptions properties:
%    NumericFormat - The format used to display numeric values
%    LineSpacing   - The amount of spacing that appears in the
%                    display output
%
% See also format

% Copyright 2020 The MathWorks, Inc.
    properties
        % NumericFormat describes the format used to display numeric values
        NumericFormat string {mustBeMember(NumericFormat, ["short",...
            "long", "shortE", "longE", "shortG", "longG", "shortEng",...
            "longEng", "bank", "rational", "hex", "+", "debug"])};

        % LineSpacing describes the amount of spacing that appears in the
        % display output
        LineSpacing string {mustBeMember(LineSpacing, ["loose",...
            "compact"])};
    end
    methods
        function obj = DisplayFormatOptions(namedArgs)
        % Constructor that accepts up to 2 named-arguments and accordingly
        % assigns values to the properties.
            arguments
                namedArgs.NumericFormat string = settings().matlab...
                    .commandwindow.NumericFormat.ActiveValue;
                namedArgs.LineSpacing string = settings().matlab...
                    .commandwindow.DisplayLineSpacing.ActiveValue;
            end
            validStr = validatestring(namedArgs.NumericFormat,...
                obj.validNumericFormatValues);
            obj.NumericFormat = validStr;
            validStr = validatestring(namedArgs.LineSpacing,...
                obj.validLineSpacingValues);
            obj.LineSpacing = validStr;
        end
    end
    properties (Hidden=true, Access=private)
        validNumericFormatValues = ["short", "long", "shortE",...
            "longE", "shortG", "longG", "shortEng", "longEng",...
            "bank", "rational", "hex","+", "debug"];
        validLineSpacingValues = ["loose", "compact"];
    end
end
