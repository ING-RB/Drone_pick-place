function navigateForward(this)

%

%   Copyright 2021 The MathWorks, Inc.

% Shift focus from the currently focused object to the next object in the
% same level in the hierarchy 

focused_obj = this.FocusedObject;

% The object list is the list of all objects in the same level as the
% currently focused graphics object.
obj_list = this.ObjectList;
num_objects = length(obj_list);

% If there are no elements in the object list, return early.
if(isempty(obj_list))
    return;
end

if(isempty(focused_obj))
    % If no object currently has focus, give focus to the first object in the
    % object list.
    this.FocusedObject = obj_list(1);
    
else
    % Remove focus indicator from the currently focused object.
    this.removeFocusIndicator(this.FocusedObject);

    % Find the index of the currently focused object
    idx = find(obj_list == this.FocusedObject);

    % Get the index of the object that is going to receive focus
    new_idx = idx+1;
    if(new_idx == num_objects+1)
        new_idx = 1;
    end
    this.FocusedObject = obj_list(new_idx);
    
end

% Set focus indicator and make screen-reader announcement for the newly
% focused object
this.focus(this.FocusedObject);

end

