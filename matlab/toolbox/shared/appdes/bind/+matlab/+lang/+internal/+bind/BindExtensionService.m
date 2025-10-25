classdef BindExtensionService < handle
    %BINDEXTENSIONSERVICE Manages the bind extension points

    %   Copyright 2022-2023 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Extensions (1,1) dictionary
    end
    
    methods
        function obj = BindExtensionService()
            obj.Extensions = obj.initializeExtensions();
        end
    end

    methods (Static, Access=private)
        function extensions = initializeExtensions()

            extensions = dictionary(string.empty,...
                struct("className", {}, "destinationParameters", {}, "factory", {}, "sourceParameters",{}));

            % The extension point framework is not yet deployable and so
            % ignore finding extensions when in deployment (see g3170056)
            if ~isdeployed
                bindSpec = matlab.internal.regfwk.ResourceSpecification;
                bindSpec.ResourceName = "matlab.bind";
                resourceList = matlab.internal.regfwk.getResourceList(bindSpec);
    
                for i = 1:length(resourceList)
                    resources = resourceList(i);
                    for j = 1:length(resources.resourcesFileContents)
                        content = resources.resourcesFileContents(j);
                        extensions(content.className) = content;
                    end
                end
            end
        end
    end

end