classdef (Hidden) EnableableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have an
    % 'Enable' property
    %
    % This class provides all implementation and storage for 'Enable'
    
    % Copyright 2012-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        Enable matlab.internal.datatype.matlab.graphics.datatype.on_off = 'on';
    end
    
    properties(Access = 'private')
        % Internal properties
        %
        % These exist to provide: 
        % - fine grained control for each property
        %
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateEnable matlab.internal.datatype.matlab.graphics.datatype.on_off = 'on';
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.Enable(obj, newEnable)
            
            % Error Checking done through the datatype specification
            
            % Property Setting
            obj.PrivateEnable = newEnable;
            
            % Update View
            markPropertiesDirty(obj, {'Enable'});
        end
        
        function value = get.Enable(obj)
            value = obj.PrivateEnable;
        end
    end
end
