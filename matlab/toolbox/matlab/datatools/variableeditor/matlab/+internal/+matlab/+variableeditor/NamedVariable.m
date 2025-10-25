classdef NamedVariable < handle
    % NAMEDVARIABLE
    % An abstract class defining the methods for a Named Variable
    % A named variable is a variable with a name and workspace.

    % Copyright 2013-2024 The MathWorks, Inc.

    % Name
    properties (SetObservable=true)
        Name;
    end

    % Workspace
    properties (Access=protected)
        WorkspaceI;
    end

    properties (SetObservable=true, Dependent)
        Workspace;
    end
    methods
        % Workspace can be either a string or an object reference.  If it's
        % a handle object we want to make sure we're using weak references
        % so that we don't hand on to them and they can be garbage
        % collected
        function val = get.Workspace(this)
            if isa(this.WorkspaceI, "matlab.lang.WeakReference")
                val = this.WorkspaceI.Handle;
            else
                val = this.WorkspaceI;
            end
        end

        function set.Workspace(this, newValue)
            if isequal(this.WorkspaceI, newValue)
                return;
            end
            if isa(newValue, 'handle')
                this.WorkspaceI = matlab.lang.WeakReference(newValue);
            else
                this.WorkspaceI = newValue;
            end
        end
    end
end
