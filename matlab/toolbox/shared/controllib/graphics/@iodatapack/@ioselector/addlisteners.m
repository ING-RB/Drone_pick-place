function addlisteners(h,L)
%ADDLISTENERS  Installs listeners.

%   Copyright 2013 The MathWorks, Inc.
if nargin==1
   % Targeted listeners
   prc = [h.findprop('InputName');h.findprop('OutputName');...
         h.findprop('InputSelected');h.findprop('OutputSelected')];
   L = [handle.listener(h,prc,'PropertyPostSet',@update);...
         handle.listener(h,h.findprop('Visible'),'PropertyPostSet',@LocalSetVisible);...
         handle.listener(h,'ObjectBeingDestroyed',@LocalCleanUp)];
   set(L,'CallbackTarget',h);
end
% Add to list
h.Listeners = [h.Listeners ; L];

%------------------------ Local Functions ---------------------------

function LocalSetVisible(this,eventdata)
% Makes selector visible
if strcmp(eventdata.NewValue,'on')
   % Sync GUI with selector state
   update(this);
end  
set(this.Handles.Figure,'Visible',eventdata.NewValue)

function LocalCleanUp(this,eventdata)
% Delete figure
if ishandle(this.Handles.Figure)
   delete(this.Handles.Figure)
end

