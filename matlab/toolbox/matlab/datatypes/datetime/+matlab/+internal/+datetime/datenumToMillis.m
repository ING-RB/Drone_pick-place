function millis = datenumToMillis(x,allowNonDouble)
%DATENUMTOMILLIS Convert datenum to milliseconds.
%   MILLIS = DATENUMTOMILLIS(X) returns the number of milliseconds
%   corresponding to a given datenum.
%
%   MILLIS = DATENUMTOMILLIS(X,ALLOWNONDOUBLE), when ALLOWNONDOUBLE is
%   true, enables X to be any non-double numeric type. By default
%   ALLOWNONDOUBLE is false, meaning that DATENUMTOMILLIS will error when X
%   is a non-double numeric type.

%   Copyright 2014-2020 The MathWorks, Inc.

try
    
    if isa(x,'double') || islogical(x)
        if ~isreal(x)
            error(message('MATLAB:datetime:ComplexNumeric'));
        end
        millis = full(x) * 86400000; % days -> ms
    elseif (nargin == 2) && allowNonDouble && isnumeric(x)
        if ~isreal(x)
            error(message('MATLAB:datetime:ComplexNumeric'));
        end
        millis = full(double(x)) * 86400000; % days -> ms
    else
        error(message('MATLAB:datetime:DurationConversion'));
    end
    
catch ME
    throwAsCaller(ME);
end
