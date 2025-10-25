classdef CoberturaPublishingService < matlab.unittest.internal.services.Service
%

%   Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess = protected,GetAccess = protected)
      Formatter;
    end
    
    methods (Abstract)
        publish(service,fileName,sources,profileData)
    end
    methods (Abstract, Static)
        supports(sources)
    end
    
    methods (Sealed)
        function fulfill(services,fileName,sources,profileData)
            for serviceIndex = 1:length(services)
                if services(serviceIndex).supports(sources)
                    services(serviceIndex).publish(fileName,sources,profileData);
                end
            end
        end
    end
end
