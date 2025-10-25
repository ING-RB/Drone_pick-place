function copyLinked(fig,varNames,varValues,mfile,fcnname)
%

% Copyright 2007-2024 The MathWorks, Inc.

this = datamanager.BrushManager.getInstance();

if nargin<=3
    [mfile,fcnname] = datamanager.getWorkspace();
end

% Get brushing arrays for variables which have been brushed
brushArray = cell(1,length(varNames));
for k=1:length(varNames)
     I = this.getBrushingProp(varNames{k},mfile,fcnname,'I');
     if ~isempty(I) && any(I(:))
        brushArray{k} = I;
     end
end
ind = ~cellfun('isempty',brushArray);
varNames = varNames(ind);
brushArray = brushArray(ind);

if isempty(varNames)
    return % Nothing brushed
elseif length(varNames)==1 % Copy single brushed variable
    varValue = varValues{ind};
    if isvector(varValue)
        clipboard('copy',(datamanager.var2string(varValue(brushArray{k})))); 
    else
        clipboard('copy',(datamanager.var2string(varValue(any(brushArray{k},2),:))));
    end
elseif ~isempty(fig) % Resolve ambiguity between multiple variables
    datamanager.vardisambiguate(handle(fig),varNames,varValues,mfile,fcnname,...
        {@localDisambiguateCallback varValues brushArray},'brushing_copyvardisambiguateDlg');
end

function localDisambiguateCallback(index,varValues,brushArray) 

varValue = varValues{index};
if ~isvector(brushArray{index})
    clipboard('copy',(datamanager.var2string(varValue(...
        any(brushArray{index},2),:))));    
else
    clipboard('copy',(datamanager.var2string(varValue(...
        brushArray{index}))));
end