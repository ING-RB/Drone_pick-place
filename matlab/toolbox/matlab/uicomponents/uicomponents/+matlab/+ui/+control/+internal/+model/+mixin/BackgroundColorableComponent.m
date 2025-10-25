classdef (Hidden) BackgroundColorableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer & ...
        matlab.mixin.CustomElementSerialization
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that support
    % background color customization. The default is consistant with edit
    % field.
    %
    % This class provides all implementation and storage for:
    %
    % * BackgroundColor   3x1 numeric array represting the rgb color value     
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    
    properties (Dependent)
        % BackgroundColor has its own validation and limited logic in the 
        % public setter.  There will be no PrivateBackgroundColor storage
        % In order to cut down on the number of Private properties
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor = matlab.ui.control.internal.model.mixin.BackgroundColorableComponent.DefaultWhite;
        
    end
    
    properties(AbortSet, Hidden)
        BackgroundColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBColor = matlab.ui.control.internal.model.mixin.BackgroundColorableComponent.DefaultWhite;
        BackgroundColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
    end

    properties (Constant, Transient, Access = protected)
        % These values will be used to help standardize the colors commonly
        % used by the components as a default color. Components can choose
        % to use these color constants when constructing themselves.
        DefaultWhite = [1, 1, 1];
        DefaultGray = [.96, .96, .96];
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.BackgroundColor(obj, newColor)
            
            % Update Model
            obj.BackgroundColorMode = 'manual';
            obj.BackgroundColor_I = newColor;
        end
        function set.BackgroundColor_I(obj, newBackgroundColor)
            
            % Update Model
            obj.BackgroundColor_I = newBackgroundColor;
            
            % Update View
            markPropertiesDirty(obj, {'BackgroundColor'});
        end

        function backgroundColor = get.BackgroundColor(obj)
            backgroundColor = obj.BackgroundColor_I;
        end

        function set.BackgroundColorMode(obj, modeValue)
            % Update Model
            obj.BackgroundColorMode = modeValue;
            if modeValue == "auto"
                matlab.graphics.internal.themes.refreshThemedValue(obj, 'BackgroundColor')
            end
        end
    end

    methods (Hidden, Static) 

        function modifyOutgoingSerializationContent(sObj, obj) 
            % sObj is the information that will be serialized for obj.

            % Serialize BackgroundColor_I as BackgroundColor so that this information
            % can be loaded in older releases that didn't have a
            % BackgroundColor_I property.
            sObj.rename('BackgroundColor_I', 'BackgroundColor'); 
        end 

        function modifyIncomingSerializationContent(sObj) 
            legacyDefaultBackgroundColor = matlab.ui.control.internal.model.mixin.BackgroundColorableComponent.DefaultWhite;
            if ~sObj.hasNameValue('BackgroundColor')
                sObj.addNameValue('BackgroundColor',legacyDefaultBackgroundColor);
            end
            if ~sObj.hasNameValue('BackgroundColorMode')
                if isequal(sObj.getValue('BackgroundColor'), legacyDefaultBackgroundColor)
                    sObj.addNameValue('BackgroundColorMode','auto');
                else
                    sObj.addNameValue('BackgroundColorMode','manual');
                end
            end
            % Rename BackgroundColor to BackgroundColor_I so that the BackgroundColorMode
            % property is not unnecessarily flipped to manual.
            sObj.rename('BackgroundColor', 'BackgroundColor_I');
        end 

  end 
end


