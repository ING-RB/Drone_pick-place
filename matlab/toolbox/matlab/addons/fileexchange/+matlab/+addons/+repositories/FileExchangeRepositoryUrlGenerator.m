classdef (Hidden = true) FileExchangeRepositoryUrlGenerator
% Builds URLs that conform to File Exchange's HTTP-based registry API.

% Copyright 2018-2020 The MathWorks, Inc.

    properties (SetAccess = public, GetAccess = private)
        BaseUrl;
    end

    methods
        % Constructor
        function obj = FileExchangeRepositoryUrlGenerator
            try
                urlManager = matlab.internal.UrlManager;

                obj.BaseUrl = urlManager.FILEEXCHANGE_REPOSITORY;
            catch
                obj.BaseUrl = "https://addons.mathworks.com/registry/v1";
            end
        end

        % The URL to get metadata about an add-on repository.
        %
        % Example: https://addons.mathworks.com/api/v1
        function url = repositoryMetadataUrl(obj)
            url = obj.generateUrl;
        end

        % The URL to get metadata about an add-on.
        %
        % Example: https://addons.mathworks.com/api/v1/00000000-0000-0000-0000-000000000000
        function url = addonMetadataUrl(obj, uuid)
            url = obj.generateUrl(uuid);
        end

        % The URL to get metadata about a version of an add-on.
        %
        % Example: https://addons.mathworks.com/api/v1/00000000-0000-0000-0000-000000000000/1.0.0.0
        function url = addonVersionMetadataUrl(obj, uuid, version)
            url = obj.generateUrl(uuid, version);
        end

        % The URL to get metadata about the packages associated with a
        % version of an add-on.
        %
        % Example: https://addons.mathworks.com/api/v1/00000000-0000-0000-0000-000000000000/1.0.0.0/-/packages
        function url = addonPackagesUrl(obj, uuid, version)
            url = obj.generateUrl(uuid, version, "-", "packages");
        end
    end

    methods (Access = private)
        function url = generateUrl(obj, varargin)
            url = strjoin([obj.BaseUrl varargin], "/");
        end
    end
end

% LocalWords:  Exchange's
