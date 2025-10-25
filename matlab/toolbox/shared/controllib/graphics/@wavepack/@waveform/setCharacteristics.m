function setCharacteristics(this,CharInfo)
%setCharacteristics  Sets waveforms characteristics

%  Copyright 2009-2010 The MathWorks, Inc.

this.CharacteristicManager = CharInfo;
registerCharacteristics(this.parent,this);