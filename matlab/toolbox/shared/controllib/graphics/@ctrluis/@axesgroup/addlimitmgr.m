function addlimitmgr(h)
%ADDLIMITMGR  Install and activates limit manager.

%   Author(s): P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

% Listeners to limit-related properties
h.LimitListeners.deleteListeners;

p_limmode = [h.findprop('XLimMode');h.findprop('YLimMode')];
h.LimitListeners.addListeners(handle.listener(h,p_limmode,'PropertyPostSet',@LocalSetLimMode));

h.LimitListeners.addListeners(...
   event.proplistener(h.Axes2d(:), ...
    {findprop(h.Axes2d(1),'XLim'),findprop(h.Axes2d(1),'YLim')},'PostSet',@(es,ed) LocalSetLim(es,ed,h)));

h.LimitListeners.addListeners(...
    event.proplistener(h.Axes2d(:), ...
    findprop(h.Axes2d(1),'View'),'PostSet',@(es,ed) LocalSetAxesView(es,ed,h)));
% Listener to ViewChanged event (responsible for updating limits)
L = handle.listener(h,'ViewChanged',@LocalUpdateLims);
set(L,'CallbackTarget',h);
h.LimitListeners.addListeners(L);

% Listener enable state tracks LimitManager state
h.LimitListeners.setEnabled(strcmpi(h.LimitManager,'on'))


%-------------- Local functions -----------------------


function LocalSetLim(eventsrc,eventdata,h)
% Sets limit across axes grid
% Localize affected axes in axes grid
[i,j] = find(eventdata.AffectedObject==getaxes(h,'2d'));
% Set X or Y limits 
% RE: triggers limit update
try
   switch eventsrc.Name
   case 'XLim'
      setxlim(h,get(eventdata.AffectedObject,'XLim'),j)  
   case 'YLim'
      setylim(h,get(eventdata.AffectedObject,'YLim'),i)
   end
end

function LocalSetAxesView(~,eventdata,h)
% 'auto' mode limits do not
% trigger listeners. So we manually listen to the View property to make
% resetplotview refresh the limits.
try
    [i,j] = find(eventdata.AffectedObject==getaxes(h,'2d'));
    setxlim(h,get(eventdata.AffectedObject,'XLim'),j)
    setylim(h,get(eventdata.AffectedObject,'YLim'),i)
end

function LocalSetLimMode(eventsrc,eventdata)
% Postset for limit modes: trigger limit update
eventdata.AffectedObject.send('ViewChanged');   % RE: LimitManager='on' at this point


function LocalUpdateLims(h,eventdata)
% Limit management (callback for ViewChanged event)
if isvisible(h)
    % Turn off backdoor listeners
    h.LimitManager = 'off';
    % Issue PreLimitChanged event prior to calling limit picker
    h.send('PreLimitChanged') 
    % Update limits
    if iscell(h.LimitFcn)
        feval(h.LimitFcn{:})
    else
        feval(h.LimitFcn)
    end
    % Notify peers of axes limit update
    h.send('PostLimitChanged')  
    % Turn backdoor listeners back on
    h.LimitManager = 'on';
end