function nodeNameValue = validateNodeName(nodeNameValue, nodeName, isAttribute)
%

% Copyright 2020 The MathWorks, Inc.
    
    if nargin < 3
        isAttribute = false;
    end
    
    validateattributes(nodeNameValue, ["string", "char"], "scalartext", ...
        "", nodeName);

    nodeNameValue = string(nodeNameValue);

    % Error if the empty string was passed as input.
    if nodeNameValue == ""
        msgid = "MATLAB:io:xml:common:EmptyNodeName";
        error(message(msgid, nodeName));
    end

    matlab.io.xml.internal.write.validateXMLElement(nodeNameValue, nodeName, isAttribute);
end
