function seq = supportedEulerSequences
%This function is for internal use only. It may be removed in the future.

%supportedEulerSequences Return character vector cell array of commonly supported Euler axis orders
%   This list is used for validation, tab completion, etc.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    seq = {'ZYX', 'ZYZ', 'XYZ', 'ZXY', 'ZXZ', 'YXZ', 'YXY', 'YZX', 'YZY', ...
           'XYX', 'XZY', 'XZX'};
end
