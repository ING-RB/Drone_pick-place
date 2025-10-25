function showCharacteristic(this, CharID)
%showCharacteristic  Show characteristics

%  Copyright 2009-2010 The MathWorks, Inc.


wfChar = this.Characteristics(strcmpi(get(this.Characteristics,'Identifier'), ...
      CharID));
% Create new instance if no match found
if isempty(wfChar)
    [~,idx] = hasCharacteristic(this, CharID);
    CharInfo = this.CharacteristicManager(idx);
    wfChar = this.addchar(...
        CharInfo.CharacteristicID, ...
        CharInfo.CharacteristicData, ...
        CharInfo.CharacteristicView);
end
 
set(wfChar,'Visible','on');

