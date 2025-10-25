function addlisteners(this)
%  ADDLISTENERS  Installs additional listeners for @bodeview class.

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2011 The MathWorks, Inc.

% Initialization. First install generic listeners
this.generic_listeners;

% Add @timeplot specific listeners
L = handle.listener(this, 'ObjectBeingDestroyed', @LocalCleanUp);
set(L, 'CallbackTarget', this);
this.Listeners = [this.Listeners ; L];

%--------------------------------------------------------------------------
function LocalCleanUp(this, ~)
% Delete hg lines
delete(this.MagCurves(ishandle(this.MagCurves)))
