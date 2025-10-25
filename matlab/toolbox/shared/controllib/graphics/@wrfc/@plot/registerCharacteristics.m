function registerCharacteristics(this,varargin)
%registerCharacteristics  Registers characteristics
% registerCharacteristics(this,waveform)
% registerCharacteristics(this,ID,Label,Group,isVisible)

%  Copyright 2009-2011 The MathWorks, Inc.

isVisible = false;
if length(varargin)==1
    % registerCharacteristics(this,waveform)
    waveform = varargin{1};
    [CharIDs,CharLabels,CharGroups] = waveform.getCharacteristicIDs;
else
    % registerCharacteristics(this,ID,Label,Group,isVisible)
    CharIDs = varargin(1);
    CharLabels = varargin(2);
    CharGroups = varargin(3);
    isVisible  = varargin{4};
    waveform = [];
end
    
for ct = 1:numel(CharIDs)
    CharID = CharIDs{ct};
    [b,idx] = hasCharacteristic(this,CharID);
    if b && ~isempty(waveform)
        this.CharacteristicManager(idx).Waveforms = ...
            [this.CharacteristicManager(idx).Waveforms; waveform];
        if this.CharacteristicManager(idx).Visible
            showCharacteristic(waveform,CharID)
        end
    elseif ~b
        if isempty(this.CharacteristicManager)
            this.CharacteristicManager = struct(...
                'CharacteristicID', CharID, ...
                'CharacteristicLabel', CharLabels{ct}, ...
                'CharacteristicGroup', CharGroups{ct}, ...
                'Waveforms', waveform, ...
                'Visible', isVisible);
        else
            this.CharacteristicManager(end+1,1) = struct(...
                'CharacteristicID', CharID, ...
                'CharacteristicLabel', CharLabels{ct}, ...
                'CharacteristicGroup', CharGroups{ct}, ...
                'Waveforms', waveform, ...
                'Visible', isVisible);
        end
    end
end