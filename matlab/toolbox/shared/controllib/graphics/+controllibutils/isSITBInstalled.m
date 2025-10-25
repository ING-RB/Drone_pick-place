function identfound  = isSITBInstalled
%ISSITBINSTALLED  Check if System Identification Toolbox is installed.

% Copyright 2013 The MathWorks, Inc.

persistent IsSITBInstalledVersionFlag;

if isempty(IsSITBInstalledVersionFlag)
   IsSITBInstalledVersionFlag = ~isempty(ver('ident'));
end

identfound = IsSITBInstalledVersionFlag && license('test', 'Identification_Toolbox');
