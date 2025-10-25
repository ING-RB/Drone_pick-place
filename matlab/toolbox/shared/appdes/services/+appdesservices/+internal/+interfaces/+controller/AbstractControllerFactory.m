classdef AbstractControllerFactory < handle
    % ABSTRACTCONTROLLERFACTORY Interface for a factory that creates
    % controllers.
    % 
    % The main purpose of the factory is to localize the logic related to
    % creating controllers.  Putting the logic on one place helps decouple
    % the specification of what controllers to use vs. the logic of
    % communicating between model, views, and controllers.
    
    % Copyright 2012 MathWorks, Inc.
    
    methods(Abstract)
        % CONTROLLER = CREATECONTROLLER(OBJ, MODEL,
        % PARENTCONTROLLER)
        %
        % Creates a controller for the given model.
        %
        % Input:
        %
        %   model:                  Handle to the model object
        %
        %   parentController:       Handle to the model's Parent's
        %                           Controller.  This should be empty if
        %                           there is no parent.
        %
        % Outputs:
        %
        %   controller:             Controller for the given model
        
        controller = createController(obj, model, parentController, proxyView)
    end
end

