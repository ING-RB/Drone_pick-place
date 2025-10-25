function windowAncestor = findWindowAncestor(obj)
    % findWindowAncestor Recursively finds the Window ancestor of the given object.
    %
    % Syntax:
    %   windowAncestor = findWindowAncestor(obj)
    %
    % Description:
    %   This function recursively traverses the parent hierarchy of the given
    %   object and returns the first ancestor of type Window.
    %
    % Input Arguments:
    %   obj - The object from which to start the search.
    %
    % Output Arguments:
    %   windowAncestor - The ancestor object of type Window, or [] if no such
    %                    ancestor is found.
    %
    % Example:
    %   windowAncestor = findWindowAncestor(myButton);
    %
    % See also:
    %   isa

    % Initialize the window ancestor as empty
    windowAncestor = [];

    % Traverse the parent hierarchy
    currentObj = obj;
    while isprop(currentObj, 'Parent') && ~isempty(currentObj.Parent)
        % Move to the parent object
        currentObj = currentObj.Parent;

        % If the parent exists and is of type Window, return it
        if isa(currentObj, 'matlab.hwmgr.internal.hwsetup.Window')
            windowAncestor = currentObj;
            return;
        end
    end
end