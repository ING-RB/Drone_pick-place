classdef UnsatisfiedCapability < MException
    properties(GetAccess = public, SetAccess = {?matlab.internal.capability.Capability})
        RequiredCapabilities
        EnabledCapabilities
        UnsatisfiedCapabilities
    end

    methods
        function obj = UnsatisfiedCapability(varargin)
            obj = obj@MException(varargin{:});
        end
    end
end

% Copyright 2018-2023 The MathWorks, Inc.
