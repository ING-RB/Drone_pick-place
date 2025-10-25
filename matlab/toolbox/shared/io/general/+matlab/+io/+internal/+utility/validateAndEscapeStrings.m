function str = validateAndEscapeStrings( str , propertyname )
% VALIDATEESCAPEDSTRINGS validate and transform input strings

% Copyright 2015-2018, The MathWorks, Inc.

if ~matlab.io.internal.validators.isCharVector(str)
    error(message('MATLAB:textio:textio:InvalidStringProperty',propertyname));
end

% sprintf turns '%' into empty, double-escape '%' to avoid this.
str = sprintf(replace(str, "%", "%%"));
end

