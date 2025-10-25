function linkplotfunc(figureSrc,varargin)
%

% Copyright 2008-2024 The MathWorks, Inc.

% Redraw linked plots and brushing annotations.

this = datamanager.LinkplotManager.getInstance();
if isempty(this.LinkListener)
    return;
end

% Parse pv-pairs.
% redrawBrushing - update brushing after linking error
% retainUndo - prevents clearing the undo stack
redrawBrushing = false;
retainUndo = false;
for k=1:2:length(varargin)
    switch varargin{k}
        case 'redrawBrushing'
            redrawBrushing = varargin{k+1};
        case 'retainUndo'
            retainUndo = varargin{k+1};
    end
end


% Get the current mfile,fcnname
[mfile,fcnname] = datamanager.getWorkspace();
redrawInd = false(1,length(this.Figures));

% When looping, don't use this.Figures since figures can be removed by
% calls to updateLinkedGraphics
linkedFigSructArray = this.Figures;
for k = 1:length(linkedFigSructArray)
    
    % If necessary reset the graphics
    if linkedFigSructArray(k).Dirty
        newLinkedFigStruct = this.updateLinkedGraphics(k);
        if isempty(newLinkedFigStruct) % This figure is removed from linked plot array
            continue;
        end
        linkedFigSructArray(k) = newLinkedFigStruct;
        if ~linkedFigSructArray(k).Figure.LinkPlot % Plot is no longer linked
            continue;
        end
    end
    
    % Redraw lines and brushing
    figH = linkedFigSructArray(k).Figure;
    hh = linkedFigSructArray(k).LinkedGraphics;
    
    for j=1:length(hh)
        bh = hggetbehavior(hh(j),'Linked','-peek');
        linkerr = '';
        
        if isempty(hh(j).findprop('LinkDataError'))
            addprop(hh(j), 'LinkDataError');
        end
        lastLinkError = hh(j).LinkDataError;
        
        if ~isempty(bh)
            if islinked(bh)
                try
                    bdatalen = sum([bh.UsesXDataSource bh.UsesYDataSource bh.UsesZDataSource]);
                    bdata = cell(1,bdatalen);
                    count = 1;
                    if bh.UsesXDataSource && ~isempty(bh.XDataSource)
                        bdata{count} = evalin('caller',bh.XDataSource);
                        count = count+1;
                    end
                    if bh.UsesYDataSource && ~isempty(bh.YDataSource)
                        bdata{count} = evalin('caller',bh.YDataSource);
                        count = count+1;
                    end
                    if bh.UsesZDataSource && ~isempty(bh.ZDataSource)
                        bdata{count} = evalin('caller',bh.ZDataSource);
                    end
                    datamanager.setBrushingInteractionHint(hh(j), true);
                catch me
                    linkerr = me.message;
                end
            end
        else
            pnames = {};
            pvals = {};
            if ~isempty(hh(j).findprop('XDataSource'))
                xsrc = hh(j).XDataSource;
                if ~isempty(xsrc)
                    try
                        xdata = evalin('caller',hh(j).XDataSource);
                        pnames = [pnames, {'xdata'}]; %#ok<AGROW>
                        pvals = [pvals, {xdata}]; %#ok<AGROW>
                    catch me
                        linkerr = me.message;
                    end
                end
            end
            if ~isempty(hh(j).findprop('YDataSource'))
                ysrc = hh(j).YDataSource;
                if ~isempty(ysrc)
                    try
                        ydata = evalin('caller',hh(j).YDataSource);
                        pnames = [pnames, {'ydata'}]; %#ok<AGROW>
                        pvals = [pvals, {ydata}]; %#ok<AGROW>
                    catch me
                        linkerr = me.message;
                    end
                end
            end
            if ~isempty(hh(j).findprop('ZDataSource'))
                zsrc = hh(j).ZDataSource;
                if ~isempty(zsrc)
                    try
                        zdata = evalin('caller',hh(j).ZDataSource);
                        pnames = [pnames, {'zdata'}]; %#ok<AGROW>
                        pvals = [pvals, {zdata}]; %#ok<AGROW>
                    catch me
                        linkerr = me.message;
                    end
                end
            end
            
        end
        if isempty(linkerr)
            if ~isempty(bh)
                % If the linked behavior object uses a Data Source,
                % only evaluate the DataSourceFcn if at 
                % least one of the Data Source strings evaluate to something 
                % non empty. This ensures that a workspace event
                % does not effectively clear the chart object
                % by setting its data to []. Consequently, 
                % the linked behavior matches the non behavior object
                % default case (g3096398)
                if islinked(bh) && (bdatalen==0 || any(~cellfun('isempty',bdata)))
                    try
                        if iscell(bh.DataSourceFcn)
                            feval(bh.DataSourceFcn{1},hh(j),bdata,bh.DataSourceFcn{2:end});
                        else
                            feval(bh.DataSourceFcn,hh(j),bdata);
                        end
                    catch me
                        linkerr = me.message;
                    end
                end
            elseif ~isempty(pnames)
                try
                    set(hh(j),pnames,pvals);
                catch me
                    linkerr = me.message;
                end
                hObj = handle(hh(j));
                if isprop(hObj,'XDataSource') && isprop(hObj,'YDataSource') && ~ishghandle(hObj,'surface') && ...
                        ~isequal(size(get(hh(j),'xdata')),size(get(hh(j),'ydata')))
                    linkerr = 'Size mismatch';
                end
            end
            
        end
        % Will need to redraw brushing on figures recovering from error,
        % in a figure where an action is being undone, or for any custom
        % linked object (which does not have DataListeners to redraw
        % brushing annotations when graphics data properties change).
        if ~redrawInd(k)
            redrawInd(k) = (~isempty(lastLinkError) && isempty(linkerr)) || ...
                (nargin>=3 && isequal(figureSrc,figH) && redrawBrushing) ||...
                ~isempty(bh);
        end
        set(hh(j),'LinkDataError',linkerr);
    end

