function StoredValue = localGetFunction(this, StoredValue, Prop)
% getfunctions

% Copyright 2015 The MathWorks, Inc.

switch Prop
    case 'Listeners'
        StoredValue = LocalGetListenersValue(this,StoredValue);
end




function StoredValue = LocalGetListenersValue(this,StoredValue)
if isempty(this.ListenersData)
    this.ListenersData = controllibutils.ListenerManager;
end
StoredValue = this.ListenersData;