function addlisteners(this,L)
%ADDLISTENERS  Installs listeners.

%  Copyright 2022 The MathWorks, Inc.
if nargin==1
   % Install built-in listeners
   L = [handle.listener(this, this.findprop('Model'),'PropertyPostSet', @LocalUpdate)];
   set(L, 'CallbackTarget', this);
end
this.Listeners = [this.Listeners ; L];


function LocalUpdate(this, ~)
% Clear dependent data
reset(this)
% Notify peers
this.send('SourceChanged')