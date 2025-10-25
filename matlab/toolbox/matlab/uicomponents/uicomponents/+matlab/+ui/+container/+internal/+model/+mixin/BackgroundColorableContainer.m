classdef (Hidden) BackgroundColorableContainer < appdesservices.internal.interfaces.model.AbstractModelMixin & ...
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
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    
    properties (Dependent)
        % BackgroundColor for containers. This has additional validation to
        % prevent setting value as 'none'.
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = [.94, .94, .94];
        
    end
    properties(AbortSet, Hidden)
        BackgroundColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = [.94, .94, .94];
        BackgroundColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
    end
    properties (Constant, Transient, Access = protected)
        % These values will be used to help standardize the colors commonly
        % used by the components as a default color. Components can choose
        % to use these color constants when constructing themselves.
        DefaultWhite = [1, 1, 1];
        DefaultGray = [.94, .94, .94];
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.BackgroundColor(obj, newColor)
            validateBackgroundColor(obj, newColor);

            % Update Model
            obj.BackgroundColorMode = 'manual';
            obj.BackgroundColor_I = newColor;  
        end
        function set.BackgroundColor_I(obj, newBackgroundColor)
            
            % Update Model
            obj.BackgroundColor_I = newBackgroundColor;
            
            % Update View
            markPropertiesDirty(obj, {'BackgroundColor'});

            % Do post set
            postSetBackgroundColor(obj);
        end

        function color = get.BackgroundColor(obj)
            color = obj.BackgroundColor_I;
        end

        function set.BackgroundColorMode(obj, modeValue)
            % Update Model
            obj.BackgroundColorMode = modeValue;
            if modeValue == "auto"
                matlab.graphics.internal.themes.refreshThemedValue(obj, 'BackgroundColor')
            end
        end

        function postSetBackgroundColor(~)
            % No-op by default.
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
            legacyDefaultBackgroundColor = matlab.ui.container.internal.model.mixin.BackgroundColorableContainer.DefaultGray;
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
    
    methods(Access='private')
        function validateBackgroundColor(~, newColor)
            % 'none' is not supported
            if isstring(newColor) || ischar(newColor)
                if strcmpi(newColor, "none")
                    throwAsCaller(MException('MATLAB:hg:ColorSpec_None',message('MATLAB:hg:ColorSpec_None', 'GridLayout')));
                end
            end
        end
    end

    methods (Access = protected, Static)
        function map = getThemeMap(varargin)
            % Return a struct describing the relationship between class
            % properties and theme attributes.
            map = struct( ...
                'BackgroundColor',  '--mw-backgroundColor-primary');
        end
    end
end


