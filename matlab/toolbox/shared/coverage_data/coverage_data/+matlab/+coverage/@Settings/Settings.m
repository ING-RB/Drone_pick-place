%

% Copyright 2022 The MathWorks, Inc.

classdef Settings < matlab.mixin.Copyable

    properties (SetAccess=?matlab.coverage.Result)
        Function (1,1) logical = true
        Statement (1,1) logical = true
        Decision (1,1) logical = true
        Condition (1,1) logical = true
        MCDC (1,1) logical = true
        MCDCMode (1,1) string {mustBeMember(MCDCMode, ["UniqueCause", "Masking"])} = "UniqueCause"
    end

end

% LocalWords:  MCDC
