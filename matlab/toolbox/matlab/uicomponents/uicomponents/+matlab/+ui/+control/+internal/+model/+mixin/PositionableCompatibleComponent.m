classdef (Hidden) PositionableCompatibleComponent < appdesservices.internal.interfaces.model.AbstractModelMixin & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
    % This undocumented class may be removed in a future release.
    %
    % This is a mixin base class for all visual components that shipped
    % before the position implementation was changed to use GBT Positionable mixins
    % This class has to be used if the component model used to derive from
    % matlab.ui.control.internal.model.mixin.PositionableComponent

    % Copyright 2016-2019 The MathWorks, Inc.
    
    
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = PositionableCompatibleComponent()
            % no-op
        end
    end
    
    properties(Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateInnerPosition matlab.internal.datatype.matlab.graphics.datatype.Position = [100, 100, 20, 20];
        
        PrivateOuterPosition matlab.internal.datatype.matlab.graphics.datatype.Position = [100, 100, 20, 20];
        
    end

    methods
        
        % should these be hidden and static? (Loadobj should be static)
        function output = saveobj(obj)
            output = obj;
            obj.PrivateOuterPosition = obj.OuterPosition;
            obj.PrivateInnerPosition = obj.InnerPosition;
        end
    end
    
    methods(Access='public', Static=true, Hidden=true)
        
        function obj = doloadobj(obj)
            % on component loading, property set will not trigger marking
            % dirty, so disable view property cache
            % Todo: enable it when we have a better design for loading
            % Todo: need a better way to disable cache instead of in invidudal
            % subclass
            obj.disableCache();
            obj.setPositionFromClient('positionChangedEvent', obj.PrivateInnerPosition, obj.PrivateOuterPosition);
        end
    end    
end

