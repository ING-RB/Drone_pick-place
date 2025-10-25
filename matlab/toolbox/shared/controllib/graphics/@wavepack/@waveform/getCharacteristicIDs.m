function [CharIDs,CharLabels,CharGroups] = getCharacteristicIDs(this)
%setCharacteristics  Sets waveforms characteristics

%  Copyright 2009-2010 The MathWorks, Inc.

if isempty(this.CharacteristicManager)
    CharIDs = {''};
    CharLabels = {''};
    CharGroups = {''};
else
    CharIDs = {this.CharacteristicManager.CharacteristicID};
    CharLabels = {this.CharacteristicManager.CharacteristicLabel};
    CharGroups = {this.CharacteristicManager.CharacteristicGroup};
end