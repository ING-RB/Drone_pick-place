function [omitMissing,optionOut] = validateMissingOption(optionIn) %#codegen
%VALIDATEMISSINGOPTION Validate the NaN-flag argument for categorical methods.
%   [OMITMISSING,OPTION] = VALIDATEMISSINGOPTION(OPTION) returns OMITMISSING as true
%   if OPTION is 'omitmissing/nan/undefined'. OPTION is the input option mapped to the
%   core MATLAB equivalent if necessary (i.e. 'includemissing' and 'includeundefined'
%   become 'includenan').

%   Copyright 2020-2022 The MathWorks, Inc.

isScalarText = (ischar(optionIn) && isrow(optionIn)) || (isstring(optionIn) && isscalar(optionIn));
coder.internal.assert(isScalarText,'MATLAB:categorical:unknownOption'); % not even text

coder.internal.assert(coder.internal.isConst(optionIn),'MATLAB:categorical:nonConstOption'); % must be const

choices = {'includemissing' 'includenan' 'includeundefined' 'omitmissing' 'omitnan' 'omitundefined'};
s = strncmpi(optionIn,choices,max(strlength(optionIn),1));
coder.internal.assert(any(s),'MATLAB:categorical:unknownOption'); % junk, or 'all' in the wrong place
if s(1) || s(2) || s(3) % 'includemissing/nan/undefined'
    omitMissing = false;
    optionOut = 'includenan';
else % s(4) || s(5) || s(6) % 'omitmissing/nan/undefined'
    omitMissing = true;
    optionOut = 'omitnan';
end
