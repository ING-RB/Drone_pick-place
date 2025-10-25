classdef (Hidden) FontStyledComponent < appdesservices.internal.interfaces.model.AbstractModelMixin & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer & ...
        matlab.mixin.CustomElementSerialization
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that support
    % font customization.
    %
    % This class provides all implementation and storage for:
    %
    % * FontName        String representing the font family name
    % * FontSize        Number representing font size in pixels
    % * FontWeight      'normal' / 'bold' to control text emphasis
    % * FontAngle       'normal' / 'italic' to control text slant
    % * FontColor       3x1 numeric array represting the rgb color value
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        FontName = 'Helvetica';
        
        FontSize = 12;
        
        FontWeight = 'normal';
        
        FontAngle = 'normal';
    end
    
    properties (Dependent)
        % FontColor has its own validation and limited logic in the 
        % public setter.  There will be no PrivateFontColor storage
        % In order to cut down on the number of Private properties
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor = 'black';
        
    end

    properties(AbortSet, Hidden)
        FontColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBColor = 'black';
        FontColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
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
        
        PrivateFontName = 'Helvetica';
        
        PrivateFontSize = 12;
        
        PrivateFontWeight = 'normal';
        
        PrivateFontAngle = 'normal';
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.FontColor(obj, newFontColor)
            
            % Update Model
            obj.FontColorMode = 'manual';
            obj.FontColor_I = newFontColor;
        end
        
        function set.FontColor_I(obj, newFontColor)
            
            % Update Model
            obj.FontColor_I = newFontColor;
            
            % Update View
            markPropertiesDirty(obj, {'FontColor'});
        end

        function fontColor = get.FontColor(obj)
            fontColor = obj.FontColor_I;
        end

        function set.FontColorMode(obj, modeValue)
            % Update Model
            obj.FontColorMode = modeValue;
            if modeValue == "auto"
                matlab.graphics.internal.themes.refreshThemedValue(obj, 'FontColor')
            end
        end

        function set.FontName(obj, newFontName)
            % Error Checking
            %
            % Must be a non empty char
            try
                % Convert to char if string
                newFontName = convertStringsToChars(newFontName);
                
                validateattributes(newFontName, ...
                    {'char'}, ...
                    {'row'});
                
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidFontName', ...
                    'FontName');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidFontName';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end
            
            % Property Setting
            obj.PrivateFontName = newFontName;
            
            % Update View
            markPropertiesDirty(obj, {'FontName'});
        end
        
        function value = get.FontName(obj)
            value = obj.PrivateFontName;
        end
        
        
        function set.FontSize(obj, newFontSize)
            % Error Checking
            %
            % Must be a positive number
            try
                validateattributes(newFontSize, ...
                    {'double'}, ...
                    {'scalar', 'finite', 'real', '>',0} ...
                    );
                
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidFontSize', ...
                    'FontSize');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidFontSize';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);

            end
            
            % Property Setting
            obj.PrivateFontSize = newFontSize;
            
            % Update View
            markPropertiesDirty(obj, {'FontSize'});
        end
        
        function value = get.FontSize(obj)
            value = obj.PrivateFontSize;
        end
        
        
        function set.FontAngle(obj, newFontAngle)
            % Error Checking
            %
            % Must be 'normal' or 'italic'
            try
                newFontAngle =  matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString...
                    (obj, ...
                    newFontAngle, ...
                    {'normal', 'italic'});
                
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTwoStringEnum', ...
                    'FontAngle', 'normal', 'italic');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidFontAngle';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateFontAngle = newFontAngle;
            
            % Update View
            markPropertiesDirty(obj, {'FontAngle'});
        end
        
        function value = get.FontAngle(obj)
            value = obj.PrivateFontAngle;
        end
        
        
        function set.FontWeight(obj, newFontWeight)
            % Error Checking
            %
            % Must be 'normal' or 'italic'
            try
                newFontWeight =  matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString...
                    (obj, ...
                    newFontWeight, ...
                    {'normal', 'bold'});
                
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTwoStringEnum', ...
                    'FontWeight', 'normal', 'bold');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidFontWeight';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.doSetPrivateFontWeight(newFontWeight);
            
            % Update View
            markPropertiesDirty(obj, {'FontWeight'});
        end
        
        function value = get.FontWeight(obj)
            value = obj.PrivateFontWeight;
        end
    end

    methods (Access = protected)

        function doSetPrivateFontWeight(obj, newValue)
            
            % Property Setting with access to sub classes
            obj.PrivateFontWeight = newValue;
        end
    end

    methods (Hidden, Static) 

        function modifyOutgoingSerializationContent(sObj, obj) 
            % sObj is the information that will be serialized for obj.

            % Serialize FontColor_I as FontColor so that this information
            % can be loaded in older releases that didn't have a
            % FontColor_I property.
            sObj.rename('FontColor_I', 'FontColor'); 
        end 

        function modifyIncomingSerializationContent(sObj) 

            legacyDefaultFontColor = validatecolor('black');
            if ~sObj.hasNameValue('FontColor')
                sObj.addNameValue('FontColor',legacyDefaultFontColor);
            end
            if ~sObj.hasNameValue('FontColorMode')
                if isequal(sObj.getValue('FontColor'), legacyDefaultFontColor)
                    sObj.addNameValue('FontColorMode','auto');
                else
                    sObj.addNameValue('FontColorMode','manual');
                end
            end
            % Rename FontColor to FontColor_I so that the FontColorMode
            % property is not unnecessarily flipped to manual.
            sObj.rename('FontColor', 'FontColor_I');
        end 

    end 
end


