function addlisteners(this,L)
%ADDLISTENERS  Installs listeners.

%  Copyright 1986-2017 The MathWorks, Inc.
if nargin==1
   % Install built-in listeners
   L = handle.listener(this, this.findprop('Model'),'PropertyPostSet', @LocalUpdate);
   set(L, 'CallbackTarget', this);
end
this.Listeners = [this.Listeners ; L];

% ----------------------------------------------------------------------------%
% Purpose:  Respond to change in model data
% ----------------------------------------------------------------------------%
function LocalUpdate(this, ~)
% NOTE: Closed-loop stability flag must be manually cleared or updated 
% (e.g., in TuningGoal.Margins for consistency with SYSTUNE) prior to 
% modifying Model property and triggering this callback. This flag is 
% not affected by this callback (unlike in @ltisource where callback 
% resets the cache).
this.send('SourceChanged')