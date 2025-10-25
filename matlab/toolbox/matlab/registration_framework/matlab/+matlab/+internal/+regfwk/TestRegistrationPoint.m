classdef TestRegistrationPoint < matlab.internal.regfwk.RegistrationPoint
    % TestRegistrationPoint is a concrete implementation of the RegistrationPoint abstract class.
    % It implements all the abstract methods and provides additional functionality for testing.

    % Copyright 2024 The MathWorks, Inc.

    properties
        RegisteredResourceInformations
        EnabledResourceInformations
        DisabledResourceInformations
        UnregisteredResourceInformations
        UpdatedResourceInformations
        InitialListOfResourceInformations
        RootFoldersState
        RootFolderResourceStates
    end

    methods
        function obj = TestRegistrationPoint(rootFolders)
            obj.RegisteredResourceInformations = {};
            obj.EnabledResourceInformations = {};
            obj.DisabledResourceInformations = {};
            obj.UnregisteredResourceInformations = {};
            obj.UpdatedResourceInformations = {};
            obj.InitialListOfResourceInformations = {};
            obj.RootFoldersState = "unregistered";
            if (nargin > 0 && ~isempty(rootFolders))
                if (ischar(rootFolders) || isstring(rootFolders))
                    rootFolders = convertCharsToStrings(rootFolders);
                end
                rootFolders = cellfun(@char, rootFolders, 'UniformOutput', false);
                obj.RootFolderResourceStates = containers.Map(rootFolders, repmat({'unregistered'}, size(rootFolders)));
            end
        end

        function registered(obj, resourceInformation)
            obj.RegisteredResourceInformations{end+1} = resourceInformation;
            obj.updateRootFolderResourceState(resourceInformation.rootFolder, "registered");
        end

        function unregistered(obj, resourceInformation)
            obj.UnregisteredResourceInformations{end+1} = resourceInformation;
            obj.updateRootFolderResourceState(resourceInformation.rootFolder, "unregistered");
        end

        function enabled(obj, resourceInformation)
            obj.EnabledResourceInformations{end+1} = resourceInformation;
            obj.updateRootFolderResourceState(resourceInformation.rootFolder, "enabled");
        end

        function disabled(obj, resourceInformation)
            obj.DisabledResourceInformations{end+1} = resourceInformation;
            obj.updateRootFolderResourceState(resourceInformation.rootFolder, "disabled");
        end

        function updated(obj, resourceInformation)
            obj.UpdatedResourceInformations{end+1} = resourceInformation;
        end

        function initialListReceived(obj, resourceInformations)
            obj.InitialListOfResourceInformations = resourceInformations;
        end

        function clearSubscriptionLists(obj)
            obj.RegisteredResourceInformations = {};
            obj.EnabledResourceInformations = {};
            obj.DisabledResourceInformations = {};
            obj.UnregisteredResourceInformations = {};
            obj.UpdatedResourceInformations = {};
        end

        function updateRootFolderResourceState(obj, rootFolder, state)
            if (isempty(obj.RootFolderResourceStates))
                return;
            end
            if obj.RootFolderResourceStates.isKey(rootFolder)
                obj.RootFolderResourceStates(rootFolder) = state;
                if all(strcmp(obj.RootFolderResourceStates.values, state))
                    obj.RootFoldersState = state;
                end
            end
        end
    end
end
