function validateXMLElement(elementValue, elementName, isAttribute)
%

% Copyright 2020 The MathWorks, Inc.

    import matlab.io.xml.internal.write.validateXMLNameCharacters
    
    % Assume that an element node name is provided is isAttribute is specified.
    if nargin < 3
        isAttribute = false;
    end
    
    % Only check user input and table variable names for invalid characters 
    if (needsInvalidCharactersCheck(elementName))
        validateXMLNameCharacters(elementValue, elementName);
    end

    % Error if the element or attribute name begins with "xml"
    if startsWith(elementValue, "xml", "IgnoreCase", true)
        if isAttribute && strcmp(elementValue, "xmlns")
            return; % Allow the xmlns attribute
        elseif startsWith(elementValue, "xmlns:") || startsWith(elementValue, "xml:")
            return; % Allow the xmlns and xml namespace prefixes
        end

        % Display the warning message, and then turn the warning off to avoid multiple
        % warnings from being printed.
        % The warning state will be corrected later during writestruct and writetable before exit.
        msgid = "MATLAB:io:xml:common:StartsWithXMLElementName";
        warning(message(msgid, elementName));
        warning('off', msgid);
    end
end

% Opt-in to validate the node name value for supported characters to be
% used in an XML name
function check = needsInvalidCharactersCheck(elementName)
    check = any(strcmp(elementName, ["TableNodeName", "RowNodeName", ...
        "VariableNames", "StructNodeName"]));
end
