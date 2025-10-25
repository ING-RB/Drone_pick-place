classdef brushingUtils
    %

    % Copyright 2008-2020 The MathWorks, Inc.
    
    % Class for sharing brushing-related code between matlab.graphics.chart.primitive graphics
    % objects.
    methods (Static)
        % Get the BrushStyleMap from the figure ancestor if it is defined,
        % of the default if not.
        function brushStyleMap = getBrushStyleMap(hObj)           
            f = ancestor(hObj,'figure');
            if ~isempty(f) && ~isempty(f.findprop('BrushStyleMap'))
                brushStyleMap = f.BrushStyleMap;
                if ~(ismatrix(brushStyleMap) && size(brushStyleMap,2)==3 && ...
                        size(brushStyleMap,1)>=1)
                    brushStyleMap = eye(3);
                end
            else
                brushStyleMap = eye(3);
            end
        end
        
        % Perform standard checks on the validity of the BrushData
        % property.
        function isValid = validateBrushing(hObj)
            
            isValid = false;
            % Early return if brushData is empty or not uint8
            % TO DO: Should cast here
            brushData = hObj.BrushData;
            if strcmp(hObj.Visible,'off') || isempty(brushData) || ...
                    all(brushData(:)==0) || ~isnumeric(brushData)
                return;
            end

            % Early return if brushData size does not match ydata size
            if size(brushData,2)~=length(hObj.YData)
                return
            end
            isValid = true;
        end
        
        % Identify the color index of any brushed data in the top layer. For 
        % now this will be the first non-zero entry in the row of the brushData
        % property which corresponds to this brushing layer to conform with 
        % R2008a behavior.
        function brushColor = getBrushingColor(brushRowData,brushStyleMap)            
            I = find(brushRowData>0);
            if ~isempty(I)  
                brushColor = uint8(brushStyleMap(rem(brushRowData(I(1))-1,size(brushStyleMap,1))+1,:)*255);
            else
                brushColor = [];
            end
        end
 
        % Transforms the 3-tuple uint8 brushColor returned from getBrushingColor 
        % to primitive ColorData.
        function colorData = transformBrushColorToTrueColor(brushColor,updateState)
            iter = matlab.graphics.axis.colorspace.IndexColorsIterator;
            iter.Colors = brushColor;
            iter.Indices = 1;
            colorData = updateState.ColorSpace.TransformTrueColorToTrueColor(iter);
        end   
        
        % Callback for a Hit listener on brushing primitives which raises
        % the context menu for brushing actions.
        function addBrushContextMenuCallback(h,eventData)        
        
        % Context menu responds only to right clicks or ctrl-click on the
        % mac
        fig = [];
        if nargin>=2
            if ismac
                fig = ancestor(h,'figure');
                if ~strcmp('alt',fig.SelectionType) && eventData.Button~=3
                    return
                end         
            elseif eventData.Button~=3
                return
            end
        end

        % Establish a figure BrushingContextMenu instance property to store
        % the uicontext menu since primitive graphics have no uicontextmenu
        % property
        if isempty(fig)
            fig = ancestor(h,'figure');
        end
        if ~isprop(fig,'BrushingContextMenu')
            pBrushingContextMenu = fig.addprop('BrushingContextMenu');
            pBrushingContextMenu.Hidden = true;
            pBrushingContextMenu.Transient = true;
        end
    
        % Create the context menu if it has not yet been built.
        if isempty(fig.BrushingContextMenu)
            fig.BrushingContextMenu = uicontextmenu('Parent',fig,...
                'Serializable','off','Tag','BrushSeriesContextMenu',...
                'Visible','on');
            
            % Check to see if object is using table support and if it is,
            % prevent replacement and deletion workflows. 
            [~, usingTable] = datamanager.filterTableSupportObjects(h.Parent);

            if ~usingTable
                mreplace = uimenu(fig.BrushingContextMenu,'Label',getString(message('MATLAB:uistring:brushingutils:ReplaceWith')),...
                    'Tag','BrushSeriesContextMenuReplaceWith');    
                uimenu(mreplace,'Label',getString(message('MATLAB:uistring:brushingutils:NaNs')),'Tag','BrushSeriesContextMenuNaNs',...
                    'Callback',{@localReplace NaN});
                uimenu(mreplace,'Label',getString(message('MATLAB:uistring:brushingutils:DefineAConstant')),'Tag',...
                    'BrushSeriesContextMenuDefineAConstant','Callback',...
                    @localReplace);
            end
            if ~matlab.ui.internal.isUIFigure(fig)
                % Web brushing does not support color selection
                uimenu(fig.BrushingContextMenu,'Label',getString(message('MATLAB:uistring:brushingutils:Color')),...
                    'Tag','BrushSeriesContextMenuColor', 'Callback', @datamanager.setBrushColor);
            end
            
            if ~usingTable
                uimenu(fig.BrushingContextMenu,'Label',getString(message('MATLAB:uistring:brushingutils:Remove')),'Tag',...
                    'BrushSeriesContextMenuRemove','Callback',...
                    {@localRemove false});
                uimenu(fig.BrushingContextMenu,'Label',getString(message('MATLAB:uistring:brushingutils:RemoveUnbrushed')),'Tag',...
                    'BrushSeriesContextMenuRemoveUnbrushed','Callback',...
                    {@localRemove true});                
            end

            uimenu(fig.BrushingContextMenu,'Label',getString(message('MATLAB:uistring:brushingutils:CreateVariable')),'Tag',...
                'BrushSeriesContextMenuCreateVariable','Callback',...
                @(e,~) localContextMenuCallback(e,"datamanager.newvar(gco)",@(es) datamanager.newvar(es)),'Separator','on');        
            uimenu(fig.BrushingContextMenu,'Label',getString(message('MATLAB:uistring:brushingutils:PasteDataToCommandLine')),...
                'Tag','BrushSeriesContextMenuPasteDataToCommandLine','Callback',...
                {@datamanager.paste},'Separator','on');
            uimenu(fig.BrushingContextMenu,'Label',getString(message('MATLAB:uistring:brushingutils:CopyDataToClipboard')),...
                'Tag','BrushSeriesContextMenuCopyDataToClipboard','Callback',...
                @(e,~) localContextMenuCallback(e,"datamanager.copySelection(gco)",@(es) datamanager.copySelection(es)));
            
            uimenu(fig.BrushingContextMenu,'Label',getString(message('MATLAB:uistring:brushingutils:ClearAllBrushing')),...
                'Tag','BrushSeriesContextMenuClearAllBrushing','Callback',...
                @localClearBrushing,'Separator','on');
        end
         
        allOptions = fig.BrushingContextMenu.Children;
        removeOptions = [];
        if isprop(h.Parent,'BarPeers') && (length(h.Parent.BarPeers) > 1)
            %Removing single bars from a Bar series is not currently supported by Bar, all bars in a series must have the same sized XData and YData.
            % toggle visibility of the remove options for a grouped bar
            removeOptions = findall(fig.BrushingContextMenu,...
                'tag','BrushSeriesContextMenuRemove','-or',...
                'tag','BrushSeriesContextMenuRemoveUnbrushed');
        end
        bManager = datamanager.BrushManager.getInstance();
        seltable = bManager.SelectionTable;
        if datamanager.isFigureLinked(fig) && ~isempty(seltable) && ~any(arrayfun(@(x)any(x.I(:)),seltable))
            % If no data point is selected, hide menu items that assume at
            % least some data is selected
            removeOptions = union(removeOptions,findall(fig.BrushingContextMenu,...
                'tag','BrushSeriesContextMenuCopyDataToClipboard','-or',...
                'tag','BrushSeriesContextMenuPasteDataToCommandLine','-or',...
                'tag','BrushSeriesContextMenuCreateVariable','-or',...
                'tag','BrushSeriesContextMenuRemove','-or',...
                'tag','BrushSeriesContextMenuReplaceWith'));
        end
        
        set(removeOptions,'Visible','off'); 
        set(setdiff(allOptions,removeOptions),'Visible','on');

        % Create a non-serializable Tartget property on the context menu
        % and update it so that callbacks can access an up-to-date version
        % of the object that was clicked.
        if ~isprop(fig.BrushingContextMenu,'Target')
            p = fig.BrushingContextMenu.addprop('Target');
            p.Transient = true;
        end
        fig.BrushingContextMenu.Target = h;
        
       
        % On the pc, context menus are raised on a mouse up event. To make
        % this happen create a listener to the WindowMouseRelease event which
        % displays the context menu. On other platforms, just show the
        % context menu.
        if ispc
            if ~isprop(fig,'BrushingContextMenuListener')
                pBrushingContextMenuListener = fig.addprop('BrushingContextMenuListener');
                pBrushingContextMenuListener.Hidden = true;
                pBrushingContextMenuListener.Transient = true;
            end
            if isempty(fig.BrushingContextMenuListener)
               fcnH = @(es,ed) matlab.graphics.chart.primitive.brushingUtils.showContextMenu(...
                   es,fig.BrushingContextMenu);
               fig.BrushingContextMenuListener = event.listener(fig,'WindowMouseRelease',...
                   fcnH);
            end
        else
            matlab.graphics.chart.primitive.brushingUtils.showContextMenu(fig,fig.BrushingContextMenu);
        end
        
        end

        % Callback for WindowMouseRelease used on the pc to raise the brushing
        % context menu.
        function showContextMenu(fig,pContextMenu)

        % Delete any remaining WindowMouseRelease listener
        if isprop(fig,'BrushingContextMenuListener') && ...
                ~isempty(fig.BrushingContextMenuListener) && ...
                isvalid(fig.BrushingContextMenuListener)
            delete(fig.BrushingContextMenuListener);
            fig.BrushingContextMenuListener = [];
        end
        
        %Convert the point to pixels since the position of the context menu should be
        %specified in pixels
        pixPoint = hgconvertunits(fig, [0,0,fig.CurrentPoint], fig.Units, 'pixels', fig);        
        pContextMenu.Position = pixPoint(3:4);
        set(pContextMenu,'Visible','on');
        
        end
        
        % Implementation of the brush behavior object DrawFcn
        function histbehaviorDrawFcn(I,colorIndex,gobj)
            if ~isprop(gobj,'BrushPrimitive')
                p = addprop(gobj,'BrushPrimitive');
                p.Transient = true;
            end
            if isempty(gobj.BrushPrimitive)
                gobj.BrushPrimitive = brushing.HistBrushing('Parent',gobj);
            end
            gobj.BrushPrimitive.BrushColorIndex = colorIndex;
            gobj.BrushPrimitive.BrushData = I;

        end          
        
        function replaceData(hObj,newValue)
            
            % For web figures replaceData must be called on gco
            % because replaceData must be called asynchronously because
            % context menus callbacks are not called in the current
            % workspace
            
            % For Linked Figures pass the var. data required by dataEdit as a property
            % of the context menu
            
            if(nargin == 1)
                newValue =[];
            end
            
            fig = ancestor(hObj,'figure');
            linkeddata = repmat(struct('VarName','','VarValue',[],'BrushingArray',[]),[0 1]);
            
            
            
            if(datamanager.isFigureLinked(fig))
                
                % In case of a Linked Plot we have to preevaluate the linked data
                % beforehand for dataEdit. dataEdit evaluates the Linked variables data by
                % calling evalin(?caller?,?) and its caller is the current (localReplace)
                % function which does not contain the required variables.
                % The following logic does the preevaluation.
                
                 [linkedVarNames,varStruct] = getLinkedVarData(fig);
                 % The varStruct "VarValue" fields need to be calculated in
                 % the calling workspace
                 for i = 1: length(linkedVarNames)
                     for j = 1:length(linkedVarNames{i})
                         varStruct{i}{j}.VarValue = evalin('caller',[linkedVarNames{i}{j} ';']);
                         linkeddata  = [linkeddata;varStruct{i}{j}]; %#ok<AGROW>
                     end
                 end
            end
            
            % Replace brushed data on clicked graphic with optionally specified value
            contextMenu = ancestor(hObj,'uicontextmenu');
            if ~isempty(contextMenu) && isprop(contextMenu,'Target')
                datamanager.dataEdit(fig,[],contextMenu.Target,'replace',newValue,linkeddata);
            elseif ~isempty(ancestor(hObj,'axes'))
                datamanager.dataEdit(fig,[],ancestor(hObj,'axes'),'replace',newValue,linkeddata);
            else
                datamanager.dataEdit(fig,[],hObj,'replace',newValue,linkeddata);
            end
            set(groot,'ShowHiddenHandles','off') 
        end
        
        function removeData(hObj, state)
                  
            % Remove brushed data on clicked graphic
            fig = ancestor(hObj,'figure');
            linkeddata = repmat(struct('VarName','','VarValue',[],'BrushingArray',[]),[0 1]);
            
            if(datamanager.isFigureLinked(fig))
                
                % In case of a Linked Plot we have to preevaluate the linked data
                % beforehand for dataEdit. dataEdit evaluates the Linked variables data by
                % calling evalin(?caller?,?) and its caller is the current (localRemove)
                % function which does not contain the required variables.
                % The following logic does the preevaluation.
                

                 [linkedVarNames,varStruct] = getLinkedVarData(fig);
                 % The varStruct "VarValue" fields need to be calculated in
                 % the calling workspace
                 for i = 1: length(linkedVarNames)
                     for j = 1:length(linkedVarNames{i})
                         varStruct{i}{j}.VarValue = evalin('caller',[linkedVarNames{i}{j} ';']);
                         linkeddata  = [linkeddata;varStruct{i}{j}]; %#ok<AGROW>
                     end
                 end
            end
            
            contextMenu = ancestor(hObj,'uicontextmenu');
            
            if ~isempty(contextMenu) && isprop(contextMenu,'Target')
                datamanager.dataEdit([],[],contextMenu.Target,'remove',state,linkeddata);
            elseif ~isempty(ancestor(hObj,'axes'))
                datamanager.dataEdit([],[],ancestor(hObj,'axes'),'remove',state,linkeddata);
            else
                datamanager.dataEdit([],[],hObj,'remove',state,linkeddata);
            end
        end
        
        
    end
    
    
    
