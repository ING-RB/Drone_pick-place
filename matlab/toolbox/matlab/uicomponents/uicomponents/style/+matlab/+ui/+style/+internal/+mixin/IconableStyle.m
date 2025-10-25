classdef (Hidden) IconableStyle
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have the
    % 'Icon' properties
    %
    % This class provides all implementation and storage for 'Icon'
    
    % Copyright 2021-2022 The MathWorks, Inc.
    
    properties(AbortSet)
        Icon = '';
    end
    
    properties(Transient, Access = {?matlab.ui.style.internal.mixin.IconableStyle,...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin,...
            ?matlab.ui.internal.controller.uitable.StylesManager})
        % Internal properties
        %
        % Store IconUri to use in Icon validation and processing
        %
        % This is transient so it does not get serialized, the file
        % information must reload when coming from a MAT file.
        % processIcon() updates IconType property

        IconType = '';
        IconUri = '';
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods

        function obj = set.Icon(obj, newValue)

            % Error Checking for valid and readable file
            [obj, isWarning, newValue, iconType, iconUri] = obj.processIcon(obj, newValue);

            % Set Icon to new value and mark property dirty only when no
            % warning occurs
            if ~(isWarning)
                % Store the value
                obj.Icon = newValue;
                obj.IconType = iconType;
                obj.IconUri = iconUri;
            end

        end
    end
    methods(Access='private', Static=true, Hidden=true)
        function [obj, isWarning, icon, iconType, iconUri] = processIcon(obj, newValue)
            isWarning = false;
            iconType = '';
            iconUri = '';
            icon = '';

            % Error Checking for valid and readable file
            try
                % string conversion for newValue
                newValue = convertStringsToChars(newValue);

                % allowed preset icons
                presetIcon = matlab.ui.internal.IconUtils.StatusAndNoneIcon;

                % validate the given icon
                [validatedNewValue, iconType] = matlab.ui.internal.IconUtils.validateIcon(newValue,presetIcon);

                if (isequal(newValue,'none'))
                    % We allow none as an iconUri for 2 reasons
                    % 1. This is in model with the dialogs which
                    % process a value of 'none' on the client
                    % 2. The styles infrastructure relies on the concept
                    % of empty == ignore. For this reason, we are
                    % forced to send 'none' to the client.
                    iconUri = 'none';
                    icon = 'none';
                elseif ~isempty(validatedNewValue)
                    % Read icon if file processing didn't throw error
                    try
                        icon = validatedNewValue;
                        iconUri = matlab.ui.internal.IconUtils.getIconForView(validatedNewValue, iconType);
                    catch ex
                        % Create and throw warning
                        messageText = getString(message('MATLAB:ui:components:UnexpectedErrorInImageSourceOrIcon', 'Icon'));
                        matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, 'UnexpectedErrorInImageSourceOrIcon', ...
                            messageText, ':\n%s', ex.getReport());
                    end
                end
            catch ex
                % Get messageText from exception
                messageText = ex.message;
                % MnemonicField is last section of error id
                mnemonicField = ex.identifier(regexp(ex.identifier,'\w*$'):end);

                if strcmp(mnemonicField, 'invalidIconNotInPath') || strcmp(mnemonicField, 'cannotReadIconFile')  || strcmp(mnemonicField, 'unableToWriteCData')
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
      function hObj = loadobj( hObj) 

          
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
            (isa(hObj, 'matlab.ui.style.internal.mixin.IconableStyle') && isprop(hObj, 'Icon'))
        
            % Error Checking for valid and readable file
            [hObj, isWarning, newValue, iconType, iconUri] = matlab.ui.style.internal.mixin.IconableStyle.processIcon(hObj, hObj.Icon);
            
            % Set Icon to new value and mark property dirty only when no 
            % warning occurs
            if ~(isWarning)
                % Store the value
                hObj.Icon = newValue;
                hObj.IconType = iconType;
                hObj.IconUri = iconUri;
            end
        end
      end
   end
end
