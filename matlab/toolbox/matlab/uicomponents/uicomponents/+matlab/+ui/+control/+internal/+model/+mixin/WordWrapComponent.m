classdef (Hidden) WordWrapComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have a
    % 'Text' property which supports text wrapping.
    %
    % This class provides all implementation and storage for 'WordWrap'
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        WordWrap matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
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
        
        PrivateWordWrap matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
    end
            
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.WordWrap(obj, newValue)
            % Error Checking
            
            % Property Setting
            obj.doSetPrivateWordWrap(newValue)
            
            % Update View
            markPropertiesDirty(obj, {'WordWrap'});
        end
        
        function value = get.WordWrap(obj)
            value = obj.PrivateWordWrap;
        end
    end

    methods (Access = protected)

        function doSetPrivateWordWrap(obj, newValue)
            
            % Property Setting with access to sub classes
            obj.PrivateWordWrap = newValue;
        end
    end
end
