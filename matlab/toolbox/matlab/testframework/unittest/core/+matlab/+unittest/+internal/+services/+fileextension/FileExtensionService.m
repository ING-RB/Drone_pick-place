classdef FileExtensionService < matlab.unittest.internal.services.Service
    % This class is undocumented and will change in a future release.
    
    % FileExtensionService - Interface for file extension services.
    %
    % See Also: FileExtensionLiaison, Service, ServiceLocator, ServiceFactory
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    properties (Abstract, Constant)
        Extension (1,1) string;
        IncludedInNamespaces (1,1) logical;
    end
    
    methods (Abstract)
        suite = createSuiteExplicitly(service, liaison, modifier, externalParameters, varargin);
        suite = createSuiteImplicitly(service, liaison, modifier, externalParameters, varargin);
    end
    
    methods (Sealed)
        function fulfill(services, liaison)
            % fulfill - Fulfill an array of file extension services
            %
            %   fulfill(SERVICES) validates that a service supports the file.
            %
            %   The folder containing the test file is assumed to be on
            %   path at fulfill time.
            
            supportingService = services.findServiceThatSupports(liaison.Extension);
            
            if isempty(supportingService)
                error(message("MATLAB:unittest:TestSuite:UnsupportedFile", liaison.ShortFile));
            end
        end
        
        function aService = findServiceThatSupports(services, extension)
            aService = services([services.Extension] == extension);
        end
    end
end

