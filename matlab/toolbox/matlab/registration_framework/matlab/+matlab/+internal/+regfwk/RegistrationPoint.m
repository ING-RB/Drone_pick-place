classdef (Abstract) RegistrationPoint < handle
    % RegistrationPoint represents an interface for registration point actions.
    % This abstract class defines methods that must be implemented by subclasses.

%   Copyright 2024 The MathWorks, Inc.

    methods (Abstract)
        % Invokes registered on the RegistrationPoint with metadata after a folder is
        % registered
        %
        % @param resourceInformation: Contains metadata parsed from requested resources.
        registered(obj, resourceInformation)

        % Invokes unregister on the RegistrationPoint with metadata after a folder is
        % unregistered
        %
        % @param resourceInformation: Contains metadata parsed from requested resources.
        unregistered(obj, resourceInformation)

        % Invokes enable on the RegistrationPoint with metadata after a folder is enabled
        %
        % @param resourceInformation: Contains metadata parsed from requested resources.
        enabled(obj, resourceInformation)

        % Invokes disable on the RegistrationPoint with metadata after a folder is disabled
        %
        % @param resourceInformation: Contains metadata parsed from requested resources.
        disabled(obj, resourceInformation)

        % Invokes update on the RegistrationPoint with metadata after a folder is updated
        %
        % @param resourceInformation: Contains metadata parsed from requested resources.
        updated(obj, resourceInformation)

        % Invoked when the initial list is received after the subscription is made
        %
        % @param resourceInformations: Contains metadata parsed from requested resources.
        initialListReceived(obj, resourceInformations)
    end

    methods
        function handleNotification(obj, evt)
            resourceSpecification = jsondecode(evt.resourceSpecificationTag);
            resourceInformation = jsondecode(evt.resourceInformation);

            if (resourceInformation.updated == true)
                obj.updated(resourceInformation);
            else
                switch resourceInformation.resourceState
                    case 'registered'
                        obj.registered(resourceInformation);
                    case 'enabled'
                        obj.enabled(resourceInformation);
                    case 'disabled'
                        obj.disabled(resourceInformation);
                    case 'unregistered'
                        obj.unregistered(resourceInformation);
                    otherwise
                        warning(strcat('Unexpected notification with incorrect state: ', resourceInformation.resourceState));
                end
            end
        end

        function handleInitialList(obj, evt)
            resourceInformations = jsondecode(evt.resourceInformations);
            obj.initialListReceived(resourceInformations);
        end
    end
end
