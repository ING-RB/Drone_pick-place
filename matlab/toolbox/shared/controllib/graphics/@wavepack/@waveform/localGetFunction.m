function StoredValue = localGetFunction(this, StoredValue, Prop)
% getfunctions

% Copyright 2015 The MathWorks, Inc.

switch Prop
    case 'NameListener'
        StoredValue = LocalGetNameListenerValue(this,StoredValue);
    case 'SelectedListener'
        StoredValue = LocalGetSelectedListenerValue(this,StoredValue);
end




function StoredValue = LocalGetNameListenerValue(this,StoredValue)
if isempty(this.NameListenerData)
    this.NameListenerData = controllibutils.ListenerManager;
end
StoredValue = this.NameListenerData;

function StoredValue = LocalGetSelectedListenerValue(this,StoredValue)
if isempty(this.SelectedListenerData)
    this.SelectedListenerData = controllibutils.ListenerManager;
end
StoredValue = this.SelectedListenerData;