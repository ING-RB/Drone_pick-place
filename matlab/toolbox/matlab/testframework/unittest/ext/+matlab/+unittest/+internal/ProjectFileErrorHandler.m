classdef (HandleCompatible) ProjectFileErrorHandler
    %

    % Copyright 2022 The MathWorks, Inc.

    methods (Abstract)
        handle(handler, exception, filename);
    end
end

