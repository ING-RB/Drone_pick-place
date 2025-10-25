function pasteContextMenuCallback
%

% Copyright 2020-2024 The MathWorks, Inc.

% Function to evaluate paste operations on linked graphics from 
% the current workspace via internal.matlab.datatoolsservices.executeCmd()

fig = gcf;
gContainer = get(fig,'CurrentAxes');
if isempty(gContainer)
    gContainer = fig;
end

h = datamanager.LinkplotManager.getInstance();
[mfile,fcnname] = datamanager.getWorkspace();
[linkedVarList,linkedGraphics] = getLinkedVarsFromGraphic(...
    h,gContainer,mfile,fcnname);
allBrushable = findobj(gContainer,'-function',...
    @(x) isprop(x,'BrushData') && ~isempty(get(x,'BrushData')) && ...
    any(x.BrushData(:)>0),...
    'HandleVisibility','on');
allBrushable= findobj(allBrushable,'flat','-function',...
    @(x) ~isempty(get(x,'BrushData')) && any(x.BrushData(:)>0));
unlinkedGraphics = setdiff(double(allBrushable),double(linkedGraphics));

% If there are unlinked graphics or expression based graphics, ask
% which should be pasted.
if ~isempty(linkedVarList) && ~isempty(unlinkedGraphics)
    msg = getString(message('MATLAB:datamanager:paste:NoVariableFromCombinationGraphics'));
    ButtonName = questdlg(msg, ...
        getString(message('MATLAB:datamanager:paste:MATLAB')), ...
        getString(message('MATLAB:datamanager:paste:Linked')),getString(message('MATLAB:datamanager:paste:Unlinked')),getString(message('MATLAB:datamanager:paste:Abort')),getString(message('MATLAB:datamanager:paste:Abort')));
    if isempty(ButtonName) || strcmp(ButtonName,getString(message('MATLAB:datamanager:paste:Abort')))
        return
    elseif strcmp(ButtonName,getString(message('MATLAB:datamanager:paste:Unlinked')))
        datamanager.pasteUnlinked(unlinkedGraphics);
        return
    end
elseif ~isempty(unlinkedGraphics) % Only unlinked
    datamanager.pasteUnlinked(unlinkedGraphics);
    return
end

cachedVarValues = cell(length(linkedVarList),1);
for k=1:length(cachedVarValues)
    cachedVarValues{k} = evalin('caller',[linkedVarList{k} ';']);
end
datamanager.pasteLinked(fig,linkedVarList,cachedVarValues,mfile,fcnname);