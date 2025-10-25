function p = xmlLocGetParser(args)
%

% Copyright 2022-2024 The MathWorks, Inc.

import matlab.io.xml.internal.legacy.xmlFindIndexOfFirstNameValuePair
import matlab.io.xml.internal.legacy.xmlLocIsValidating
import matlab.io.xml.internal.legacy.xmlParseNameValuePairs


p = [];
for i=1:length(args)
    if isa(args{i},'javax.xml.parsers.DocumentBuilderFactory')
        javaMethod('setValidating',args{i},xmlLocIsValidating(args));
        p = javaMethod('newDocumentBuilder',args{i});
        break;
    elseif isa(args{i},'javax.xml.parsers.DocumentBuilder')
        p = args{i};
        break;
    end
end

if isempty(p)
    parserFactory = javaMethod('newInstance',...
        'javax.xml.parsers.DocumentBuilderFactory');
    javaMethod('setValidating',parserFactory,xmlLocIsValidating(args));
    %javaMethod('setIgnoringElementContentWhitespace',parserFactory,1);
    %ignorable whitespace requires a validating parser and a content model
    
    % Since xmlread allows arbitrary inputs to be passed in using
    % varargin, we can't reliably use an inputParser here for
    % name-value pair parsing.
    firstNameValuePairIndex = xmlFindIndexOfFirstNameValuePair(args);
    if firstNameValuePairIndex ~= -1
        nameValuePairs = args(firstNameValuePairIndex:end);
        parsedNameValuePairs = xmlParseNameValuePairs(nameValuePairs);
        
        % Disable DOCTYPE declarations completely.
        % This also disables validation against DTD files
        % and resolution of external entities.
        if ~parsedNameValuePairs.AllowDoctype
            parserFactory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            parserFactory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            parserFactory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            parserFactory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
            parserFactory.setExpandEntityReferences(false);
        end
        
    end
    
    p = javaMethod('newDocumentBuilder',parserFactory);
end

end