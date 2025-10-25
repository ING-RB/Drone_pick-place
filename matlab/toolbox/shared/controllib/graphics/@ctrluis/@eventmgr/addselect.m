function addselect(h,Object,Container)
%ADDSELECT  Adds selection to list of selected objects.

%   Copyright 1986-2024 The MathWorks, Inc.

if nargin==3
    % Reset container (automatically clears selection list if container differs from previous)
    h.SelectedContainer = Container;
end

h.SelectedObjects = [h.SelectedObjects ; Object];
h.SelectedListeners = [h.SelectedListeners ; ...
        event.listener(Object,'ObjectBeingDestroyed',@(hSrc,hData) LocalRemove(h,Object))];
end

function LocalRemove(h,Object)
h.rmselect(Object);
end