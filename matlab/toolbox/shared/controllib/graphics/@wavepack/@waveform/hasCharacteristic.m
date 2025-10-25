function [b,idx] = hasCharacteristic(this,CharID)
%hasCharacteristic  Determines if characteristics exists

%  Copyright 2009-2010 The MathWorks, Inc.

if isempty(this.CharacteristicManager)
    b = false;
    idx = [];
else
    idx = find(strcmp(CharID,{this.CharacteristicManager.CharacteristicID}));
    b = ~isempty(idx);
end


