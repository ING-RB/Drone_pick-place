function seq = supportedLegacyEulerSequences
%This function is for internal use only. It may be removed in the future.

%supportedLegacyEulerSequences Return character vector cell array of legacy supported Euler axis orders
%   This list is used for validation, tab completion, etc.
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    seq = {'ZYX', 'ZYZ', 'XYZ'};
end
