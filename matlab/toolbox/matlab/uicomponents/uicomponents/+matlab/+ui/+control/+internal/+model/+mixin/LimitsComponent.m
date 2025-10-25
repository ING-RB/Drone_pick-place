classdef (Hidden) LimitsComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    % This is a mixin parent class for visual components that have the
    % 'Limits' property.  Note this class does not support setting
    % the Limits to be inclusive or exclusive, they are always inclusive.

    properties(Dependent, AbortSet)
        Limits = [0 100];
    end

    properties(Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, beacuse sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateLimits= [0 100];
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.Limits(obj, limits)

            % Error Checking
            rowVectorLimits = matlab.ui.control.internal.model.PropertyHandling.validateFiniteLimitsInput(obj, limits);

            % property setting
            obj.PrivateLimits = rowVectorLimits;

            % properties to mark dirty
            commonDirtyProperties = {'Limits'};

            % additional updates like Value or ScaleColorLimits
            additionalDirtyProperties = obj.updatePropertiesAfterLimitsChange();

            % combine list properties
            combinedProperties = [additionalDirtyProperties,commonDirtyProperties];

            obj.markPropertiesDirty(combinedProperties);
        end

        function limits = get.Limits(obj)
            limits = obj.PrivateLimits;
        end
    end
    
    methods(Access = 'protected')
        
        function updatedProperties = updatePropertiesAfterLimitsChange(obj)
            % Perform any additional work to react to the limits change.
            % Returns any additional properties that should be marked dirty
            
            % no-op by default
            updatedProperties = {};
        end
        
    end
    
end