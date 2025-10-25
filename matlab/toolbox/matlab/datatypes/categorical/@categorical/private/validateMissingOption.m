function [omitMissing,option] = validateMissingOption(option)
%VALIDATEMISSINGOPTION Validate the NaN-flag argument for categorical methods.
%   [OMITMISSING,OPTION] = VALIDATEMISSINGOPTION(OPTION) returns
%   OMITMISSING as true if OPTION is either 'omitmissing/nan/undefined'.
%   OPTION is the input option mapped to the core MATLAB equivalent if
%   necessary (e.g. 'includemissing/undefined' becomes 'includenan').

%   Copyright 2017-2022 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText

if isScalarText(option)
    choices = ["includemissing" "includeundefined" "includenan" "omitmissing" "omitundefined" "omitnan"];
    s = strncmpi(option,choices,max(strlength(option),1));
    if s(1) || s(2) || s(3) % 'includemissing'
        omitMissing = false;
        option = 'includemissing';
    else
        omitMissing = true;
        if s(4) || s(5)|| s(6) % 'omitmissing'
            option = 'omitmissing';
        else
            % leave any other string alone
        end
    end
else
    omitMissing = true;
    % leave a numeric DIM, or any junk, alone
end