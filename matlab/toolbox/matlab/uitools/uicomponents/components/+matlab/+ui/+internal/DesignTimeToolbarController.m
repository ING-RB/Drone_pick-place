classdef DesignTimeToolbarController < ...
        matlab.ui.internal.controller.WebToolbarController & ...
        matlab.ui.internal.DesignTimeGbtParentingController
    
    % DesignTimeToolbarController - A toolbar controller class which
    % encapsulates the design-time specific behaviour and establishes the
    % gateway between the Model and the View
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods
        function obj = DesignTimeToolbarController( model, parentController, proxyView, adapter)
            % CONSTRUCTOR
            
            % Input verification
            narginchk(4, 4);
            
            % Construct the run-time controller
            obj = obj@matlab.ui.internal.controller.WebToolbarController(model, parentController, proxyView);
            
            % Construct the appdesigner base class controllers
            obj = obj@matlab.ui.internal.DesignTimeGbtParentingController(model, parentController, proxyView, adapter);
        end
    end
end