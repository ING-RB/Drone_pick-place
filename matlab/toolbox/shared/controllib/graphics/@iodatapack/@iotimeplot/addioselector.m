function hio = addioselector(this)
%ADDIOSELECTOR  Builds I/O selector for the data plot.

%   Copyright 2013-2014 The MathWorks, Inc.

hio = iodatapack.ioselector(this.InputName,this.OutputName);
hio.InputSelected = strcmp(this.InputVisible,'on');
hio.OutputSelected = strcmp(this.OutputVisible,'on');

% Center dialog
centerfig(hio.Handles.Figure,this.AxesGrid.Parent);

% Install listeners that keep selector and response plot in sync
p1 = [hio.findprop('InputSelected');hio.findprop('OutputSelected')];
p2 = [this.findprop('InputVisible');this.findprop('OutputVisible')];
L1 = [handle.listener(hio,p1,'PropertyPostSet',{@LocalSetIOVisible this});...
   handle.listener(this,p2,'PropertyPostSet',{@LocalSetSelection hio})];
L2 = [handle.listener(this,'ObjectBeingDestroyed',@LocalDelete);...
   handle.listener(this,this.findprop('Visible'),'PropertyPostSet',@LocalSetVisible)];
set(L2,'CallbackTarget',hio);
hio.addlisteners([L1;L2])

%-------------------------- Local Functions -------------------------------
function LocalSetIOVisible(eventsrc,eventdata,this)
OnOff = {'off','on'};
switch eventsrc.Name
   case 'InputSelected'
      this.InputVisible = OnOff(1+eventdata.NewValue);
   case 'OutputSelected'
      this.OutputVisible = OnOff(1+eventdata.NewValue);
end

%--------------------------------------------------------------------------
function LocalSetSelection(eventsrc,eventdata,h)
switch eventsrc.Name
   case 'OutputVisible'
      h.OutputSelected = strcmp(eventdata.NewValue,'on');
   case 'InputVisible'
      h.InputSelected = strcmp(eventdata.NewValue,'on');
end

%--------------------------------------------------------------------------
function LocalDelete(h,eventdata)
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
