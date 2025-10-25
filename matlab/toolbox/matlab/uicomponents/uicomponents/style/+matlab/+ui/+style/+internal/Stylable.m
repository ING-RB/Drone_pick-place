classdef (Hidden) Stylable < matlab.ui.style.internal.ComponentStyle & ...
        matlab.ui.style.internal.mixin.IconableStyle
        
    % STYLABLE - Contains style related properties for Style object
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties
        BackgroundColor = [];
        FontColor = [];
        FontWeight char = '';
        FontAngle char = '';
        FontName = '';
        HorizontalAlignment char = '';
        HorizontalClipping char = '';
        IconAlignment char = '';
        Interpreter char = '';
    end
    
    properties (Access = ?matlab.ui.style.internal.ComponentStyle)
        DisplayPropertyOrder = ["BackgroundColor", "FontColor", "FontWeight", "FontAngle", "FontName", "HorizontalAlignment", "HorizontalClipping", "Icon", "IconAlignment", "Interpreter"];
    end
       
    methods
        function obj = Stylable(varargin)
            obj = obj@matlab.ui.style.internal.ComponentStyle(varargin{:});
        end
        
        function obj = set.BackgroundColor(obj, newColor)
            
            % Validate background color
            newColor = obj.processColor(newColor);
            
            % Property Setting
            obj.BackgroundColor = newColor;
        end
        
        function obj = set.FontAngle(obj, newFontAngle)
            
            % Must be 'normal' or 'italic' or ''
            try
                newFontAngle =  matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString...
                    (obj, ...
                    newFontAngle, ...
                    {'normal', 'italic', ''});
                
            catch ME
                messageObj = message('MATLAB:ui:components:invalidThreeStringEnum', ...
                    'FontAngle', 'normal', 'italic', '');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidFontAngle';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
                
            end
            
            % Property Setting
            obj.FontAngle = newFontAngle;
            
        end
        
        function obj = set.FontColor(obj, newColor)
            
            % Validate font color
            newColor = obj.processColor(newColor);
            
            % Property Setting
            obj.FontColor = newColor;
        end
        
        function obj = set.FontName(obj, newFontName)
            
            % Convert string to char
            newFontName = convertStringsToChars(newFontName);
            
            % Must be empty or a row char vector
            if ~(ischar(newFontName) && isequal(newFontName, ''))
                try
                    
                    validateattributes(newFontName, ...
                        {'char'},...
                        {'row'});
                    
                catch ME
                    messageObj = message('MATLAB:ui:style:invalidName', ...
                        'FontName');
                    
                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidFontName';
                    
                    % Use string from object
                    messageText = getString(messageObj);
                    
                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throwAsCaller(exceptionObject);
                end
            end
            
            % Property Setting
            obj.FontName = newFontName;
        end
        
        function obj = set.FontWeight(obj, newFontWeight)
            
            % Must be 'normal' or 'bold'
            try
                newFontWeight =  matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString...
                    (obj, ...
                    newFontWeight, ...
                    {'normal', 'bold', ''});
                
            catch ME
                messageObj = message('MATLAB:ui:components:invalidThreeStringEnum', ...
                    'FontWeight', 'normal', 'bold', '');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidFontWeight';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
                
            end
            
            % Property Setting
            obj.FontWeight = newFontWeight;
        end
        
        function obj = set.HorizontalAlignment(obj, newAlignment)
            
            % Error Checking
            try
                newAlignment = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    newAlignment, ...
                    {'center', 'left', 'right', ''});
            catch ME
                messageObj = message('MATLAB:ui:components:invalidFourStringEnum', ...
                    'HorizontalAlignment', 'left', 'center', 'right', '');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidHorizontalAlignment';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
                
            end
            
            % Property Setting
            obj.HorizontalAlignment = newAlignment;
        end
        
        function obj = set.HorizontalClipping(obj, newClipping)
            
            % Error Checking
            try
                newClipping = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    newClipping, ...
                    {'left', 'right', ''});
            catch ME %#ok<*CTCH>
                messageObj = message('MATLAB:ui:components:invalidThreeStringEnum', ...
                    'HorizontalClipping', 'left', 'right', '');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidHorizontalClipping';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
                
            end
            
            % Property Setting
            obj.HorizontalClipping = newClipping;
        end
        
        function obj = set.IconAlignment(obj, newAlignment)
            
            % Error Checking
            try
                newAlignment = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    newAlignment, ...
                    {'left', 'right', 'center', 'leftmargin', 'rightmargin',''});
            catch ME %#ok<*CTCH>

                messageObj = message('MATLAB:ui:components:invalidSixStringEnum', ...
                    'IconAlignment', 'left', 'center', 'right','leftmargin','rightmargin','');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidIconAlignment';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
                
            end
            
            % Property Setting
            obj.IconAlignment = newAlignment;
        end

        function obj = set.Interpreter(obj, newInterpreter)
            
            % Error Checking
            try
                newInterpreter = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    newInterpreter, ...
                    {'', 'none', 'html', 'latex', 'tex', ''});
            catch ME %#ok<*CTCH>                

                messageObj = message('MATLAB:ui:components:invalidFiveStringEnum', ...
                    'Interpreter', 'none', 'html', 'latex', 'tex', '');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidInterpreter';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
            end
            
            % Property Setting
            obj.Interpreter = newInterpreter;
        end
    end
    
    methods (Access = private)
        
        function newColor = processColor(obj, newColor)
            % PROCESSCOLOR - Color must be empty or a valid rgb value as
            % defined by the graphics data type
            try
                if isequal(newColor, [])
                    newColor = [];
                else
                    newColor = hgcastvalue('matlab.graphics.datatype.RGBColor', newColor);
                end
                
            catch ME
                messageObj = message('MATLAB:ui:style:invalidColor');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidColor';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
                
            end
        end
    end
    
    methods (Access = ?matlab.ui.internal.SetGetDisplayAdapter)
        
        function linkDisplay(obj)
            % LINKDISPLAY - This method displays on the commandline all
            % properties in a display consistent with the property groups
            
            propertyGroupArray = matlab.mixin.util.PropertyGroup(properties(obj));
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj,propertyGroupArray);
        end
    end
end

