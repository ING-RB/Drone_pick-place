classdef ReadLines < matlab.io.internal.functions.ExecutableFunction
    %READLINES Functional Interface for readlines

    %   Copyright 2020 The MathWorks, Inc.
    properties (Constant)
        InternalFunction = getDefaultFunc()
    end

    properties (Access = private)
        ConfiguredFunction
    end

    properties (Required)
        Filename;
    end

    properties (Parameter)
        %  'LineEnding'     - The line ending for the file.
        LineEnding
        %  'Whitespace'     - Characters to treat as whitespace.
        Whitespace
        %  'WhitespaceRule' - What to do with whitespace surrounding the lines.
        WhitespaceRule
        %  'EmptyLineRule'  - What to do with empty lines in the file.
        EmptyLineRule
        %  'Encoding'       - The character encoding scheme associated with
        %                     the file. If not specified, the encoding is detected
        %                     from the file. If the 'Encoding' parameter value is
        %                     'system', then readlines uses your system's default
        %                     encoding.
        Encoding
        %  "WebOptions"     - HTTP(s) request options, specified as a
        %                     weboptions object.
        WebOptions = [];
    end

    properties (Parameter, Dependent, Hidden)
        %ENDOFLINE End-of-line character.
        % Can be any  single character, or '\r\n'. If EndOfLine is '\r\n',
        % any of the following will be treated as a line ending:\n, \r, or
        % \r\n. Can be specified as a character vector or scalar string.
        EndOfLine
    end

    methods
        function [func,supplied,otherArgs] = validate(func,varargin)
            [func,varargin] = extractArg(func,"WebOptions",varargin, 1);

            [func,supplied,otherArgs] = func.validate@matlab.io.internal.functions.ExecutableFunction(varargin{:});

            func.ConfiguredFunction = matlab.io.internal.functions.ReadLines.InternalFunction;
            if supplied.WebOptions
                func.ConfiguredFunction.WebOptions = func.WebOptions;
            end
            % Readmatrix expects certain fields in the supplied struct
            supplied = mergeSuppliedWithDefault(func,supplied);

            func = setConfiguredFunction(func,supplied);

        end

        function lines = execute(func,supplied)
            supplied.Encoding = false;
            lines = func.ConfiguredFunction.execute(supplied);
        end

        function val = get.EndOfLine(opts)
            val = opts.LineEnding;
        end

        function opts = set.EndOfLine(opts,rhs)
            % setter for EndOfLine *sets the value for LineEnding*
            rhs = convertStringsToChars(rhs);
            rhs = matlab.io.internal.utility.validateAndEscapeCellStrings(rhs,'EndOfLine');
            if strcmp(rhs, char([13 10]))
                opts.LineEnding = {newline, char(13), char([13 10])};
            else
                opts.LineEnding = rhs;
            end
        end

    end

    methods (Access = private)
        function func = setConfiguredFunction(func,supplied)
            % set once at end
            opts = func.ConfiguredFunction.Options;

            func.ConfiguredFunction.Filename = func.Filename;
            if supplied.LineEnding
                opts.LineEnding = func.LineEnding;
            end
            if supplied.WhitespaceRule
                opts = setvaropts(opts,1,'WhitespaceRule',func.WhitespaceRule);
            end
            if supplied.Whitespace
                opts.Whitespace = func.Whitespace;
            end
            if supplied.EmptyLineRule
                opts.EmptyLineRule = func.EmptyLineRule;
            end
            if supplied.Encoding
                opts.Encoding = func.Encoding;
            end
            func.ConfiguredFunction.Options = opts;
        end

        function supplied = mergeSuppliedWithDefault(func,supplied)
            % Merging the supplied structs, preferring the parameters
            % in readlines.
            suppliedRM = func.ConfiguredFunction.SuppliedStruct;
            for f = string(fieldnames(suppliedRM)')
                if ~isfield(supplied,f)
                    supplied.(f) = false;
                end
            end
        end
    end
end

function func = getDefaultFunc()
opts = delimitedTextImportOptions('NumVariables',1,...
    "VariableTypes","string");
opts.Delimiter = "";
opts.EmptyLineRule = "read";
opts.Encoding = "";

opts = setvaropts(opts,1,...
    "FillValue","",...
    "QuoteRule","keep",...
    "WhitespaceRule","preserve");

func = matlab.io.internal.functions.ReadMatrixWithImportOptions();
func.OutputType = "string";
func.ReadVariableNames = false;
func.Options = opts;
func.ReadingLines = true;
end
