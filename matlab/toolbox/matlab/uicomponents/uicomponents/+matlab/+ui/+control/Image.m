classdef (Sealed, ConstructOnLoad=true) Image < ...
        matlab.ui.control.internal.model.ComponentModel & ...            
        matlab.ui.control.internal.model.mixin.PositionableComponent& ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.HorizontallyAlignableComponent & ...
        matlab.ui.control.internal.model.mixin.VerticallyAlignableComponent & ...     
        matlab.ui.control.internal.model.mixin.FocusableComponent & ...     
        matlab.ui.control.internal.model.mixin.URLComponent & ...   
        matlab.ui.control.internal.model.mixin.IconIDableComponent & ...
        matlab.ui.control.internal.model.mixin.AltTextComponent
    %

    % Do not remove above white space
    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        ScaleMethod = 'fit';
        ImageSource = '';
    end
    
    properties(Access = {?matlab.ui.control.internal.controller.ImageController})
        ImageType = '';
    end
    
    properties(Access = 'private')
        % Store property name so multiple components can use this mixin
        % when the Icon is stored in differnet property names Value/Icon
        
        PrivateScaleMethod = 'fit';
        PrivateImageSource = '';            
    end
    
    properties(NonCopyable, Dependent, AbortSet)
        
        ImageClickedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    properties(NonCopyable, Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
                        
        PrivateImageClickedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})        
        ImageClicked;
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = Image(varargin)
            %
            
            % Do not remove above white space
            % Override the default values
            defaultSize = [100, 100];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;
            
            obj.Type = 'uiimage';
            % override default value of HorizontalAlignment
            obj.HorizontalAlignment = 'center';
            
            parsePVPairs(obj,  varargin{:});
            
            obj.attachCallbackToEvent('ImageClicked', 'PrivateImageClickedFcn');
        end

        % ----------------------------------------------------------------------
        
        function set.ImageSource(obj, newValue)
            newValue = convertStringsToChars(newValue);
            % Error Checking
            try
                % validate the given image    
                [newValue, imageType] = matlab.ui.internal.IconUtils.validateIcon(newValue);
                
                % Throw error for 'preset' image type since its not supported
                % for Image component
                if strcmp(imageType, 'preset')
                    % Throw error on invalid ImageSource
                    throwAsCaller(MException(message('MATLAB:ui:components:InvalidImageSourceSpecified')));
                end
                
                % Property Setting is done inside try/catch so that
                % ImageSource and ImageType are not set and marked dirty 
                % when warning occurs
                obj.PrivateImageSource = newValue;
                obj.ImageType = imageType;

                obj.markPropertiesDirty({'ImageSource'});
            catch ex
                % MnemonicField is last section of error id
                mnemonicField = ex.identifier(regexp(ex.identifier,'\w*$'):end);
                % Get messageText from exception
                messageText = ex.message;
                
                if strcmp(mnemonicField, 'invalidIconNotInPath') || strcmp(mnemonicField, 'cannotReadIconFile') || strcmp(mnemonicField, 'unableToWriteCData')
                    % Warn and proceed when Image file cannot be read.
                    % This is done, so that the app can continue working when 
                    % it is loaded and when the Image file is invalid or dont
                    % exist
                    matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, mnemonicField, messageText);
                else
                    % Get Identifier specific for Iconable component as
                    % validateImageSource() throws error for Image Component.
                    if strcmp(mnemonicField, 'invalidIconFile')
                        messageText = getString(message('MATLAB:ui:components:InvalidImageSourceSpecified'));
                        mnemonicField = 'InvalidImageSourceSpecified';
                    end
                    % Create and throw exception for errors related to
                    % invalidIconFormat, cannotReadIconFile, InvalidImageSourceSpecified
                    % and any other errors related to Image
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throw(exceptionObject);
                end
            end
        end
        
        function value = get.ImageSource(obj)
            value = obj.PrivateImageSource;
        end
        
        % ----------------------------------------------------------------------
        function set.ScaleMethod(obj, newValue)
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    newValue, ...
                    {'fit', 'fill', 'none', 'scaledown', 'scaleup', 'stretch'});
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidSixStringEnum', ...
                    'ScaleMethod', 'fit', 'fill', 'none', 'scaledown', 'scaleup', 'stretch');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidScaleMethod';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            % Property Setting
            obj.PrivateScaleMethod = newValue; 
            
            obj.markPropertiesDirty({'ScaleMethod'});
        end
        
        function value = get.ScaleMethod(obj)
            value = obj.PrivateScaleMethod;
        end
    
        % ----------------------------------------------------------------------
        function set.ImageClickedFcn(obj, newValue)
            % Property Setting
            obj.PrivateImageClickedFcn = newValue; 
            
            obj.markPropertiesDirty({'ImageClickedFcn'});
        end
        
        function value = get.ImageClickedFcn(obj)
            value = obj.PrivateImageClickedFcn;
        end
    end
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'ImageSource', 'ScaleMethod', 'URL', 'ImageClickedFcn'};
                
        end
        
      function str = getComponentDescriptiveLabel(obj)
            % GETDESCRIPTIVELABELFORDISPLAY - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.AltText;
            if isempty(obj.AltText) && ~isempty(obj.Tooltip)
                str = obj.Tooltip;
            end
      end

      function isFocusable = isConfigurationFocusable(obj)
            % ISCONFIGURATIONFOCUSABLE - This function validates
            % whether the image component is in a focusable state.
            % Used by FocusableComponent mixin to determine programmatic
            % focusability.
            % Image is only focusable if ImageClickedFcn, URL, or AltText
            % is non-empty.
            if (isempty(obj.ImageClickedFcn) && ...
                    isempty(obj.URL) && ...
                    isempty(obj.AltText))
                isFocusable = false;
                msgTxt = getString(message('MATLAB:ui:components:ImageNotFocusable'));
                    mnemonicField = 'ImageNotFocusable';
                    matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj,mnemonicField,msgTxt);
            else
                isFocusable = true;
            end

      end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent(sObj);
        end 

    end 
end
