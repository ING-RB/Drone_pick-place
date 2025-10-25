function addlisteners(this,L)
%ADDLISTENERS  Default implementation.

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2008 The MathWorks, Inc.

% Initialization. First install generic listeners
if nargin==1
   this.generic_listeners;
else
   this.Listeners.addListeners(L);
end