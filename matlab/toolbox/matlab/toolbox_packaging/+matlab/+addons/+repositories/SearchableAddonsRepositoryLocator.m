classdef SearchableAddonsRepositoryLocator < handle

    % Class for getting the list of Support Packages that support
    % matlab.internal.addons.SupportPackageInfoBase interface


    methods (Access = public, Static)
        function repositories = getRepositories()
            % store the instances in a map facilitate lookup by name
            repositories = containers.Map;

            packages = meta.package.fromName( 'matlab.addons.repositories' );
            classes = packages.ClassList;
            for i = 1:length(classes)
                if(~classes(i).Abstract) % skip the abstract class
                    % matlab.internal.addons.SupportPackageInfoBase must be a superclass
                    if(any(strcmp(superclasses(classes(i).Name), 'matlab.addons.repositories.SearchableAddonsRepository')))

                        try % if eval fails, we still want to go to the next one

                            %must have a constructor with no parameters
                            repositoryInstance = eval(horzcat(classes(i).Name, '()'));
                            repositoryName = classes(i).Name;

                            % Check to see if the name is already a key in the map
                            if(~repositories.isKey(repositoryName))
                                %add repository to the map
                                repositories(repositoryName) = repositoryInstance;
                            end

                        catch ME
                            %show warning and continue
                            warning("MATLAB:repositories:instantiation", '%s', ME.message);
                        end

                    end
                end
            end
        end

        function [availableFromRepository, availableVersions] = getAddOnInfo(guid)
            repositories = matlab.addons.repositories.SearchableAddonsRepositoryLocator.getRepositories();
            availableFromRepository = false;
            availableVersions = char.empty;
            for k = keys(repositories)
                key = k{1};
                repositoryInstance = repositories(key);
                try
                    availableFromRepository = repositoryInstance.hasAddon(guid);
                    if availableFromRepository
                        availableVersions = repositoryInstance.getAddonVersions(guid);
                        try
                            availableVersions = cellstr(availableVersions);
                            break;
                        catch ME
                            error(message( ...
                                'MATLAB:toolbox_packaging:packaging:InvalidRepositoryVersionType', ...
                                class(repositoryInstance)));
                        end
                    end
                catch ERROR
                    % catch error and move to the next entry
                    warning("MATLAB:addons:repository:searchWarning", "%s", ERROR.message);
                end
            end
        end

        function [availableInRepository, downloadURL, version] = getAddOnDownloadURL(name, guid, earliest, latest)
            repositories = matlab.addons.repositories.SearchableAddonsRepositoryLocator.getRepositories();
            guidAvailableInRepository = false;
            versionAvailableInRepository = false;
            downloadURL = '';
            version = '';
            for k = keys(repositories)
                key = k{1};
                repositoryInstance = repositories(key);
                try
                    guidAvailableInRepository = repositoryInstance.hasAddon(guid);
                catch ERROR
                    %catch error and move to the next entry
                    warning("MATLAB:addons:repository:searchWarning", "%s", ERROR.message);
                    guidAvailableInRepository = false;
                end
                if guidAvailableInRepository

                    try
                        [downloadURL, version] = matlab.addons.repositories.SearchableAddonsRepositoryLocator.getLatestCompatibleDownloadURL(repositoryInstance, name, guid, earliest, latest);
                        versionAvailableInRepository = true;
                        version = char(version);

                        try
                            validateattributes(downloadURL, {'string', 'char'},{'ndims',2});
                        catch ME
                            error(message( ...
                                'MATLAB:toolbox_packaging:packaging:InvalidRepositoryURLType', ...
                                class(repositoryInstance)));
                        end
                        downloadURL = char(downloadURL);
                        break;

                    catch ME
                        %only silently catch if unavailable version error,
                        %returns empty add-on info in that case
                        switch ME.identifier
                            case 'MATLAB:toolbox_packaging:packaging:UnavailableVersion'
                            otherwise
                                rethrow(ME)
                        end
                    end
                end
            end
            availableInRepository = guidAvailableInRepository && versionAvailableInRepository;
        end

        %Sorts the list of versions and chooses the last one
        function latestAcceptableVersion = getLatestInRange(repository, name, guid, earliest, latest)
            availableVersions = repository.getAddonVersions(guid);
            current = '';
            earliestVersion =  matlab.internal.addons.AddonVersion(earliest);
            latestVersion =  matlab.internal.addons.AddonVersion(latest);

            for i = numel(availableVersions):-1:1
                version = matlab.internal.addons.AddonVersion(availableVersions{i});
                %versions may or may not be sorted
                %check all to catch the latest
                isLater = isempty(current) || version>current;

                isInRange = version.isInRange(earliestVersion, latestVersion);

                if isInRange && isLater
                    current = version;
                end
            end

            if ~isempty(current)
                latestAcceptableVersion = current.getVersionString();
            else
                latestAcceptableVersion = [];
            end
        end

        function [url, latestAcceptableVersion] = getLatestCompatibleDownloadURL(repository, name, guid, earliest, latest)
            latestAcceptableVersion = matlab.addons.repositories.SearchableAddonsRepositoryLocator.getLatestInRange(repository, name, guid, earliest, latest);
            if isempty(latestAcceptableVersion)
                  error(message( ...
                            'MATLAB:toolbox_packaging:packaging:UnavailableVersion'));
            end

            url = repository.getAddonURL(guid, latestAcceptableVersion);
        end

    end
end
