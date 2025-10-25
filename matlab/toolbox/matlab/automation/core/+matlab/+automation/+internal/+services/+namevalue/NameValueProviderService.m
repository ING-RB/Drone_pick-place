classdef NameValueProviderService < matlab.automation.internal.services.Service
    % This class is undocumented and will change in a future release.

    % NameValueProviderService - Interface for name-value pair addition services.
    %
    % See Also: NameValueProviderLiaison, Service, ServiceLocator, ServiceFactory

    %   Copyright 2018-2022 The MathWorks, Inc.

    properties(Abstract, Constant)
        ParameterName
        Default
    end
    
    methods
        function validate(service, value) %#ok<INUSD>
        end
        
        function value = resolve(service, value) %#ok<INUSL>
        end
    end
    
    methods(Sealed)
        function fulfill(services, liaison)
            arrayfun(@(s) liaison.addParameter(s.ParameterName, s.Default,...
                @s.validate, @s.resolve), services, 'UniformOutput', false);
        end
    end
end
