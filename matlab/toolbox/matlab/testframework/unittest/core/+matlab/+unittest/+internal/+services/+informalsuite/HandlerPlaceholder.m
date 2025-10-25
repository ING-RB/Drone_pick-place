classdef HandlerPlaceholder < matlab.unittest.internal.services.informalsuite.Handler
    %

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        Precedence = matlab.unittest.internal.services.informalsuite.HandlerPrecedence.ContainerPost;
    end

    methods
        createSuite(varargin);
    end

    methods (Access=protected)
        canHandle(varargin);
    end
end

