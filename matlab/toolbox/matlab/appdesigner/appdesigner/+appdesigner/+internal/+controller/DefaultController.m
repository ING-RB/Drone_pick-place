classdef DefaultController < appdesservices.internal.interfaces.controller.AbstractController
    %DefaultController A generic controller that performs the base
    %implementation of AbstractController
    
    % Copyright 2017 The MathWorks, Inc.
    
    methods        
        function obj = DefaultController(model, proxyView)
            % constructor for the controller
            obj = obj@appdesservices.internal.interfaces.controller.AbstractController(model, [], proxyView);
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
