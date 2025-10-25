function overMe = findLowestManagedObject(buttonMotionEvent)
%FINDLOWESTMANAGEDOBJECT Find lowest object in the hg hierarchy with a pointer behavior.
%   OVERME = findLowestManagedObject(CURRENTPOINT) returns the lowest
%   object in the HG hierarchy that contains a pointer
%   behavior.
%
%   Copyright 2007-2014 The MathWorks, Inc.

% Begin search for an object with a pointerBehavior directly underneath the
% mouse pointer. If this object returned by hittest does not have a
% pointerBehavior, climb the HG tree of ancestors until either an object
% with a pointerBehavior is found or the root object is reached.
overMe.Handle = buttonMotionEvent.HitObject;
overMe.PointerBehavior = [];

while ~ishghandle(overMe.Handle,'root')
    overMe.PointerBehavior = iptGetPointerBehavior(overMe.Handle);
    if ~isempty(overMe.PointerBehavior)
        break;
    end
    overMe.Handle = get(overMe.Handle,'Parent');
end

% If no pointer behavior was found in the ancestor tree, return empty Handle
% and PointerBehavior.
if isempty(overMe.PointerBehavior)
    overMe.PointerBehavior = [];
    overMe.Handle = [];
end
