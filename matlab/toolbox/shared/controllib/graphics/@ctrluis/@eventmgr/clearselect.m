function clearselect(h,Containers)
%CLEARSELECT  Clear list of selected objects

%   Author: P. Gahinet
%   Copyright 1986-2004 The MathWorks, Inc.

if nargin==1 | ...
        (~isempty(h.SelectedContainer) & any(h.SelectedContainer==Containers))
    set(h.SelectedObjects,'Selected','off')
    h.SelectedObjects = [];
end