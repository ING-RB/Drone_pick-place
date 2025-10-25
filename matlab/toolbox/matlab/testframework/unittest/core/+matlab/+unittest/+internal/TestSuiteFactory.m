classdef TestSuiteFactory
    % This class is undocumented.
    
    % TestSuiteFactory - Abstract factory class for creating suites.
    %   TestSuiteFactory abstracts out static analysis and suite creation
    %   operations for test content defined using different interfaces.
    
    % Copyright 2014-2024 The MathWorks, Inc.
    
    properties(Abstract, Constant)
        CreatesSuiteForValidTestContent
        SupportsParameterizedTests (1,1) logical;
    end
    
    methods (Abstract)
        % createSuiteExplicitly - Attempt to create the suite.
        %   Create the suite given a specific entity (e.g., a class name).
        suite = createSuiteExplicitly(factory, modifier, parameters, varargin)
        
        % createSuiteImplicitly - Attempt to create the suite.
        %   Create the suite using an entity discovered inside a container
        %   (e.g., folder or namespace).
        suite = createSuiteImplicitly(factory, modifier, parameters, varargin)
    end
    
    methods (Hidden)
        function suite = createSuiteFromParentName(factory, modifier, params)
            arguments
               factory
               modifier
               params = matlab.unittest.parameters.Parameter.empty(1, 0);
            end
            suite = factory.createSuiteExplicitly(modifier, params);
        end
        
        function suite = createSuiteFromProcedureName(factory, procedureName, modifier, params)
            import matlab.unittest.selectors.HasProcedureName;

            modifier = modifier & HasProcedureName(procedureName);
            suite = factory.createSuiteExplicitly(modifier, params);
        end
        
        function suite = createSuiteFromName(factory, nameParser, parameters)
            import matlab.unittest.selectors.HasName;
            
            if ~factory.SupportsParameterizedTests && ...
                    ~isempty([nameParser.TestMethodParameters, nameParser.MethodSetupParameters, nameParser.ClassSetupParameters])
                error(message("MATLAB:unittest:TestSuite:TestDoesNotAcceptParameters"));
            end
            
            suite = factory.createSuiteExplicitly(HasName(nameParser.Name), parameters);
            if isempty(suite)
                error(message("MATLAB:unittest:TestSuite:InvalidTestFunction", ...
                    nameParser.ParentName, nameParser.TestName));
            end
        end
        
        function bool = isValidProcedureName(~,~)
            bool = false;
        end
    end
    
    methods (Static)
        function factory = fromParentName(varargin)
            % fromParentName - Create a TestSuiteFactory for a given test parent name.
            %   TestSuiteFactory.fromParentName(parentName, namingConventionService)
            %   creates a TestSuiteFactory for test content with the given parent name
            %   according to the supplied naming convention service. If a naming
            %   convention service is not supplied, this method locates the service.
            
            import matlab.automation.internal.services.ServiceLocator;
            import matlab.unittest.internal.services.ServiceFactory;
            import matlab.unittest.internal.services.suitecreation.SuiteCreationLiaison;
            import matlab.unittest.internal.services.suitecreation.ClassSuiteCreationService;
            
            namespace = 'matlab.unittest.internal.services.suitecreation.located';
            locator = ServiceLocator.forNamespace(meta.package.fromName(namespace));
            cls = ?matlab.unittest.internal.services.suitecreation.SuiteCreationService;
            locatedServiceClasses = locator.locate(cls);
            locatedServices = ServiceFactory.create(locatedServiceClasses);
            
            services = [ClassSuiteCreationService; locatedServices];
            liaison = SuiteCreationLiaison.fromParentName(varargin{:});
            fulfill(services, liaison);
            factory = liaison.Factory;
        end
    end
    
    methods (Access=protected)
        function factory = TestSuiteFactory
        end
    end
end

% LocalWords:  suitecreation cls
