classdef ServiceFactory
    % This class is undocumented and will change in a future release.
    
    % ServiceFactory - Creates services. Used with the Service interface and
    % the ServiceLocator in order to locate and construct services across
    % module boundaries dynamically.
    %
    % See Also: ServiceLocator, Service
    
    % Copyright 2015-2022 The MathWorks, Inc.
    
    methods(Static)
        function services = create(serviceClasses, varargin)
            % create - Create each service according to its own interface
            %
            %   SERVICES = Service.create(SERVICECLASSES, INPUT1, INPUT2, ..., INPUTN)
            %   should create an array of SERVICES for each element of SERVICECLASSES.
            %   SERVICECLASSES is a meta.class array of classes that derive from
            %   Service. INPUT1, INPUT2, ..., INPUTN are the inputs
            %   which are determined by the implementing service interface.
            
            import matlab.automation.internal.services.ServicePlaceholder;
            
            servicesCell = cell(1, numel(serviceClasses));
            serviceClassNames = {serviceClasses.Name};
            for idx = 1:numel(serviceClasses)
                constructor = str2func(serviceClassNames{idx});
                servicesCell{idx} = constructor(varargin{:});
            end
            services = reshape([ServicePlaceholder.empty, servicesCell{:}], ...
                size(serviceClasses));
        end
    end
    
end

% LocalWords:  SERVICECLASSES INPUTN func
