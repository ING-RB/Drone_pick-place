function hideCharacteristic(this, CharID)
%hideCharacteristic  hide characteristics

%  Copyright 2009-2010 The MathWorks, Inc.


[b,idx] = hasCharacteristic(this,CharID);
if b
   this.CharacteristicManager(idx).Visible = false;
 
   wf = this.CharacteristicManager(idx).Waveforms;
   wf = wf(ishandle(wf));
   for ct = 1:numel(wf)
        hideCharacteristic(wf(ct), CharID)
   end
   this.AxesGrid.send('ViewChanged')

else
    ctrlMsgUtils.warning('Controllib:plots:CharacteristicNotSupported', CharID)
end

