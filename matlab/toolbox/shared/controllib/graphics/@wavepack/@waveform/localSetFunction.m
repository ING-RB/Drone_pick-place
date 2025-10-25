function valueStored = localSetFunction(this, ProposedValue, Prop)
% Setfunctions

% Copyright 2015 The MathWorks, Inc.

switch Prop
    case 'Name'
        valueStored = LocalSetName(this,ProposedValue);  
end


%----------------------LOCAL SET FUCTIONS---------------------------------%

% ------------------------------------------------------------------------%
% Function: LocalSetName
% Purpose:  Update Group legendinfo for legend when name changes
% ------------------------------------------------------------------------%
function ProposedValue = LocalSetName(this, ProposedValue)

this.updateGroupInfo(ProposedValue);