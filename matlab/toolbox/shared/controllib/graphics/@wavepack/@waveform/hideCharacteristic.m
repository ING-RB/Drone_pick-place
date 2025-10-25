function hideCharacteristic(this, CharID)
%hideCharacteristic  hide characteristics

%  Copyright 2009-2010 The MathWorks, Inc.


wfChar = this.Characteristics(strcmpi(get(this.Characteristics,'Identifier'), ...
      CharID));

if ~isempty(wfChar)
    set(wfChar,'Visible','off');
end


