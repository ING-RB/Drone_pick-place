classdef AbstractControllerMixin < matlab.ui.internal.componentframework.services.optional.ControllerInterface
    % AbstractControllerMixin is a marker interface for any class that will
    % be inherited from by an
    % appdesservices.internal.interfaces.controller.AbstractController.
    %
    % Classes that do not lend themselves to a typical inheritence
    % hierarchy, but rather a mixin hierarchy, should use this class.
    %
    % Inheriting from this class allow "friend" permissions to call methods
    % on AbstractController without actually having to be an AbstractController.
    
    % Copyright 2012-2015 MathWorks, Inc.
    
end

