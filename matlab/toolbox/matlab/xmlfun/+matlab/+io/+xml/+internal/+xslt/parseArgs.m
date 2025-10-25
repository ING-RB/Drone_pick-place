function parsed = parseArgs(varargin)
    % source and style are required input arguments.
    % However, dest is an optional input argument.
    %
    % The following syntaxes are supported:
    %
    % 1. xslt(source, style)
    % 2. xslt(source style, XMLEngine=value)
    % 3. xslt(source, style, dest)
    % 4. xslt(source, style, dest, XMLEngine=value)
    % 5. xslt(source, style, "-web")
    % 6. xslt(source, style, "-web", XMLEngine=value)
    % 7. xslt(source, style, dest, "-web")
    % 8. xslt(source, style, dest, "-web", XMLEngine=value)

    [unparsed, xmlEngine] = parseXMLEngineNVPair(varargin);

    parsed.source = unparsed{1};
    parsed.style = unparsed{2};
    parsed.dest = "";
    parsed.displayWeb = false;
    parsed.XMLEngine = xmlEngine;
    numPositionalArgs = numel(unparsed);

    if numPositionalArgs == 3
        parsed.displayWeb = isequal(unparsed{3}, "-web");
        if ~parsed.displayWeb
            % If the third positional input argument is not -web, then
            % assume it is a value for dest.
            parsed.dest = unparsed{3};
        end
    elseif numPositionalArgs >= 4
        % Four positional input arguments were supplied, so assume the
        % third is a value for dest and check if the forth is "-web".
        parsed.dest = unparsed{3};
        parsed.displayWeb = isequal(unparsed{4}, "-web");
    end
end

function [args, xmlEngine] = parseXMLEngineNVPair(args)
    numArgs = numel(args);
    if numArgs == 6
        % Supported Syntaxes:
        % - xslt(source, style, dest, "-web", XMLEngine=value)
        xmlEngine = validateXMLEngineNVPair(args{5}, args{6});
        args = args(1:4);
    elseif numArgs == 5
        % Supported Syntaxes:
        % - xslt(source, style, dest, XMLEngine=value)
        % - xslt(source, style, "-web", XMLEngine=value)
        xmlEngine = validateXMLEngineNVPair(args{4}, args{5});
        args = args(1:3);
    elseif numArgs == 4
        % Supported Syntaxes:
        % - xslt(source, style, dest, "-web")
        % - xslt(source, style, XMLEngine=value)
        if isScalarText(args{3}) && args{3} == "XMLEngine"
            xmlEngine = validateXMLEngineArgValue(args{4});
            args = args(1:2);
        else
            xmlEngine = "auto";
        end
    else
        % Supported Syntaxes:
        % - xslt(source, style, dest)
        % - xslt(source, style, "-web")
        % - xslt(sourc,e style)
        xmlEngine = "auto";
    end
end

function value = validateXMLEngineNVPair(name, value)
    if ~isScalarText(name)
         error(message('MATLAB:io:common:arguments:InvalidParameterType'));
    elseif name ~= "XMLEngine"
        error(message("MATLAB:io:common:arguments:UnknownParameter", name));
    end
    value = validateXMLEngineArgValue(value);
end

function value = validateXMLEngineArgValue(value)
   value = validatestring(value, ["auto" "maxp" "jaxp"]);
end

function tf = isScalarText(value)
    isCharVector = ischar(value) && isrow(value);
    isStringScalar = isstring(value) && isscalar(value);
    tf = (isCharVector || isStringScalar) && strlength(value) > 0;
end

% Copyright 2024 The MathWorks, Inc.
