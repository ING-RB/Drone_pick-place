function ind = checkInputName(actualName,expectedNames,minLength) %#codegen
%CHECKINPUTNAME Match name of input argument against supported names.
%   IND = CHECKINPUTNAME(ACTUALNAME,EXPECTEDNAMES,MINLENGTH) returns
%   true if ACTUALNAME is a partial (to at least MINLENGTH chars) or
%   complete case-insensitive match to an element of EXPECTEDNAMES.
%   EXPECTEDNAMES is a char vector or a cell array of char vectors.
%   CHECKINPUTNAME returns false if actualName is '' or [].

%   Copyright 2019-2020 The MathWorks, Inc.

if nargin < 3
    minLength = 1;
end
if (ischar(actualName) && isrow(actualName)) || ...
   (isstring(actualName) && isscalar(actualName))
    ind = strncmpi(actualName, expectedNames, ...
        max(minLength,strlength(actualName)));
else
    if ischar(expectedNames)
        ind = false;
    else
        ind = false(size(expectedNames));
    end
end