end

function localReplace(es,~,newValue)
fig = ancestor(es,'figure');
if datamanager.isFigureLinked(fig)
    % If the figure is HandleInvisible, temporarily turn on ShowHiddenHandles
    isHandleInvisibleFigure = (fig.HandleVisibility=="off");
    if isHandleInvisibleFigure
        cachedShowHiddenHandles = get(groot,'ShowHiddenHandles');
        set(groot,'ShowHiddenHandles','on')     
    end
    if nargin<=2
        internal.matlab.datatoolsservices.executeCmd('matlab.graphics.chart.primitive.brushingUtils.replaceData(gco)');
    else
        internal.matlab.datatoolsservices.executeCmd("matlab.graphics.chart.primitive.brushingUtils.replaceData(gco,"+num2str(newValue)+")");
    end
    if isHandleInvisibleFigure && cachedShowHiddenHandles=="off"        
        internal.matlab.datatoolsservices.executeCmd("set(groot,'ShowHiddenHandles','off')");
    end
elseif nargin<=2
    matlab.graphics.chart.primitive.brushingUtils.replaceData(es,[])
else
    if isprop(fig, 'CurrentAxes') && containsDatetime(fig.CurrentAxes)
        newValue = NaT;
    elseif isprop(fig, 'CurrentAxes')&& containsCategorical(fig.CurrentAxes)
        newValue = categorical(NaN);
    end
    matlab.graphics.chart.primitive.brushingUtils.replaceData(es,newValue)
