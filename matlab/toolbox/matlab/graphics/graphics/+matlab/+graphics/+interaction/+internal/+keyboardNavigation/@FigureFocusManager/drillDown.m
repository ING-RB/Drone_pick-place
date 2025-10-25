function drillDown(this)

%

%   Copyright 2021 The MathWorks, Inc.

% Shift focus from the currently focused object to its children. 

focused_obj = this.FocusedObject;

% If no object is currently in focus, nothing to do, so return.
if(isempty(focused_obj))
    return;
end

child_list = this.getListOfChildren(focused_obj);

% If there are no children, this is the deepest object in the hierarchy, so
% return early as there's nothing to do. 
if(isempty(child_list))
    return;
end


% If the currently focused object does have children, then pass focus to
% the first child. 
this.removeFocusIndicator(this.FocusedObject);
this.ObjectList = child_list;
this.FocusedObject = child_list(1);

% Set focus indicator and make screen-reader announcement for the newly
% focused object
this.focus(this.FocusedObject);

end

