function drillUp(this)

%

%   Copyright 2021 The MathWorks, Inc.

% Shift focus from the currently focused object to its parent. 

focused_obj = this.FocusedObject;

% If no object is currently in focus, nothing to do, so return.
if(isempty(focused_obj))
    return;
end

% Get the parent of the object currently in focus. 
parent_obj = focused_obj.Parent;

% If the parent object is the figure itself, then remove focus from the
% current object, since focus has gone to the figure. 

if(isa(parent_obj, 'matlab.ui.Figure'))
    this.removeFocusIndicator(this.FocusedObject);
    this.FocusedObject = [];
    
    obj_list = this.getListOfChildren(parent_obj);
    this.ObjectList = obj_list;
    return;
end

% If the parent object is not the figure, then get focus to the parent
% object
this.removeFocusIndicator(this.FocusedObject);
this.FocusedObject = parent_obj;

% Set focus indicator and make screen-reader announcement for the newly
% focused object
this.focus(this.FocusedObject);

% Update the object list with the siblings of the newly focused object;
this.ObjectList = this.getListOfChildren(this.FocusedObject.Parent);

end

