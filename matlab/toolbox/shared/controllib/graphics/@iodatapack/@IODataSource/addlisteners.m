function addlisteners(this,L)
%ADDLISTENERS  Installs listeners.

%  Copyright 2013 The MathWorks, Inc.
if nargin==1
   % Install built-in listeners
   L = [handle.listener(this, this.findprop('IOData'),'PropertyPostSet', @localUpdate);...
      handle.listener(this, this.findprop('UsePreview'),'PropertyPostSet', @localUpdate)];
   set(L, 'CallbackTarget', this);
   
   L2 = addlistener(this.IOData, 'Data', 'PostSet', @(es,ed)localUpdate(this));
   this.IODataChangeListener = L2;
end

this.Listeners = [this.Listeners ; L];

%--------------------------------------------------------------------------
function localUpdate(this, ~)
% Response to change in original data.

% Notify peers
this.send('SourceChanged')
