classdef (HandleCompatible) FailureHandler
    %

    % Copyright 2021 The MathWorks, Inc.

    methods (Abstract)
        handleQualificationFailure(handler);
    end
end

