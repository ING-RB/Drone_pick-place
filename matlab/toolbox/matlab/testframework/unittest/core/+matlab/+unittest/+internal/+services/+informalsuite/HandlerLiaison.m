classdef HandlerLiaison < handle
    %HandlerLiaison is a liaison to handler services
    %
    %   See also: HandlerService

%   Copyright 2022 The MathWorks, Inc.
    
    properties
        Handlers = matlab.unittest.internal.services.informalsuite.Handler.empty(1, 0)
    end
end
