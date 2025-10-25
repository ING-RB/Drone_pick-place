classdef (Hidden) IconableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have the
    % 'Icon' properties
    %
    % This class provides all implementation and storage for 'Icon'
    
    % Copyright 2014-2023 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        Icon = ''; 
    end
    
    properties(Access = {?matlab.ui.control.internal.model.mixin.IconableComponent, ...
            ?matlab.ui.control.internal.controller.mixin.IconableComponentController})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateIcon = '';
    end

    properties(Transient, Access = protected)
        % Determine if this object supports preset icons on the client.
        % The default is true. Subclasses can opt out if they would like. 

        AllowedPresets = matlab.ui.internal.IconUtils.PresetIcon;
    end
    
    properties(Transient, Access = {?matlab.ui.control.internal.model.mixin.IconableComponent, ...
            ?matlab.ui.control.internal.controller.mixin.IconableComponentController, ...
            ?matlab.ui.internal.componentframework.services.optional.ControllerInterface})
        % Internal properties
        %
        % Store IconURL to use in Icon validation and processing
        %
        % This is transient so it does not get serialized, the file
        % information must reload when coming from a MAT file.
        % processIcon() updates IconType property
        
        IconType = '';
        PrivateIconURL = '';
        PrivateIconURLRequiresRead = true;
    end
    
    properties(Dependent, Transient, Access = {?matlab.ui.control.internal.model.mixin.IconableComponent, ...
            ?matlab.ui.control.internal.controller.mixin.IconableComponentController,...
            ?matlab.ui.internal.componentframework.services.optional.ControllerInterface,...
            ?matlab.graphics.mixin.ViewPropertiesManager})
        % Internal properties
        %
        % Store IconURL to use in Icon validation and processing
        %
        % This is transient so it does not get serialized, the file
        % information must reload when coming from a MAT file.
        % processIcon() updates IconType property
        
        IconURL;

    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        
        function set.Icon(obj, newValue)
            % Error Checking for valid and readable file
            [obj, isWarning, newValue] = obj.processIcon(obj, newValue);
            
            % Set Icon to new value and mark property dirty only when no 
            % warning occurs
            if ~(isWarning)
                % Store the value
                obj.PrivateIcon = newValue;
                
                obj.PrivateIconURLRequiresRead = true;

                % When the Icon property is marked dirty, App Designer gets the corresponding IconURL value.
                % PrivateIconURLRequiresRead should be set to true before marking the Icon as dirty,
                % so that App Designer fetches the latest IconURL.

                % Update View
                markPropertiesDirty(obj, {'Icon'});
            end
        end
        
        function value = get.Icon(obj)
            value = obj.PrivateIcon;
        end
        
        function iconURL = get.IconURL(obj)
            % IconURL - View representation of the value stored in the Icon
            % property
            iconURL = obj.PrivateIconURL;
            
            % Read icon if necessary (has changed and is not empty)
            if obj.PrivateIconURLRequiresRead
                iconURL = '';
                
                if ~isempty(obj.Icon)
                    try
                        iconURL = matlab.ui.internal.IconUtils.getIconForView(obj.Icon, obj.IconType);
                        obj.PrivateIconURLRequiresRead = false;
                    catch ex
                        % Create and throw warning
                        messageText = getString(message('MATLAB:ui:components:UnexpectedErrorInImageSourceOrIcon', 'Icon'));
                        matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, 'UnexpectedErrorInImageSourceOrIcon', ...
                            messageText, ':\n%s', ex.getReport());
                    end
                end
                
                % Store URL
                obj.PrivateIconURL = iconURL;
            end
        end
    end
    
    methods(Access='private', Static=true, Hidden=true)
        function [obj, isWarning, newValue] = processIcon(obj, newValue)
            isWarning = false;
            % Error Checking for valid and readable file
            try
                % string conversion for newValue
                newValue = convertStringsToChars(newValue);
                % validate the given icon    
                [newValue, iconType] = matlab.ui.internal.IconUtils.validateIcon(newValue);
                
                % Throw error for 'preset' icon type since its not supported
                % for Iconable components
                if strcmp(iconType, 'preset') && ~any(strcmp(obj.AllowedPresets,newValue)) 
                    % Throw error on invalid Icon
                    throwAsCaller(MException(message('MATLAB:ui:components:invalidIconFile')));
                end
                % Store the iconType value
                obj.IconType = iconType;
                
            catch ex
                % Get messageText from exception
                messageText = ex.message;
                % MnemonicField is last section of error id
                mnemonicField = ex.identifier(regexp(ex.identifier,'\w*$'):end);
                
                if strcmp(mnemonicField, 'invalidIconNotInPath') || strcmp(mnemonicField, 'cannotReadIconFile') || strcmp(mnemonicField, 'unableToWriteCData')
                    % Warn and proceed when Icon file is not in path or cannot be read.
                    % This is done, so that the app can continue working when 
                    % it is loaded and when the Icon file is invalid or dont
                    % exist
                    
                    % isWarning is used in set.Icon()
                    isWarning = true;
                    matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, mnemonicField, messageText);
                else
                    % Create and throw exception for errors related to
                    % invalidIconFormat, cannotReadIconFile, invalidIconFile
                    % and any other errors related to Icon
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, '%s', messageText);
                    throwAsCaller(exceptionObject);
                end
            end
        end
    end
    
     methods(Access='public', Static=true, Hidden=true)
      function hObj = doloadobj( hObj) 

          
         % Restore Icon on load
         % 1. The model (as opposed to the controller) owns loading the 
         % Icon 
         %    a. to get the end user the most responsive error message
         %    b. because sometimes the controller is destroyed in
         %    restructuring workflows where loading the icon in the
         %    controller is wasteful
         % 2. Pre 17b - The Icon data wasn't read in the model.  Older
         % components loaded into 17b+ won't have icon data stored in them
         % 
         % Thus, the whole workflow of reading and storing the icon is
         % completely transient.
         
        % hObj may be an Iconable Object or struct
        if (isstruct(hObj) && isfield(hObj, 'Icon')) ||...
            (isgraphics(hObj) && isprop(hObj, 'Icon'))
        
            [hObj, ~, ~] = matlab.ui.control.internal.model.mixin.IconableComponent.processIcon(hObj, hObj.Icon);
        end

      end
   end
end
