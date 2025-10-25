function str = getSimplifiedStringFromText(t)
% Given a text object, returns the string after removing white spaces, and
% combining multiple lines into one. 

%   Copyright 2021 The MathWorks, Inc.

arguments
    t (1, 1) {mustBeA(t, 'matlab.graphics.primitive.Text')}
end

ch = t.String;

% Step 1: Make sure that we are dealing with strings and not chars.
str = string(ch);

% Step 2: Remove leading and trailing white spaces from all the strings. 
str = strip(str);

% Step 3: Combine multiple strings into one. 
str = strjoin(str);


end

