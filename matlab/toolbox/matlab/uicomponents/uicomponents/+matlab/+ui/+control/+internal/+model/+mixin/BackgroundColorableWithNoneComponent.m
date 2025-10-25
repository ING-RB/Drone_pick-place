classdef (Hidden) BackgroundColorableWithNoneComponent < appdesservices.internal.interfaces.model.AbstractModelMixin & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer & ...
        matlab.mixin.CustomElementSerialization
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that support
    % background color customization.
    %
    % This class provides all implementation and storage for:
    %
    % * BackgroundColor   3x1 numeric array represting the rgb color value
    %                     or 'none' to mean transparent
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    
    properties (Dependent)
        % BackgroundColor has its own validation and limited logic in the 
        % public setter.  There will be no PrivateBackgroundColor storage
        % In order to cut down on the number of Private properties
        % BackgroundColor for label is special cased because it allows
        % 'none' as a valid value. 
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = 'none';
        
    end
    properties(AbortSet, Hidden)
        BackgroundColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = 'none';
        BackgroundColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
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

        function fontColor = get.BackgroundColor(obj)
            fontColor = obj.BackgroundColor_I;
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

            if ~sObj.hasNameValue('BackgroundColorMode')
                legacyDefaultBackgroundColor = 'none';
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


