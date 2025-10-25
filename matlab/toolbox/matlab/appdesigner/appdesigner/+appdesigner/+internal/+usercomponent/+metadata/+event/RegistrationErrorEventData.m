classdef (ConstructOnLoad) RegistrationErrorEventData < event.EventData
    % This class holds data for RegistrationErrorEvent
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        RegistrationError MException
        ErrorMessage
    end
    
    methods
        function data = RegistrationErrorEventData(registrationError)
            data.RegistrationError = registrationError;
            data.getErrorMessage();
        end
        
        function getErrorMessage(data)
               import appdesigner.internal.usercomponent.metadata.Constants
            switch(data.RegistrationError.identifier)
                case 'MATLAB:MKDIR:OSError'
                    data.ErrorMessage = string(message([Constants.MessageCatalogPrefix, 'NoWriteAccessErrorMsg']));
                case 'MATLAB:ui:componentcontainer:ErrorWhileExecutingSetup'
                    data.ErrorMessage = data.RegistrationError.message;
                    if ~isempty(data.RegistrationError.cause) && ...
                        strcmp(data.RegistrationError.cause{1}.identifier, 'MATLAB:minrhs')
                            % this particular error is caused when a
                            % user-authored component does not support a
                            % no-input 'setup' method, ther exception
                            % thrown in this case has a 1*1 cause-cell
                            % array
                            data.ErrorMessage = string(message([Constants.MessageCatalogPrefix, 'NotEnoughInputArgErrorMsg']));
                    end
                otherwise
                    data.ErrorMessage = data.RegistrationError.message;
            end
        end
    end
end

