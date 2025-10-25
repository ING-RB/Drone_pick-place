function pasteLinked(fig,varNames,varValues,mfile,fcnname)
%

% Copyright 2007-2024 The MathWorks, Inc.

this = datamanager.BrushManager.getInstance();

if nargin<=3
    [mfile,fcnname] = datamanager.getWorkspace();
end

% Get brushing arrays
brushArray = cell(length(varNames),1);
for k=length(varNames):-1:1
     I = this.getBrushingProp(varNames{k},mfile,fcnname,'I');
     if ~isempty(I) && any(I(:))
        brushArray{k} = I;
     end
end
ind = ~cellfun('isempty',brushArray);
varNames = varNames(ind);
brushArray = brushArray(ind);

if isempty(varNames)
    errordlg(getString(message('MATLAB:datamanager:pasteLinked:AtLeastOneVariableMustBeBrushed')),'MATLAB','modal')
    return
elseif length(varNames)==1
    varValue = varValues{ind};
    if isvector(varValue) % Watch out for row vectors
        localPaste(varValue(brushArray{1}));
    else
        localPaste(varValue(any(brushArray{1},2),:));
    end
elseif ~isempty(fig)
    datamanager.vardisambiguate(handle(fig),varNames,varValues,mfile,fcnname,...
        {@localDisambiguateCallback varValues brushArray},'brushing_pastevardisambiguateDlg');
end

function localDisambiguateCallback(index,varValues,brushArray) 

varValue = varValues{index};
if isvector(varValue)
    localPaste(varValue(brushArray{index}));
else
    localPaste(varValue(any(brushArray{index},2),:));
end
    

function localPaste(variableData)

disp(datamanager.var2string(variableData));