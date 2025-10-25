%#codegen
function [millis, validConversion] = datenumToMillis(x,allowNonDouble)
%DATENUMTOMILLIS Convert datenum to milliseconds.
%   MILLIS = DATENUMTOMILLIS(X) returns the number of milliseconds
%   corresponding to a given datenum.
%
%   MILLIS = DATENUMTOMILLIS(X,ALLOWNONDOUBLE), when ALLOWNONDOUBLE is
%   true, enables X to be any non-double numeric type. By default
%   ALLOWNONDOUBLE is false, meaning that DATENUMTOMILLIS will error when X
%   is a non-double numeric type.
%
%   [MILLIS,VALIDCONVERSION] = DATENUMTOMILLIS(X,ALLOWNONDOUBLE) sets
%   VALIDCONVERSION to true if DATENUMTOMILLIS permits converting X to a
%   double, i.e. if X is a double or logical, or if ALLOWNONDOUBLE is true
%   and X is a numeric non-double type.

%   Copyright 2014-2020 The MathWorks, Inc.

if isa(x,'double') || islogical(x)
    coder.internal.assert(isreal(x),'MATLAB:datetime:ComplexNumeric');
    millis = full(x) * 86400000; % days -> ms
    validConversion = true;
else
    validConversion = (nargin == 2) && allowNonDouble && isnumeric(x);
    if validConversion
        coder.internal.assert(isreal(x),'MATLAB:datetime:ComplexNumeric');
        millis = full(double(x)) * 86400000; % days -> ms
    else
        millis = 0;
    end
end
