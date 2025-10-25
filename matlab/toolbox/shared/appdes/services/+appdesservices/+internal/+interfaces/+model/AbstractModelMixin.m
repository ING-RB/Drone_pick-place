classdef (Hidden) AbstractModelMixin < handle
    % AbstractModelMixin is a marker interface for any class that will be
    % inherited from by a matlab.ui.control.interfaces.AbstractModel.
    %
    % Classes that do not lend themselves to a typical inheritence
    % hierarchy, but rather a mixin hierarchy, should use this class.
    %
    % Inheriting from this class allow "friend" permissions to call methods
    % on AbstractModel without actually having to be an AbstractModel and
    % forcing a diamond - inheritence hierarchy on the model.
    
    % Copyright 2012 MathWorks, Inc.
end