end
end

function result = containsDatetime(ax)
% Check if the YAxis on the given axis is a datetime ruler
result = isa(ax.YAxis, 'matlab.graphics.axis.decorator.DatetimeRuler');
end
function result = containsCategorical(ax)
% Check if the YAxis on the given axis is a categorical ruler
result = isa(ax.YAxis, 'matlab.graphics.axis.decorator.CategoricalRuler');
end

function localClearBrushing(es,~)

% Clear brushing from clicked axes.
fig =  ancestor(es,'figure');
ax = get(fig,'CurrentAxes');
brushMgr = datamanager.BrushManager.getInstance();
if isprop(handle(fig),'LinkPlot') && get(fig,'LinkPlot')    
    [mfile,fcnname] = datamanager.getWorkspace(1);
    brushMgr.clearLinked(fig,ax,mfile,fcnname);
end
brushing.select.clearBrushing(ax)

end
 
function localContextMenuCallback(es,callbackStr,callbackFcn)

% Callback for context menus that need to work for linked plots (where the
% callback must be evaluated in a specific workspace). The callback
% execution is asynchronous for linked plots to allow this function to be
% called from any workspace. This behavior is needed because web figure and
% java figure context menus evaluate from different workspace (java figures
% in the current workspace, web figures in a functional workspace of the
% web figure context menu implementation)

