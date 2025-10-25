classdef DesignTimeIconHandler < appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController
    % DESIGNTIMEICONHANDLER - This class contains design time logic
    % specific to the handling of Icon and ImageSource properties.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    methods
        function [propertyValue, validationStatus, imageRelativePath] = validateImageFile(obj, propertyName, event)
            % VALIDATEIMAGEFILE - Validate the image file that the user
            % wants to use.
            % INPUTS:
            %   obj: MCOS object corresponding to the component's controller
            %   propertyName: property name that the user wants to set.
            %       Usually either Icon or ImageSource
            %   event: event structure.
            % OUTPUTS:
            %  propertyValue: char containing a valid file name,
            %       including extension if the image is on the path or a
            %       full path to the image if the image satisfies the
            %       relative path requirement
            %  validationStatus: logical indicating whether validation
            %       suceeded or not.
            %  imageRelativePath: The relative path from the MLAPP file to the
            %  image file

            validationStatus = true;
            additionalData = event.Data.AdditionalData;
            propertyValue = additionalData.PropertyValue;
            originalPropertyValue = event.Data.PropertyValue;
            imageRelativePath = additionalData.ImageRelativePath;
            imageRelativePathNoSpaces = imageRelativePath(find(~isspace(imageRelativePath)));
            % if the relative path that the user typed into the Inspector 
            % starts with ./ to indicate a file in the current folder, 
            % remove the ./ from the relative path property
            if strlength(imageRelativePath) > 2 && strcmp(imageRelativePath(1), '.') && (strcmp(imageRelativePath(2), '/') || strcmp(imageRelativePath(2), '\'))
                imageRelativePath = imageRelativePath(3:end);
            elseif strlength(imageRelativePathNoSpaces) > 2 && strcmp(imageRelativePathNoSpaces(1), '.') && (strcmp(imageRelativePathNoSpaces(2), '/') || strcmp(imageRelativePathNoSpaces(2), '\'))
                % if there is a space between the . and the /, show an error
                ex = MException(message('MATLAB:appdesigner:appdesigner:imageNotFoundErrorDialogText'));
                propertySetFail(obj, propertyName, event.Data.CommandId, ex);
                validationStatus = false;
                return;
            end
            % update the relative path with forward slashes
            imageRelativePath = strrep(imageRelativePath, '\', '/');
            % update the property value with the correct slashes for the OS
            propertyValue = fullfile(strrep(propertyValue, '\', '/'));
            enumValues = matlab.ui.internal.IconUtils.PresetIcon;
            componentsSupportingEnums = {
                    'appdesigner.internal.componentcontroller.DesignTimePushButtonController', ...
                    'appdesigner.internal.componentcontroller.DesignTimeStateButtonController', ...
                    'appdesigner.internal.componentcontroller.DesignTimeColorPickerController'
            };
            imageExtensionEnums = {'.png', '.jpg', '.jpeg', '.gif', '.svg'};
            
            [~, file, ext] = fileparts(propertyValue);
            imageName = [file ext];
                        
            % Only validate the file if the property value is non-empty
            % char or string
            if ~isempty(propertyValue) && ~isempty(ext) && (isa(propertyValue, 'char') || isa(propertyValue, 'string'))
                % if the image extension is not an accepted extension,
                % the validation status should be set to false
                if ~any(strcmpi(imageExtensionEnums, ext))
                    ex = MException(message('MATLAB:ui:components:invalidIconFormat', 'png, jpg, jpeg, gif, svg'));
                    propertySetFail(obj, propertyName, event.Data.CommandId, ex);
                    validationStatus = false;
                else
                    % if the file is an image that is on a relative path from
                    % the MLAPP, validate that it exists
                    if ~isempty(imageRelativePath) && exist(propertyValue, 'file') == 2
                        validationStatus = true;
    
                    % if the image is on the MATLAB path, but not a relative 
                    % path, it is valid. In this case, update the property
                    % value and relative path
                    % this can only be the case if the user provided an image
                    % name through the edit field of the Inspector or an
                    % absolute path if the File Explorer was used. If the user
                    % specified a relative path, we do not check if the image
                    % is on the MATLAB path.
                    elseif exist(imageName, 'file') == 2 && (strcmp(originalPropertyValue, imageName) || exist(originalPropertyValue, 'file') == 2)
                        propertyValue = imageName;
                        imageRelativePath = '';
                        
                    % if none of the above conditions are met, show an error
                    % message to the user
                    else
                        ex = MException(message('MATLAB:appdesigner:appdesigner:imageNotFoundErrorDialogText'));
                        propertySetFail(obj, propertyName, event.Data.CommandId, ex);
                        validationStatus = false;
                    end
                end
            
            % if the Icon property is a string without a file extention,
            % check if it is one of the supported Enums
            elseif isempty(ext) && any(strcmp(enumValues, imageName)) && ismember(class(obj), componentsSupportingEnums)
                propertyValue = imageName;
                imageRelativePath = '';

            % if the property is not a string/char and is not empty, show
            % an error message
            elseif ~isempty(propertyValue)
                ex = MException(message('MATLAB:appdesigner:appdesigner:imageNotFoundErrorDialogText'));
                propertySetFail(obj, propertyName, event.Data.CommandId, ex);
                validationStatus = false;
            end
        end
    end
end