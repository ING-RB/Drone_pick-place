function [str,ShowName] = rcinfo(this,Row,~)
%RCINFO  Constructs data tip text locating @iowave in axes grid.
%
%   The boolean SHOWNAME indicates that at least one of the names is 
%   user-defined (nonempty).

%   Copyright 2013 The MathWorks, Inc.

ShowName = 1; % always show channel name in data tips
yNames = this.Parent.OutputName;
uNames = this.Parent.InputName;
ny = length(yNames);
if Row > ny
   uName = uNames{Row-ny};
   if isempty(uName)
      str = sprintf('Ch(%d)',this.InputIndex(Row-ny));
   else      
      str = uName;
   end
else
   yName = yNames{Row};
   if isempty(yName)
      str = sprintf('Ch(%d)',this.OutputIndex(Row));
   else 
      str = yName;
   end   
end

str =  getString(message('Controllib:plots:strChannelLabel',str));
