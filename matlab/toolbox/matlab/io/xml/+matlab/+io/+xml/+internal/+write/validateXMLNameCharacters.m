function validateXMLNameCharacters(nameValue, elementName)
% The XML 1.0 Specification, Fifth Edition, limits the characters that can
% be used in element or attribute names:
% https://www.w3.org/TR/xml/#NT-Name

% Copyright 2020 The MathWorks, Inc.

import matlab.io.xml.internal.write.inHexRange
import matlab.io.xml.internal.write.validateXMLNameFirstCharacter

% convert the name to char type
nameValue = char(nameValue);

validateXMLNameFirstCharacter(nameValue, elementName);

highSurrogate = 0;

for i = 2:length(nameValue)
    nameChar = nameValue(i);
    
    % Check for high surrogate value
    if inHexRange(nameChar, 0xD800, 0xDBFF)
        % store high surrogate value for next iteration
        highSurrogate = nameChar;
    
    % Check for low surrogate if high surrogate is set correctly
    elseif inHexRange(highSurrogate, 0xD800, 0xDBFF) ...
        &&  inHexRange(nameChar, 0xDC00, 0xDFFF)
        
        lowSurrogate = nameChar;
        
        % compute Unicode scalar value
        unicodeScalarValue = (highSurrogate - 0xD800) * 400 ...
            + (lowSurrogate - 0xDC00) + 10000;
        
        % compare Unicode scalar value to supported range
        if inHexRange(unicodeScalarValue, 0x10000, 0xEFFFF)
            invalidChar = [char(highSurrogate), char(lowSurrogate)];
            
            error(message("MATLAB:io:xml:common:UnsupportedCharInElementName", ...
            elementName, nameValue, invalidChar));
        end
        
        % reset surrogate value variables
        lowSurrogate = 0;
        highSurrogate = 0;
    elseif ~(startsWith(nameChar, "_") ...
        || startsWith(nameChar, ":") ...
        || isstrprop(nameChar, "alphanum") ...
        || inHexRange(nameChar, 0xC0, 0xD6) ...
        || inHexRange(nameChar, 0xD8, 0xF6) ...
        || inHexRange(nameChar, 0xF8, 0x2FF) ...
        || inHexRange(nameChar, 0x370, 0x37D) ...
        || inHexRange(nameChar, 0x37F, 0x1FFF) ...
        || inHexRange(nameChar, 0x200C, 0x200D) ...
        || inHexRange(nameChar, 0x2070, 0x218F) ...
        || inHexRange(nameChar, 0x2C00, 0x2FEF) ...
        || inHexRange(nameChar, 0x3001, 0xD7FF) ...
        || inHexRange(nameChar, 0xF900, 0xFDCF) ...
        || inHexRange(nameChar, 0xFDF0, 0xFFFD) ...
        || inHexRange(nameChar, 0xB7, 0xB7) ...
        || inHexRange(nameChar, 0x0300, 0x036F) ...
        || inHexRange(nameChar, 0x203F, 0x2040))

        error(message("MATLAB:io:xml:common:UnsupportedCharInElementName", ...
            elementName, nameValue, char(nameChar)));
    end

end

