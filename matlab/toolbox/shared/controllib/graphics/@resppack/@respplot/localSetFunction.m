function valueStored = localSetFunction(this, ProposedValue, Prop)
% Setfunctions

% Copyright 2015 The MathWorks, Inc.

switch Prop
    case {'InputName','OutputName'}
        valueStored = LocalSetValue(this,ProposedValue);  
end


%----------------------LOCAL SET FUCTIONS---------------------------------%

function valueStored = LocalSetValue(this, ProposedValue)

valueStored = ProposedValue(:);