fig = ancestor(es,'figure');
if datamanager.isFigureLinked(fig)
    % If the figure is HandleInvisible, temporarily turn on ShowHiddenHandles
    isHandleInvisibleFigure = (fig.HandleVisibility=="off");
    if isHandleInvisibleFigure
        cachedShowHiddenHandles = get(groot,'ShowHiddenHandles');
        set(groot,'ShowHiddenHandles','on')     
    end
    internal.matlab.datatoolsservices.executeCmd(callbackStr);
    if isHandleInvisibleFigure && cachedShowHiddenHandles=="off"        
        internal.matlab.datatoolsservices.executeCmd("set(groot,'ShowHiddenHandles','off')");
    end
else
    feval(callbackFcn,es);
end
end

function localRemove(es,~,state)
fig = ancestor(es,'figure');
if datamanager.isFigureLinked(fig)
        % If the figure is HandleInvisible, temporarily turn on ShowHiddenHandles
    isHandleInvisibleFigure = (fig.HandleVisibility=="off");
    if isHandleInvisibleFigure
        cachedShowHiddenHandles = get(groot,'ShowHiddenHandles');
        set(groot,'ShowHiddenHandles','on')     
    end
    internal.matlab.datatoolsservices.executeCmd("matlab.graphics.chart.primitive.brushingUtils.removeData(gco," + num2str(state)+ ")");
    if isHandleInvisibleFigure && cachedShowHiddenHandles=="off"        
        internal.matlab.datatoolsservices.executeCmd("set(groot,'ShowHiddenHandles','off')");
    end
else
    matlab.graphics.chart.primitive.brushingUtils.removeData(es, state)
end
end

function [linkedVars,varStruct] = getLinkedVarData(fig)

% Get the names and linked data structures for linked variables in the
% figure. Return each as a depth-2 cell array with the first dimension
% matching the number of graphics objects with linked variables and the
% second dimension defined by the number of variables linked in each of
% those graphics
h = datamanager.LinkplotManager.getInstance();
brushMgr = datamanager.BrushManager.getInstance();
sibs = datamanager.getAllBrushedObjects(fig);
[mfile,fcnname] = datamanager.getWorkspace(3);
linkedVars = cell(1,length(sibs));
varStruct = cell(1,length(sibs));
for i = 1:length(sibs)
    linkedVars{i} = h.getLinkedVarsFromGraphic(sibs(i),mfile,fcnname,true); 
    for j = 1:length(linkedVars{i})
        varStruct{i}{j} = struct('VarName',...
            linkedVars{i}{j},...
            'BrushingArray',...
            brushMgr.getBrushingProp(linkedVars{i}{j},mfile,fcnname,'I'));
    end
end
end



