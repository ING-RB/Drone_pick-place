classdef HandlerService < matlab.unittest.internal.services.Service
    %HandlerService is an interface for services that provide handlers
    %
    %   See also: HandlerLiaison

%   Copyright 2022 The MathWorks, Inc.

    methods (Abstract)
        handler = getHandler(service);
    end

    methods (Sealed)
        function fulfill(services, liaison)
            % fulfill - Fulfill an array of informal suite creation services
            %
            %   The fulfill method takes a liaison and populates it with an
            %   array of concrete handler objects derived from each of the
            %   elements in services
            
            numServices = numel(services);
            serviceHandlers = cell(1, numServices);

            for serviceIdx = 1:numel(services)
                service = services(serviceIdx);
                serviceHandlers{serviceIdx} = service.getHandler();
            end

            liaison.Handlers = [matlab.unittest.internal.services.informalsuite.Handler.empty(1, 0), serviceHandlers{:}];
        end
    end
end
