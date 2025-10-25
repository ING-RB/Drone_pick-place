function exportedSymbols = getSymbolsFromDEFFile(defFile)
% GETSYMBOLSFROMDEFFILE parses the DEF file and extracts exported symbol names
%   GETSYMBOLSFROMDEFFILE(DEFFILE)
%
%   Input Arguments
%   ----------
%   DEFFILE           -- DEF file that is generated from a shared library
%   (DLL) file on Windows.
%
%   Output Arguments
%   ----------
%   EXPORTEDSYMBOLS   -- Exported symbols extracted from DEF file.
%

%  Copyright 2020 The MathWorks, Inc.

   exportedSymbols = '';
   defFile = strrep(defFile,'"','');
   defFileConstructs = strtrim(string(splitlines(fileread(defFile))));
   ind1= find(startsWith(defFileConstructs, 'ordinal hint RVA      name'));
   ind2 = find(startsWith(defFileConstructs, 'Summary'));
   defFileConstructs = defFileConstructs(ind1+1:ind2-1);
   % If there are no function signatures for symbols available in the
   % DEF file then throw an error
   if isempty(defFileConstructs)
       return;
   end
   defFileConstructs = defFileConstructs(defFileConstructs~="");
   % regex to parse definition of type
   % "         1    0 00011023 ??0A@@QEAA@H@Z = @ILT+30(??0A@@QEAA@H@Z)"
   result = regexp(defFileConstructs, '\w+\s*\w+\s*\w+\s*(?<name>.*)','names','forceCellOutput');
   % result: array of structures that has names of the definitions
   result= [result{:}];
   exportedSymbols = [result.name];
   exportedSymbols = strrep(exportedSymbols,' ','');
end