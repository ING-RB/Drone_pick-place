function addlisteners(this,L)
%  ADDLISTENERS  Installs additional listeners for @diskmarginplot class.

%  Copyright 1986-2008 The MathWorks, Inc.
if nargin == 1
   % Initialization. First install generic listeners
   init_listeners(this);
else
   this.Listeners.addListeners(L);
end