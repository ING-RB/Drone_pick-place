function hio = addioselector(this)
%ADDIOSELECTOR  Builds I/O selector for the data plot.

%   Copyright 2013 The MathWorks, Inc.

s = this.IOSize;
yname = this.OutputName(1:s(1));
uname = this.OutputName(s(1)+(1:s(2)));
hio = iodatapack.ioselector(uname,yname);

% Center dialog
centerfig(hio.Handles.Figure,this.AxesGrid.Parent);

% Install listeners that keep selector and response plot in sync
p1 = [hio.findprop('InputSelected'); hio.findprop('OutputSelected')];
p2 = [this.findprop('InputVisible'); this.findprop('OutputVisible')];

L1 = [handle.listener(hio,p1,'PropertyPostSet',{@LocalSetIOVisible this s});...
   handle.listener(this,p2,'PropertyPostSet',{@LocalSetSelection hio s})];

L2 = [handle.listener(this,'ObjectBeingDestroyed',@LocalDelete);...
   handle.listener(this,this.findprop('Visible'),'PropertyPostSet',@LocalSetVisible)];

set(L2,'CallbackTarget',hio);

hio.addlisteners([L1;L2])

%-------------------------- Local Functions -------------------------------
function LocalSetIOVisible(eventsrc,eventdata,this,iosize)
OnOff = {'off','on'};
switch eventsrc.Name
   case 'InputSelected'
      this.OutputVisible(iosize(1)+(1:iosize(2))) = OnOff(1+eventdata.NewValue);
   case 'OutputSelected'
      this.OutputVisible(1:iosize(1)) = OnOff(1+eventdata.NewValue);
end

%--------------------------------------------------------------------------
function LocalSetSelection(eventsrc,eventdata,h,iosize)
On = strcmp(eventdata.NewValue,'on');
switch eventsrc.Name
   case 'OutputVisible'
      h.OutputSelected = On(1:iosize(1));
      h.InputSelected = On(iosize(1)+(1:iosize(2)));
   case 'InputVisible'
      % do nothing: iofrequency plot has a fixed 1 "input" (column)
end

%--------------------------------------------------------------------------
function LocalDelete(h,~)
if ishandle(h.Handles.Figure)
   delete(h.Handles.Figure)
end
delete(h)

%--------------------------------------------------------------------------
function LocalSetVisible(h,eventdata)
% REVISIT: push/pop would be better
if strcmp(eventdata.NewValue,'off')
   h.Visible = 'off';
end
