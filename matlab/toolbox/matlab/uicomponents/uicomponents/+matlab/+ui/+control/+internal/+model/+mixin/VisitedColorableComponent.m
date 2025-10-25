classdef (Hidden) VisitedColorableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that support
    % visited color customization for links
    %
    % This class provides all implementation and storage for:
    %
    % * VisitedColor   3x1 numeric array represting the rgb color value     
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties (Constant, Transient, Access = 'private')
        
        DefaultVisitedColor = [128,0,128] / 256;    
    end

    properties (Dependent)
        % VisitedColor has its own validation and limited logic in the 
        % public setter.  There will be no PrivateVisitedColor storage
        % In order to cut down on the number of Private properties
        VisitedColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor = matlab.ui.control.internal.model.mixin.VisitedColorableComponent.DefaultVisitedColor;
        
    end
    
    properties(AbortSet, Hidden)
        VisitedColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBColor = matlab.ui.control.internal.model.mixin.VisitedColorableComponent.DefaultVisitedColor;
        VisitedColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
            
        function set.VisitedColor(obj, newColor)
            
            % Update Model
            obj.VisitedColorMode = 'manual';
            obj.VisitedColor_I = newColor;
        end
        function set.VisitedColor_I(obj, newVisitedColor)
            
            % Update Model
            obj.VisitedColor_I = newVisitedColor;
            
            % Update View
            markPropertiesDirty(obj, {'VisitedColor'});
        end

        function fontColor = get.VisitedColor(obj)
            fontColor = obj.VisitedColor_I;
        end

        function set.VisitedColorMode(obj, modeValue)
            % Update Model
            obj.VisitedColorMode = modeValue;
            if modeValue == "auto"
                matlab.graphics.internal.themes.refreshThemedValue(obj, 'VisitedColor')
            end
        end
    end

    methods (Hidden, Static) 

        function modifyOutgoingSerializationContent(sObj, obj) 
            % sObj is the information that will be serialized for obj.

            % Serialize VisitedColor_I as VisitedColor so that this information
            % can be loaded in older releases that didn't have a
            % VisitedColor_I property.
            sObj.rename('VisitedColor_I', 'VisitedColor'); 
        end 

        function modifyIncomingSerializationContent(sObj)
            if ~sObj.hasNameValue('VisitedColorMode')
                legacyDefaultVisitedColor = matlab.ui.control.internal.model.mixin.VisitedColorableComponent.DefaultVisitedColor;
                if isequal(sObj.getValue('VisitedColor'), legacyDefaultVisitedColor)
                    sObj.addNameValue('VisitedColorMode','auto');
                else
                    sObj.addNameValue('VisitedColorMode','manual');
                end
            end
            % Rename VisitedColor to VisitedColor_I so that the VisitedColorMode
            % property is not unnecessarily flipped to manual.
            if sObj.hasNameValue('VisitedColor')
                sObj.rename('VisitedColor', 'VisitedColor_I');
            end
        end

    end 
end


