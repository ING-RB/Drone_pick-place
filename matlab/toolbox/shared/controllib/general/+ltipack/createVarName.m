function Name = createVarName(Name)
% Turn identifier into valid variable name. Used to convert user-specified 
% block identifiers into valid Control Design block names in slTunable.

%   Copyright 2011-2013 The MathWorks, Inc.
if ~isvarname(Name)
   % Make sure first char is not a number
   if ~isempty(regexp(Name(1),'\d','ONCE'))
      Name = ['a',Name];
   end
   
   % Replace invalid variable name characters with "_"
   Name = regexprep(Name, '\W', '_', 'ignorecase');
   
   % Remove multiples "_"
   Name = regexprep(Name, '[_]+', '_', 'ignorecase');
   
   % Remove leading and traling "_"
   Name = regexprep(Name, '[_]$','');
   Name = regexprep(Name, '^[_]','');
   
   % If name is greater than max name length truncate it
   if length(Name) > namelengthmax
      Name = Name(length(Name)-namelengthmax+1:end);
      % Make sure first char of truncated name is a letter
      if ~isletter(Name(1))
          Name(1) = 'a';
      end
   end
   
   if ~isvarname(Name)
      % Failed to generate valid var name
      error(message('Controllib:general:UnexpectedError','Failed to generate a valid variable name.'))
   end
end

