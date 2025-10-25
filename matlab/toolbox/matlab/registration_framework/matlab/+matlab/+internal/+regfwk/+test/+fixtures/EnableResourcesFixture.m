classdef EnableResourcesFixture < matlab.unittest.fixtures.Fixture
    %

    % Copyright 2024 The MathWorks, Inc.
    properties(SetAccess=immutable,Hidden)
        % Folders - String absolute paths for the folders to be enabled.
        %
        %   The Folders property is a string array representing the absolute
        %   paths to folders enabled by the RegistrationFramework when the fixture is
        %   set up.
        Folders(1,:) string{mustBeNonempty} = missing;

        % ResourceSpecifications
        %
        %   The ResourceSpecifications object / array for the resources to be subscribed to.
        ResourceSpecifications matlab.internal.regfwk.ResourceSpecification
    end

    properties(SetAccess=private)
        TestRegistrationPoint matlab.internal.regfwk.TestRegistrationPoint
        SubscriptionObject matlab.internal.regfwk.SubscriptionObject
    end

    methods
        function fixture = EnableResourcesFixture(folders, resourceSpecifications)
            %   FIXTURE = EnableResourcesFixture(FOLDERS, RESOURCESPECIFICATIONS) constructs a fixture for adding FOLDERS to
            %   the MATLAB path. The fixture subscribes and waits for notifications from specific
            %   resources inside all such root folders using the provided RESOURCESPECIFICATIONS.
            %
            arguments
                folders string {mustBeNonempty, mustBeNonzeroLengthText}
                resourceSpecifications = []
            end
            fixture.Folders = convertCharsToStrings(folders);
            for folder=folders
                if ~isfolder(fullfile(folder, 'resources'))
                    error(message("registration_framework:reg_fw_resources:doesNotContainResourcesFolder", folder));
                end
            end
            if ~isempty(resourceSpecifications)
                fixture.ResourceSpecifications = resourceSpecifications;
                fixture.TestRegistrationPoint = matlab.internal.regfwk.TestRegistrationPoint(fixture.Folders);
                fixture.SubscriptionObject = matlab.internal.regfwk.subscribe([fixture.ResourceSpecifications], fixture.TestRegistrationPoint);
            end
        end

        function folders = get.Folders(fixture)
            folders = fixture.Folders;
        end

        function resourceSpecifications = get.ResourceSpecifications(fixture)
            resourceSpecifications = fixture.ResourceSpecifications;
        end

        function delete(fixture)
            if (~isempty(fixture.SubscriptionObject))
                fixture.SubscriptionObject.unsubscribe();
            end
        end
    end

    methods(Hidden)
        function setup(fixture)
            import matlab.unittest.constraints.Eventually;
            import matlab.unittest.constraints.IsEqualTo;
            % disable filesystem watching to suppress updated notifications affecting the system under test
            matlab.internal.regfwk.disableFilesystemWatching();

            matlab.internal.regfwk.enableResources(fixture.Folders);
            matlab.internal.mvm.test.flush_cache();

            if ~isempty(fixture.ResourceSpecifications)
                % wait for notifications for all resources from each root folder
                fixture.assertThat(@() fixture.TestRegistrationPoint.RootFoldersState, ...
                    Eventually(IsEqualTo("enabled"), "WithTimeoutOf", 5));
                for folder=fixture.Folders
                    fixture.assertEqual(matlab.internal.regfwk.getFolderState(folder), "enabled");
                end
            else
                % poll until all folders are enabled
                for folder=fixture.Folders
                    folderState = matlab.internal.regfwk.getFolderState(folder);
                    if ~strcmp(folderState, "enabled")
                        matlab.internal.regfwk.enableResources(folder);
                        fixture.assertThat( @()matlab.internal.regfwk.getFolderState(folder), ...
                            Eventually(IsEqualTo("enabled")), ...
                            "Failed to enable resource at " + folder );
                    end
                end
            end
        end

        function teardown(fixture)
            import matlab.unittest.constraints.Eventually;
            import matlab.unittest.constraints.IsEqualTo;

            matlab.internal.regfwk.unregisterResources(fixture.Folders);
            matlab.internal.mvm.test.flush_cache();

            if ~isempty(fixture.ResourceSpecifications)
                fixture.assertThat(@() fixture.TestRegistrationPoint.RootFoldersState, ...
                    Eventually(IsEqualTo("unregistered"), "WithTimeoutOf", 5));
                for folder=fixture.Folders
                    fixture.assertEqual(matlab.internal.regfwk.getFolderState(folder), "unregistered");
                end
            else
                % poll until all folders are unregistered
                for folder=fixture.Folders
                    folderState = matlab.internal.regfwk.getFolderState(folder);
                    if ~strcmp(folderState, "unregistered")
                        matlab.internal.regfwk.unregisterResources(folder);
                        fixture.assertThat( @()matlab.internal.regfwk.getFolderState(folder), ...
                            Eventually(IsEqualTo("unregistered")), ...
                            "Failed to unregister resource at " + folder );
                    end
                end
            end

            % restore filesystem watching
            matlab.internal.regfwk.enableFilesystemWatching();
        end
    end

    methods(Access=protected, Hidden)
        function bool = isCompatible(fixture, other)
            bool = isequal(sort(fixture.Folders),sort(other.Folders)) && isequal(fixture.ResourceSpecifications, other.ResourceSpecifications);
        end
    end
end
