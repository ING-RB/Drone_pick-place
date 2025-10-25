classdef (Sealed) BoundInclusivity < matlab.internal.validation.OptionalFlag
% BoundInclusivity Option flags for mustBeInRange
    
% Copyright 2018-2020 The MathWorks, Inc.
    properties(Constant)
        Flags = ["inclusive", "exclusive", "exclude-lower", "exclude-upper"]
    end
end
