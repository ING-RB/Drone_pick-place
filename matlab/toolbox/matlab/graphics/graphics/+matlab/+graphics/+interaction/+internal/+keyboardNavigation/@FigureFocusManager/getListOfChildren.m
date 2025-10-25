function children = getListOfChildren(~, hObj)

%

%   Copyright 2021-2022 The MathWorks, Inc.

% This function takes in a graphics object as input and returns an array
% with the list of elements in the next level of the hierarchy. This
% includes all the named children of the object, as well as other objects
% that may be handle invisible. 

% For e.g, an axes must return its title, subtitle, labels (if any), and
% all named children which are present in its "Children" property


% Note: Currently, only graphics objects define a list of focusable
% children. So objects like figures and other uicomponents don't yet have a
% way to specify their list of focusable children. 

arr = [];

if(isa(hObj, 'matlab.ui.Figure'))
    rev_arr = hObj.Children;
    arr = flip(rev_arr);
end

if(isa(hObj, 'matlab.graphics.mixin.Focusable'))
    arr = hObj.getFocusableChildren();
end

children = arr;

end


