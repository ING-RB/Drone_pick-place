function newvarFromVarEditor(varName)

% Disambiguate variables in linked plots when creating new variables from
% brushing annotations.

% Copyright 2008-2024 The MathWorks, Inc.

% Build and show Disambiguation dialog
h = datamanager.BrushManager.getInstance();
[mfile,fcnname] = datamanager.getWorkspace();
I = h.getBrushingProp(varName,mfile,fcnname,'I');
varValue = evalin('caller',varName);
if isvector(varValue)
    brushedData = varValue(I);
else
    brushedData = varValue(any(I,2),:);
end
export2wsdlg({getString(message('MATLAB:datamanager:brushobj:EnterVariableName'))}, ...
    {'brushedData'}, ...
    {brushedData}, ...
    getString(message('MATLAB:datamanager:brushobj:ExportToWorkspace')));