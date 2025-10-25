function setDefaultName(this,WaveList)
%SETDEFAULTNAME  Assigns default name to unnamed waveforms.

%  Author(s): P. Gahinet
%  Copyright 1986-2013 The MathWorks, Inc.

% Resolve wave name
if isempty(this.Name)
   % Assign untitled## name when name is unspecified
   Names = get(WaveList,{'Name'});
   Names = [Names{:}];
   n = 1;
   while ~isempty(strfind(Names,sprintf('untitled%d',n)))
      n = n+1;
   end
   this.Name = sprintf('untitled%d',n);
end

