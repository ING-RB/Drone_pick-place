function [xResultURI, xProcessor] = xslt(varargin)
%

% Copyright 2024 The MathWorks, Inc.

   import matlab.io.xml.internal.legacy.xmlstringinput

    % Convert strings to chars.
    if nargin > 0
        [varargin{:}] = convertStringsToChars(varargin{:});
    end

    [isView, isToString, errorListener, uriResolver, varargin] = locFlags(varargin);
    xUtil = "com.mathworks.xml.XMLUtils";

    % Find Source
    if ischar(varargin{1})
        varargin{1} = xmlstringinput(varargin{1}, true);
    end
    xSource = javaMethod('transformSourceFactory', xUtil, varargin{1});

    % Find Result
    if isToString
        stringWriter = java.io.StringWriter;
        xResult = stringWriter;
    else
        if length(varargin) < 3 | isempty(varargin{3})
            xResult = java.io.File([tempname, '.html']);
        else
            xResult = varargin{3};
            if ischar(xResult)
                xResult = xmlstringinput(xResult, false);
            end
        end

        if ischar(xResult)
            if strncmp(xResult, 'file:', 5)
                xResult = regexprep(xResult, '^file:///(([a-zA-Z]:)|[\\/])', '$1');
                xResult = strrep(xResult, 'file://', '');
                temp = java.io.File(xResult);
                xResult = strrep(char(temp.toURI()), '%20', ' ');
            end
            xResultURI = xResult;
        elseif isa(xResult, 'java.io.File')
            xResultURI = xmlstringinput(char(xResult.getCanonicalPath), false);
        else
            xResultURI = '';
        end
    end
    
    xResult=javaMethod('transformResultFactory', xUtil, xResult);

    % Find Stylesheet
    if length(varargin) < 2
        varargin{2} = '';
    end
    xProcessor = locTransformer(varargin{2}, xSource, xUtil, errorListener, uriResolver);

    % Perform Transformation
    xProcessor.transform(xSource, xResult);

    if isToString
        xResultURI = char(stringWriter.toString);
        if isView
            web(['text://' xResultURI]);
        end
    elseif isView & ~isempty(xResultURI)
        web(xResultURI);
    end
end

function [isView, isToString, errorListener, uriResolver, arg] = locFlags(arg)
    flagIdx = strncmp(arg, '-', 1);
    flagStrings = arg(find(flagIdx));
    arg = arg(find(~flagIdx));
    isView = any(strcmp(flagStrings, '-web'));
    isToString = any(strcmp(flagStrings, '-tostring'));
    
    % Check whether any of the input arguments are a javax.xml.transform.ErrorListener
    errorListener = [];
    uriResolver = [];
    i = 1;
    while i <= length(arg)
        if isa(arg{i}, 'javax.xml.transform.ErrorListener')
            errorListener = arg{i};
            arg = [arg(1:i-1), arg(i+1:end)];
        elseif isa(arg{i}, 'javax.xml.transform.URIResolver')
            uriResolver = arg{i};
            arg = [arg(1:i-1), arg(i+1:end)];
        else
            i = i + 1;
        end
    end
end

function xProcessor = locTransformer(xStyle, xSource, xUtil, errorListener, uriResolver)
    import matlab.io.xml.internal.legacy.xmlstringinput

    if isa(xStyle, 'javax.xml.transform.Transformer')
        xProcessor = xStyle;
        if ~isempty(errorListener)
            %note that SAXON does not yet honor the errorListener so this action
            %doesn't really do anything yet
            xProcessor.setErrorListener(errorListener);
        end

        if ~isempty(uriResolver)
            xProcessor.setURIResolver(uriResolver);
        end
    else
        xformFactory = javaMethod('newInstance', 'javax.xml.transform.TransformerFactory');
        if ~isempty(errorListener)
            xformFactory.setErrorListener(errorListener);
        end
    
        if ~isempty(uriResolver)
            xformFactory.setURIResolver(uriResolver);
        end

        if isempty(xStyle) %find the stylesheet
            try
                xStyle = javaMethod('getAssociatedStylesheet', xformFactory, xSource, '', '', '');
            catch
                error(message('MATLAB:xslt:NoStylesheet'));
            end
        else
            if ischar(xStyle)
                xStyle = xmlstringinput(xStyle, true);
            end
            xStyle = javaMethod('transformSourceFactory', xUtil, xStyle);
        end

        xProcessor = javaMethod('newTransformer', xformFactory, xStyle);
    end
end