function str = getDescriptionForTextObject(t)
%

%   Copyright 2021 The MathWorks, Inc.

% Given a text object, this function returns a string that describes the
% text object. Currently, the description includes the 'Type' of the object
% (text) and the text's string

arguments
    t (1, 1) {mustBeA(t, 'matlab.graphics.primitive.Text')}
end

str_type = string(t.Type);

str_string = matlab.graphics.internal.screenreader.getSimplifiedStringFromText(t); 

str = strjoin([str_type, str_string]);

end