end

% Update brushing manager in case the size of brushed variables has changed
brushManager = datamanager.BrushManager.getInstance();

% Build a whos struct array identifying any structs already brushed or
% linked.
wsInfo = evalin('caller','whos');
brushVarNames = brushManager.getVarNames(mfile,fcnname);
Itmp = strfind(brushVarNames,'.');
if ~isempty(Itmp)
    structElementNames = [this.getAllStructVarNames;brushVarNames(~cellfun('isempty',Itmp))];
else
    structElementNames = this.getAllStructVarNames;
end
if ~isempty(structElementNames)
    wFieldNames = fields(wsInfo);
end
for k=1:length(structElementNames)
    % Exclude any brushed or linked structure elements which are not in the
    % caller workspace.
    structElementName = structElementNames{k};
    dotPos = strfind(structElementName,'.');
    if isempty(dotPos) || ~any(strcmp(structElementName(1:dotPos(1)-1),{wsInfo.('name')}))
        continue;
    end
    try
        % Add all brushed and linked struct elements to wsInfo.
        stuctData = evalin('caller',['{class(' structElementName '), size(' structElementName ')}']);
        locWStruct = cell2struct(cell(length(wFieldNames),1),wFieldNames);
        locWStruct.name = structElementName;
        locWStruct.class = stuctData{1};
        locWStruct.size = stuctData{2};
        wsInfo = [wsInfo;locWStruct]; %#ok<AGROW>
    catch me  % Clean out any lasterr state
    end
end
brushManager.updateVars(wsInfo,mfile,fcnname);

% Redraw brushing for variables which have recovered from a previous error
redrawPos = find(redrawInd);
for k=1:length(redrawPos)
    
    uniqueVarNames = this.Figures(redrawPos(k)).VarNames;
    uniqueVarNames = uniqueVarNames(~cellfun('isempty',uniqueVarNames));
    uniqueVarNames = unique(uniqueVarNames);
    for j=1:length(uniqueVarNames)
        brushManager.draw(uniqueVarNames{j},mfile,fcnname);
    end
end

% Update array editors
if ~feature('webui')
    com.mathworks.page.datamgr.brushing.ArrayEditorManager.refreshAll()
end

% Update the enabled state of brushing actions in the Variable Editor.
[brushVarNames,Ivars] = brushManager.getVarNames(mfile,fcnname);
isVarBrushed = false(1,length(brushVarNames));
for k=1:length(Ivars)
    isVarBrushed(k) = any(brushManager.SelectionTable(Ivars(k)).I(:));
end
if ~feature('webui')
    com.mathworks.mlwidgets.array.brushing.BrushingActionFactory.setAllVarBrushedState(brushVarNames,isVarBrushed);
end

% Clear undo stack of all linked figures except those explicitly excluded.
% This prevents undo actions being invalid because of stale referenced to
% linked variables.
if nargin<=1 || ~retainUndo
    datamanager.clearUndoRedo;
else
    datamanager.clearUndoRedo('exclude',figureSrc);
    this.LinkListener.EventSource = [];
end