function h = addioselector(this)
%ADDIOSELECTOR  Builds I/O selector for response plot.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

[OutputNames,InputNames] = getrcname(this);

% Set selector I/O labels
ni = length(InputNames);
if ni==0
   InputLabels = {''};
else
   for ct=ni:-1:1
      InputLabels(ct,1) = {getString(message('Controllib:plots:strInIndex',ct))};
   end
end
no = length(OutputNames);
if no==0
   OutputLabels = {''};
else
   for ct=no:-1:1
      OutputLabels(ct,1) = {getString(message('Controllib:plots:strOutIndex',ct))};
   end
end

% Build selector
h = ctrluis.axesselector(max(1,[no ni]),...
   'Name',getString(message('Controllib:gui:strIOSelector')),...
   'RowName',OutputLabels,...
   'ColumnName',InputLabels);

% Center dialog
centerfig(h.Handles.Figure,this.AxesGrid.Parent);

% Install listeners that keep selector and response plot in sync
p1 = [h.findprop('RowSelection');h.findprop('ColumnSelection')];
p2 = [this.findprop('InputVisible');this.findprop('OutputVisible')];
L1 = [handle.listener(h,p1,'PropertyPostSet',{@LocalSetIOVisible this});...
      handle.listener(this,p2,'PropertyPostSet',{@LocalSetSelection h})];
L2 = [handle.listener(this,'ObjectBeingDestroyed',@LocalDelete);...
      handle.listener(this,this.findprop('Visible'),'PropertyPostSet',@LocalSetVisible)];
set(L2,'CallbackTarget',h);
h.addlisteners([L1;L2])

%------------------ Local Functions -------------------------------

function LocalSetIOVisible(eventsrc,eventdata,this)
OnOff = {'off','on'};
switch eventsrc.Name
case 'RowSelection'
   this.OutputVisible = OnOff(1+eventdata.NewValue);
case 'ColumnSelection'
   this.InputVisible = OnOff(1+eventdata.NewValue);
end

function LocalSetSelection(eventsrc,eventdata,h)
switch eventsrc.Name
case 'OutputVisible'
   h.RowSelection = strcmp(eventdata.NewValue,'on');
case 'InputVisible'
   h.ColumnSelection = strcmp(eventdata.NewValue,'on');
end

function LocalDelete(h,eventdata)
if ishandle(h.Handles.Figure)
   delete(h.Handles.Figure)
end
delete(h)

function LocalSetVisible(h,eventdata)
% REVISIT: push/pop would be better
if strcmp(eventdata.NewValue,'off')
   h.Visible = 'off';
end
