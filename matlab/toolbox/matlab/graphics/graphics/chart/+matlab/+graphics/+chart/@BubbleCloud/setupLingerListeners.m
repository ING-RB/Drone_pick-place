function setupLingerListeners(obj)
%

%   Copyright 2020-2022 The MathWorks, Inc.

% Add listeners that will respond when the mouse enter or exits a bubble,
% or lingers over a bubble

linger=matlab.graphics.interaction.actions.Linger(obj.Marker);
linger.IncludeChildren=false;
linger.LingerTime = 0.5;
linger.GetNearestPointFcn=@(~,e)LingerGetPoint(e);

obj.LingerListeners.EnterListener=addlistener(linger,'EnterObject', @(~,e)obj.LingerEvent(e));
obj.LingerListeners.ExitListener=addlistener(linger,'ExitObject', @(~,e)obj.LingerEvent(e));
obj.LingerListeners.LingerListener=addlistener(linger,'LingerOverObject', @(~,e)obj.LingerEvent(e));
obj.LingerListeners.ResetListener=addlistener(linger,'LingerReset', @(~,e)obj.LingerEvent(e));
linger.enable;

obj.Linger=linger;
end

function ind=LingerGetPoint(eventdata)
ind=nan;
hitobj=eventdata.HitObject;
if isa(hitobj,'matlab.graphics.primitive.world.Marker')
    d = abs(sum(eventdata.IntersectionPoint' - eventdata.HitObject.VertexData, 1));
    [~,ind] = min(d);
end
end
