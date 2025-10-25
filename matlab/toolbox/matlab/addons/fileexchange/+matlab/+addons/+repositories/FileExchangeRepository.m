classdef FileExchangeRepository < matlab.addons.repositories.SearchableAddonsRepository
% Retrieve information about add-ons hosted on File Exchange.

% Copyright 2018 The MathWorks, Inc.

    properties (Access = private)
        HttpClient;
        UrlGenerator;
    end

    methods
        % Constructor
        function obj = FileExchangeRepository
            obj.HttpClient = matlab.addons.repositories.FileExchangeRepositoryClient;
            obj.UrlGenerator = matlab.addons.repositories.FileExchangeRepositoryUrlGenerator;
        end

        % Change the UrlGenerator's BaseUrl
        function setRepositoryUrl(obj, url)
            obj.UrlGenerator.BaseUrl = url;
        end

        % Change the HttpClient
        function setHttpClient(obj, httpClient)
            obj.HttpClient = httpClient;
        end

        % Determine whether an add-on exists in the repository.
        %
        % Returns false when the repository service returns status code 404.
        function exists = hasAddon(obj, uuid)
            try
                addonMetadata = obj.sendRepositoryRequest( ...
                    obj.UrlGenerator.addonMetadataUrl(uuid) ...
                );
            catch exception
                if strcmp(exception.identifier, "MATLAB:addons:repositories:NotFound")
                    exists = false;
                    return;
                else
                    rethrow(exception);
                end
            end

            exists = isfield(addonMetadata, "uuid");
        end

        % Get all of the available version numbers for an add-on.
        %
        % Returns an empty cell array when the repository returns an empty
        % array, or if the repository service returns status code 404.
        %
        % Throws MATLAB:addons:repositories:RepositoryError when the response does
        % not include a "versions" key.
        function versions = getAddonVersions(obj, uuid)
            try
                addonMetadata = obj.sendRepositoryRequest( ...
                    obj.UrlGenerator.addonMetadataUrl(uuid) ...
                );
            catch exception
                if strcmp(exception.identifier, "MATLAB:addons:repositories:NotFound")
                    versions = {};
                    return;
                else
                    rethrow(exception);
                end
            end

            if ~isfield(addonMetadata, "versions")
                obj.throwRepositoryError("Repository did not provide a list of versions");
            end

            if ~isempty(addonMetadata.versions)
                versions = addonMetadata.versions;
            else
                versions = {};
            end
        end

        % Get the URL for the toolbox package for the specified AddOn.
        % Version is optional, if not provided the latest version is used.
        %
        % Returns an empty string when the add-on is not packaged as a
        % toolbox (.mltbx) or zip, when the repository returns an empty list
        % of packages, or when the repository service returns status code 404.
        %
        % Throws MATLAB:addons:repositories:RepositoryError when the response does
        % not include a "packages" key, or when the package list contains
        % an object without a "type" or "url" key.
        function url = getAddonURL(obj, uuid, version)
            if ~exist("version", "var")
                version = "latest";
            end

            try
                packageMetadata = obj.sendRepositoryRequest( ...
                    obj.UrlGenerator.addonPackagesUrl(uuid, version) ...
                );
            catch exception
                if strcmp(exception.identifier, "MATLAB:addons:repositories:NotFound")
                    url = "";
                    return;
                else
                    rethrow(exception);
                end
            end

            if ~isfield(packageMetadata, "packages")
                obj.throwRepositoryError("Repository did not provide a list of packages");
            end

            if isempty(packageMetadata.packages)
                % There are no installable packages
                url = "";
                return;
            end

            if  ~isfield(packageMetadata.packages, "type") || ~isfield(packageMetadata.packages, "url")
                obj.throwRepositoryError("Repository did not provide a valid list of packages");
            end

            mltbx = packageMetadata.packages(strcmp({packageMetadata.packages.type}, "mltbx"));
            zip = packageMetadata.packages(strcmp({packageMetadata.packages.type}, "zip"));

            if ~isempty(mltbx)
                url = mltbx.url;
            elseif ~isempty(zip)
                url = zip.url;
            else
                % Packages are present, but there are no toolboxes or zips
                url = "";
            end
        end

        % Get the URL for a page with more information about the add-on.
        %
        % Throws MATLAB:addons:repositories:RepositoryError when the response does
        % not include a "url" key.
        function url = getAddonDetailsURL(obj, uuid, version)
            if ~exist("version", "var")
                version = "latest";
            end

            try
                versionMetadata = obj.sendRepositoryRequest( ...
                    obj.UrlGenerator.addonVersionMetadataUrl(uuid, version) ...
                );
            catch exception
                if strcmp(exception.identifier, "MATLAB:addons:repositories:NotFound")
                    url = "";
                    return;
                else
                    rethrow(exception);
                end
            end

            if ~isfield(versionMetadata, "url")
                obj.throwRepositoryError("Repository did not provide a URL");
            end

            url = versionMetadata.url;
        end

        % Get the repository name.
        %
        % For File Exchange, the repository name will be the fully-qualified
        % domain name where the registry is hosted (for example, "addons.mathworks.com").
        %
        % Throws MATLAB:addons:repositories:RepositoryError when the response does
        % not include a "repositoryName" key.
        function name = getRepositoryName(obj)
            repositoryMetadata = obj.sendRepositoryRequest( ...
                obj.UrlGenerator.repositoryMetadataUrl ...
            );

            if ~isfield(repositoryMetadata, "repositoryName")
                obj.throwRepositoryError("Repository did not provide a name");
            end

            name = repositoryMetadata.repositoryName;
        end
    end

    methods (Access = private, Hidden = true)
        function responseBody = sendRepositoryRequest(obj, url)
            responseBody = obj.HttpClient.get(url);
        end

        function throwRepositoryError(~, message)
            error("MATLAB:addons:repositories:RepositoryError", message)
        end
    end
end
