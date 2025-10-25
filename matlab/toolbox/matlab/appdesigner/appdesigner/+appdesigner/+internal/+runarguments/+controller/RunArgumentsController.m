classdef RunArgumentsController < appdesservices.internal.interfaces.controller.AbstractController
    %RUNARGUMENTSCONTROLLER A basic controller for use with RunArgumentsModel

    % Copyright 2022 The MathWorks, Inc.

    properties (Access=private)
        PropertiesSetListener
    end

    methods
        function obj = RunArgumentsController(model, proxyView)
            obj@appdesservices.internal.interfaces.controller.AbstractController(model, [], proxyView);
        end

        function populateView(obj, proxyView)
            populateView@appdesservices.internal.interfaces.controller.AbstractController(obj, proxyView);

            if ~isempty(proxyView) && ~isempty(proxyView.PeerNode)
                % Set up propertiesSet event listener
                obj.PropertiesSetListener = addlistener(proxyView.PeerNode, 'propertiesSet', ...
                    obj.wrapLegacyProxyViewPropertiesChangedCallback(@obj.handlePropertiesChanged));
            end
        end
    end

    methods(Access = protected)
        function handleEvent(~, ~, ~)
            % No-Op implemented for Base Class
        end

        function getPropertiesForView(~, ~)
            % No-Op implemented for Base Class
        end
    end
end
