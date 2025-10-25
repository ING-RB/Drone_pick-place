function contrastcolors(state, fig)
%CONTRASTCOLORS Modify figure to avoid dithered lines.
%   This undocumented helper function is for internal use.

%   CONTRASTCOLORS(STATE,FIG) modifies the color of graphics objects to
%   black or white, whichever best contrasts the figure and axis
%   colors.  STATE is either 'save' to set up colors for black
%   background or 'restore'.
%
%   CONTRASTCOLORS(STATE) operates on the current figure.
%
%   See also ADJUSTBACKGROUND, BWCONTR, PRINT

%   Copyright 1984-2022 The MathWorks, Inc.
    
    drawnowNeeded = false;
    if nargin == 0 ...
            || ~ischar( state ) ...
            || ~(strcmp(state, 'save') || strcmp(state, 'restore'))
        error(message('MATLAB:contrastcolors:invalidFirstArgument'))
    elseif nargin ==1
        fig = gcf;
    elseif isempty(fig)
        if isappdata(groot, 'PrintingFigure')
            fig = getappdata(groot, 'PrintingFigure');
            % this path requires a drawnow when 'save' 
            drawnowNeeded = true;
        else
            return % do nothing if figure is empty
        end
    end
    
    persistent NoDitherOriginalColors;
    
    if strcmp(get(fig,'color'),'none')
        return % Don't do anything -- Assume all users of 'none' have already
        % mapped their colors if so desired.
    end
    
    useOrig = matlab.graphics.internal.useOriginalHGPrinting(fig); 

    BLACK = [0 0 0];
    WHITE = [1 1 1];
    
    if strcmp( state, 'save' )
        
        % initialize objects
        di.axesObj = [];
        di.rulerObj = [];
        di.lineObj = [];
        di.surfaceObj = [];
        di.textObj = [];
        di.rectObj = [];
        di.patchObj = [];
        di.annotObj = [];
        di.chartObj = [];
        di.colorbarObj = [];
        di.subplotTextObj = [];
        di.legendObj = [];
        di.contourObj = [];
        di.baselineObj = [];
        di.graphplotObj = [];
        di.heatmapObj = [];
        di.constantlineObj = [];
        di.wordcloudObj = [];
        di.polygonObj = [];
        di.confusionMatrixChartObj = [];
        di.scatterhistogramObj = [];
        di.stackedplotObj = [];
        di.parallelplotObj = [];
        di.boxchartObj = [];
        
        figColor = get(fig,'color');
        if strcmp(figColor, 'none')
            figColor = BLACK;
        end
        figContrast = bwcontr(figColor);
        figKids = findall(fig); 
        allAxes = findall( figKids, 'Type', 'axes', '-or','Type','polaraxes','-depth', 0);
        allLegends = findall(figKids, 'Type', 'legend', '-depth', 0);
        allSubplotText = findall(figKids, 'Type', 'subplottext', '-depth', 0);
        allColorbars = findall(figKids, 'Type', 'colorbar', '-depth', 0); 
        allHeatmaps = findall(figKids, 'Type', 'heatmap', '-depth', 0);
        allWordclouds = findall(figKids, 'Type', 'wordcloud', '-depth', 0);
        allConfusionMatrixCharts = findall(figKids, 'Type', 'ConfusionMatrixChart', '-depth', 0);
        allScatterhistograms = findall(figKids, 'Type', 'scatterhistogram', '-depth', 0);
        allStackedplots = findall(figKids, 'Type', 'stackedplot', '-depth', 0);
        allParallelplots = findall(figKids, 'Type', 'parallelplot', '-depth', 0);
        allBoxChart = findall(figKids, 'Type', 'BoxChart', '-depth', 0);
        
        naxes = length(allAxes);
        for k = 1:naxes
            a = allAxes(k);
            ha = handle(a);
            axColor = get(a,'Color');
            if (isequal(axColor,'none'))
                axContrast = figContrast;
            else
                axContrast = bwcontr(axColor);
            end
            
            kids = findall(a, 'Visible', 'on'); 
            axIdx = k;
            saveAxisColors(a, axIdx);
            rulerIdx = saveRulerColors(a); 
            textIdx = saveTextColors(kids); 
            changeAxisColors(axIdx);
            % Change the various plot object colors
            saveAndChangeLineColors(kids);
            saveAndChangeSurfacePlotColors(kids);
            saveAndChangeRectangleColors(kids);
            saveAndChangePatchColors(kids);
            saveAndChangeChartObjColors(kids);
            saveAndChangeContourObjColors(kids);
            saveAndChangeBaselineObjColors(kids);
            changeTextColors(a, textIdx); 
            changeRulerColors(rulerIdx); 
            saveAndChangeGraphPlotColors(kids);
            saveAndChangeConstantLineColors(kids);
            saveAndChangePolygonColors(kids);
        end
        
        if ~isempty(allSubplotText)
            saveAndChangeSubplotTextColors(allSubplotText); 
        end
        if ~isempty(allLegends)
            saveAndChangeLegendColors(allLegends); 
        end
        if ~isempty(allColorbars)
           saveAndChangeColorbarColors(allColorbars);
        end
        if ~isempty(allHeatmaps)
           saveAndChangeHeatmapColors(allHeatmaps);
        end
        if ~isempty(allWordclouds)
           saveAndChangeWordcloudColors(allWordclouds);
        end
        if ~isempty(allConfusionMatrixCharts)
           saveAndChangeConfusionMatrixChartColors(allConfusionMatrixCharts);
        end
        if ~isempty(allScatterhistograms)
           saveAndChangeScatterhistogramColors(allScatterhistograms);
        end
        if ~isempty(allStackedplots)
            saveAndChangeStackedplotColors(allStackedplots);
        end
        if ~isempty(allParallelplots)
            saveAndChangeParallelplotColors(allParallelplots);
        end
        if ~isempty(allBoxChart)
            saveAndChangeBoxChartColors(allBoxChart);
        end
        
        % Change annotations
        if ~useOrig
            saveAndChangeAnnotationColors(fig);
        end
        
        % Save for restoration later
        NoDitherOriginalColors = [di NoDitherOriginalColors];
        if drawnowNeeded
            drawnow;
        end
    else  
        % Restore the colors to the original state
        orig = NoDitherOriginalColors(1);
        NoDitherOriginalColors = NoDitherOriginalColors(2:end);
        
        restoreLineColors();
        restoreAxesColors();
        restoreRulerColors(); % restore AFTER restoring axes colors
        restorePatchColors();
        restoreSurfacePlotColors();
        restoreTextColors();
        restoreRectangleColors();
        restoreChartObjColors();
        restoreGraphPlotColors();
        restoreConstantLineColors()
        restoreHeatmapColors();
        restorePolygonColors();
        restoreWordcloudColors();
        restorePolygonColors();
        restoreConfusionMatrixChartColors();
        restoreScatterhistogramColors();
        restoreStackedplotColors();
        restoreParallelplotColors();
        restoreBoxChartColors();
        
        if ~useOrig
            restoreAnnotationColors();
            restoreSubplotTextColors();
            restoreLegendColors();
            restoreColorbarColors();
            restoreContourObjColors();
            restoreBaselineObjColors();
        end
    end
    
    %----------------------------------------------------------------     
    function saveAxisColors(ha, index)
        % save the current values for axes X-, Y-, Z- (or Theta and R) 
        % and Grid / MinorGrid colors and color modes  
        di.axesObj(index).axesObject = ha;
        
        names = getAxisDimensionNames(ha);

        % 
        names{end+1} = 'Grid';  % to access Grid Color and ColorMode
        names{end+1} = 'MinorGrid'; % to access MinorGrid Color and ColorMode

        % these props need to be contrasted against the fig color
        for propIdx = 1:length(names) 
            currBase = names{propIdx};
            currProp = [currBase 'Color' ];
            currMode = [currProp 'Mode'];
            storageProp = [lower(currProp(1)) currProp(2:end)];
            storageMode = [lower(currMode(1)) currMode(2:end)];
            % all should have a *Color property 
            
            di.axesObj(index).(storageProp) = get(ha, currProp);
            % not all might have the *ColorMode property 
            if ~isempty(findprop(ha, currMode))
                di.axesObj(index).(storageMode) = get(ha, currMode); 
            end
        end
    end

    %----------------------------------------------------------------     
    function changeAxisColors(startIdx)
        % Make sure that axes colors are one of
        %   - white
        %   - black
        %   - figColor
        %   - figContrast 
        %   - axContrast

        if ~startIdx 
            return; % nothing to do
        end
        for idx = startIdx:length(di.axesObj)
            ha = di.axesObj(idx).axesObject; 
            names = getAxisDimensionNames(ha);
            
            insideNames{1} = 'Grid';  % to access Grid Color and ColorMode
            insideNames{2} = 'MinorGrid'; % to access MinorGrid Color and ColorMode
            
            % these props need to be contrasted against the fig color
            for propIdx = 1:length(names) 
                currBase = names{propIdx};
                currProp = [currBase 'Color' ];
                storageProp = [lower(currProp(1)) currProp(2:end)];
                % all should have a *Color property 
                currColor = di.axesObj(idx).(storageProp);
                if (~isequal(currColor,BLACK) && ~isequal(currColor,WHITE) && ~isequal(currColor,figColor))
                    set(ha,currProp,figContrast)
                end
            end
            
            % grid (inside) props need to be contrasted against the axes color
            for propIdx = 1:length(insideNames) 
                currBase = insideNames{propIdx};
                currProp = [currBase 'Color' ];
                storageProp = [lower(currProp(1)) currProp(2:end)];
                % all should have a *Color property 
                currColor = di.axesObj(idx).(storageProp);
                if (~isequal(currColor,BLACK) && ~isequal(currColor,WHITE) && ~isequal(currColor,axColor))
                    set(ha,currProp,axContrast)
                end
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreAxesColors()
        % Restore axes
        for idx = 1:length(orig.axesObj)
            ha = orig.axesObj(idx).axesObject; 
            names = getAxisDimensionNames(ha);
            
            names{end+1} = 'Grid';  % to access Grid Color and ColorMode
            names{end+1} = 'MinorGrid'; % to access MinorGrid Color and ColorMode
            
            origValues = orig.axesObj(idx);
            % restore the original values
            for propIdx = 1:length(names) 
                currBase = names{propIdx};
                currProp = [currBase 'Color' ];
                currModeProp = [currProp 'Mode'];
                storageProp = [lower(currProp(1)) currProp(2:end)];
                storageModeProp = [lower(currModeProp(1)) currModeProp(2:end)];
                % all should have a *Color property 
                set(ha,currProp,origValues.(storageProp))
                % not all might have the *ColorMode property -- restore
                % those that do
                if ~isempty(findprop(ha, currModeProp))
                    set(ha, currModeProp, origValues.(storageModeProp)); 
                end
            end
            
        end
    end
    %----------------------------------------------------------------
    function saveAndChangeLineColors(kids)
        lobjs = findall(kids,'type','line', '-or', ...
                          'type', 'errorbar', '-or', ...
                          'type', 'quiver', '-or', ...
                          'type', 'stair', '-or', ...
                          'type', 'stem', '-or', ...
                          'type', 'functionline', '-or', ...
                          'type', 'parameterizedfunctionline', '-or', ...
                          '-isa', 'hg2sample.ScopeLineAnimator', '-or', ...
                          '-isa', 'hg2sample.ScopeStairAnimator', '-or', ...
                          '-isa', 'matlab.graphics.animation.ScopeLineAnimator', '-or', ...
                          '-isa', 'matlab.graphics.animation.ScopeStairAnimator',  '-or',...
                          '-isa', 'matlab.graphics.animation.ScopeStemAnimator', ...
                          '-depth', 0);
        nlobjs = length(lobjs);
        already.line = length(di.lineObj);
        
        for n = 1:nlobjs
            l = lobjs(n);
            
            lcolor = get(l,'color');
            lmecolor = get(l,'markeredgecolor');
            lmfcolor = get(l,'markerfacecolor');
            idx = already.line+n;
            
            % Save the line and its current colors for the restore
            di.lineObj(idx).lineObject = l;
            di.lineObj(idx).color = lcolor;
            di.lineObj(idx).markerEdgeColor = lmecolor;
            di.lineObj(idx).markerFaceColor = lmfcolor;
            
            if ~isempty(findprop(handle(l), 'ColorMode')) && ~isempty(findprop(handle(l), 'MarkerEdgeColorMode')) ...
                    && ~isempty(findprop(handle(l), 'MarkerFaceColorMode'))
                di.lineObj(idx).colorMode = get(l, 'ColorMode');
                di.lineObj(idx).markerEdgeColorMode = get(l, 'MarkerEdgeColorMode');
                di.lineObj(idx).markerFaceColorMode = get(l, 'MarkerFaceColorMode');
            end
            
            if (~isequal(lcolor,BLACK) && ~isequal(lcolor,WHITE) && ...
                    ~isequal(lcolor,axColor))
                set(l,'color',axContrast)
            end
            
            if ~ischar(lmfcolor) && ~isequal(lmfcolor,BLACK) && ...
                    ~isequal(lmfcolor,WHITE) && ~isequal(lmfcolor,axColor)
                if (isequal(lmfcolor,axContrast))
                    set(l,'markerfacecolor',1-axContrast)
                else
                    set(l,'markerfacecolor',axContrast)
                end
            end
            
            %Don't change EdgeColor if it's one of the strings
            %  or the same color as the face itself.
            if ~ischar(lmecolor) && ~isequal(lmecolor,BLACK) && ...
                    ~isequal(lmecolor,WHITE) && ~isequal(lmecolor,axColor)
                % if it WAS same as markerfacecolor, want it to be same now
                %   (may or may not actually change)
                if isequal( lmecolor, lmfcolor)
                    set(l, 'markeredgecolor', get(l, 'markerfacecolor'));
                else
                    if (isequal(lmfcolor,axContrast))
                        set(l,'markeredgecolor',1-axContrast)
                    else
                        set(l,'markeredgecolor',axContrast)
                    end
                end
            end
        end
    end

    %----------------------------------------------------------------
    function restoreLineColors
        % Restore lines
        for n = 1:length(orig.lineObj)
            l = orig.lineObj(n).lineObject;
            lcolor = orig.lineObj(n).color;
            lmecolor = orig.lineObj(n).markerEdgeColor;
            lmfcolor = orig.lineObj(n).markerFaceColor;
            
            set(l,'color',lcolor )
            set(l,'markeredgecolor',lmecolor )
            set(l,'markerfacecolor',lmfcolor)
            
            if ~isempty(findprop(handle(l), 'ColorMode')) && ~isempty(findprop(handle(l), 'MarkerEdgeColorMode')) ...
                    && ~isempty(findprop(handle(l), 'MarkerFaceColorMode'))
                set(l, 'ColorMode', orig.lineObj(n).colorMode);
                set(l, 'MarkerEdgeColorMode', orig.lineObj(n).markerEdgeColorMode);
                set(l, 'MarkerFaceColorMode', orig.lineObj(n).markerFaceColorMode); 
            end
        end
    end

    %----------------------------------------------------------------     
    function saveAndChangeGraphPlotColors(kids)
        robjs = findall(kids,'type','graphplot', ...
                             '-depth', 0);
            
        nrobjs = length(robjs);
        already.graphplot = length(di.graphplotObj);
        
        for n = 1:nrobjs
            r = robjs(n);
            ecolor = get(r,'edgecolor');
            ncolor = get(r,'nodecolor');
            idx = already.graphplot+n;
            
            di.graphplotObj(idx).graphplotObject = r;
            di.graphplotObj(idx).EdgeColor = ecolor;
            di.graphplotObj(idx).NodeColor = ncolor;
            
            % Don't change color if it is:
            % a) is None
            % b) is same as the Axes background
            % c) it is Black or White
            if ~( strcmp(ecolor,'none') || isequal(ecolor,axColor) ...
                    || isequal(ecolor,BLACK) || isequal(ecolor,WHITE) )
                set(r,'edgecolor',axContrast)
            end
            if ~( strcmp(ncolor,'none') || isequal(ncolor,axColor) ...
                    || isequal(ncolor,BLACK) || isequal(ncolor,WHITE) )
                set(r,'nodecolor',axContrast)
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreGraphPlotColors()
        for n = 1:length(orig.graphplotObj)
            r = orig.graphplotObj(n).graphplotObject;
            ecolor = orig.graphplotObj(n).EdgeColor;
            ncolor = orig.graphplotObj(n).NodeColor;
            
            set(r,'edgecolor',ecolor)
            set(r,'nodecolor',ncolor)
        end
    end
    %----------------------------------------------------------------     
    function saveAndChangeConstantLineColors(kids)
        robjs = findall(kids,'type','constantline', ...
                             '-depth', 0);
    
        nrobjs = length(robjs);
        already.constantline = length(di.constantlineObj);
        
        for n = 1:nrobjs
            r = robjs(n);
            color = get(r,'color');
            idx = already.constantline+n;
            
            di.constantlineObj(idx).constantlineObj = r;
            di.constantlineObj(idx).Color = color;
            
            if ~( strcmp(color,'none') || isequal(color,axColor) ...
                    || isequal(color,BLACK) || isequal(color,WHITE) )
                set(r,'color',axContrast)
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreConstantLineColors()
        for n = 1:length(orig.constantlineObj)
            r = orig.constantlineObj(n).constantlineObj;
            color = orig.constantlineObj(n).Color;
            set(r,'color',color)
        end
    end    

    %----------------------------------------------------------------     
    function saveAndChangeSurfacePlotColors(kids)
        sobjs = findall(kids, ...
            'type','surface','-or',...
            'type','functionsurface','-or', ...
            'type','parameterizedfunctionsurface', ...
            '-depth', 0);
        nsobjs = length(sobjs);
        already.surface = length(di.surfaceObj);
        
        for n = 1:nsobjs
            s = sobjs(n);
            secolor = get(s,'edgecolor');
            sfcolor = get(s,'facecolor');
            smecolor = get(s,'markeredgecolor');
            smfcolor = get(s,'markerfacecolor');
            idx = already.surface+n;
            
            % Save the surface plot and its current colors for the restore
            di.surfaceObj(idx).surfaceObject = s;
            di.surfaceObj(idx).EdgeColor = secolor;
            di.surfaceObj(idx).faceColor = sfcolor;
            di.surfaceObj(idx).markerEdgeColor = smecolor;
            di.surfaceObj(idx).markerFaceColor = smfcolor;
            
            if ~isempty(findprop(handle(s), 'EdgeColorMode')) && ~isempty(findprop(handle(s), 'FaceColorMode')) && ...
                    ~isempty(findprop(handle(s), 'MarkerEdgeColorMode')) && ...
                    ~isempty(findprop(handle(s), 'MarkerFaceColorMode'))
                
                di.surfaceObj(idx).EdgeColorMode = get(s, 'EdgeColorMode');
                di.surfaceObj(idx).faceColorMode = get(s, 'FaceColorMode');
                di.surfaceObj(idx).markerEdgeColorMode = get(s, 'MarkerEdgeColorMode');
                di.surfaceObj(idx).markerFaceColorMode = get(s, 'MarkerFaceColorMode');
            end

            edgesUseCdata = strcmp(secolor,'flat') | strcmp(secolor,'interp');
            %       markerEdgesUseCdata = strcmp(smecolor,'flat') | ...
            % 	  (strcmp(smecolor,'auto') & edgesUseCdata);
            nanInCdata = false;
            if ~isempty(findprop(s, 'cdata'))
                nanInCdata = any(find(isnan(get(s, 'cdata'))));
            end
            
            %Don't change EdgeColor if it is
            % a) it is the same as the FaceColor
            % b) is None
            % c) is same as the Axes background
            % d) it is Black or White
            % e) the edges use cdata and there is a nan in the cdata
            if ~( isequal(secolor, sfcolor) || strcmp(secolor,'none') || isequal(secolor,axColor) ...
                    || isequal(secolor,BLACK) || isequal(secolor,WHITE) ...
                    || (edgesUseCdata && nanInCdata))
                if (isequal(sfcolor,axContrast))
                    set(s,'edgecolor',1-axContrast)
                else
                    set(s,'edgecolor',axContrast)
                end
                edgecolormapped = 1;
            else
                edgecolormapped = 0;
            end
            
            %Look for surfaces that want to be treated like lines. All
            %surfaces where the AppData property 'NoDither' exists and is
            %set to 'on' are treated like lines.
            if isappdata(s,'NoDither') && strcmp(getappdata(s,'NoDither'),'on')
                if (~isequal(sfcolor,BLACK) && ~isequal(sfcolor,WHITE) && ...
                        ~isequal(sfcolor,axColor))
                    set(s,'facecolor',axContrast)
                end
                if (~isequal(secolor,BLACK) && ~isequal(secolor,WHITE) && ...
                        ~isequal(secolor,axColor))
                    set(s,'edgecolor',axContrast)
                end
            end
            
            %Don't change EdgeColor if it is
            % a) it is the same as the FaceColor
            % b) is None
            % c) is same as the Axes background
            % d) it is Black or White
            % e) the markeredges are flat and the edges weren't mapped
            % f) the markeredges are auto and the edges weren't mapped
            if ~strcmp(smecolor,'none') && ...
                    ~isequal(smecolor,sfcolor) && ~isequal(smecolor,BLACK) && ...
                    ~isequal(smecolor,WHITE) && ~isequal(smecolor,axColor) && ...
                    ~(strcmp(smecolor,'auto') && ~edgecolormapped) && ...
                    ~(strcmp(smecolor,'flat') && ~edgecolormapped)
                if (isequal(smfcolor,axContrast))
                    set(s,'markeredgecolor',1-axContrast)
                else
                    set(s,'markeredgecolor',axContrast)
                end
            end
            
            %Don't change MarkerFaceColor if it is
            % a) same as the FaceColor
            % b) None
            % c) same as the Axes Background
            % d) Black or White
            % e) the marker faces are auto and the edges weren't mapped
            if ~strcmp(smfcolor,'none') && ...
                    ~isequal(smfcolor,sfcolor) && ~isequal(smfcolor,BLACK) && ...
                    ~isequal(smfcolor,WHITE) && ~isequal(smfcolor,axColor) && ...
                    ~(strcmp(smfcolor,'auto') && ~edgecolormapped) && ...
                    ~(strcmp(smfcolor,'flat') && ~edgecolormapped)
                if (isequal(smfcolor,axContrast))
                    set(s,'markerfacecolor',1-axContrast)
                else
                    set(s,'markerfacecolor',axContrast)
                end
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreSurfacePlotColors()
        % Restore surface objects
        for n = 1:length(orig.surfaceObj)
            s = orig.surfaceObj(n).surfaceObject;
            sfcolor = orig.surfaceObj(n).faceColor;
            secolor = orig.surfaceObj(n).EdgeColor;
            smecolor = orig.surfaceObj(n).markerEdgeColor;
            smfcolor = orig.surfaceObj(n).markerFaceColor;
            
            set(s,'facecolor',sfcolor)
            set(s,'edgecolor',secolor)
            set(s,'markeredgecolor',smecolor)
            set(s,'markerfacecolor',smfcolor)
            
            if ~isempty(findprop(handle(s), 'EdgeColorMode')) && ~isempty(findprop(handle(s), 'FaceColorMode')) && ...
                    ~isempty(findprop(handle(s), 'MarkerEdgeColorMode')) && ...
                    ~isempty(findprop(handle(s), 'MarkerFaceColorMode'))
                set(s,'EdgeColorMode', orig.surfaceObj(n).EdgeColorMode)
                set(s,'FaceColorMode', orig.surfaceObj(n).faceColorMode)
                set(s,'MarkerEdgeColorMode', orig.surfaceObj(n).markerEdgeColorMode)
                set(s,'MarkerFaceColorMode', orig.surfaceObj(n).markerFaceColorMode)
            end
        end
    end
    
    %----------------------------------------------------------------
    function startIdx = saveTextColors(kids)
        startIdx = 0; % assume no objects of interest already exist
        tobjs = findall(kids,'type','text','-depth', 0);
        ntobjs = length(tobjs);
        if ntobjs > 0
            startIdx = length(di.textObj) + 1; 
            already.text = length(di.textObj);
            for n = 1:ntobjs
                t = tobjs(n);
                tcolor = get(t,'color');
                idx = already.text+n;
                
                di.textObj(idx).textObject = t;
                di.textObj(idx).color = tcolor;
                if ~isempty(findprop(handle(t), 'ColorMode'))
                    di.textObj(idx).colorMode = get(t, 'ColorMode');
                end
            end
        end
    end
   
    %----------------------------------------------------------------
    function changeTextColors(a, startIdx)
        if ~startIdx 
            return; % nothing to do
        end
        ntobjs = length(di.textObj) - startIdx + 1;
        if ntobjs > 0
            if ~isempty(findprop(handle(a), 'XLabel_IS')) && ~isempty(findprop(handle(a), 'YLabel_IS')) && ...
                    ~isempty(findprop(handle(a), 'ZLabel_IS')) && ~isempty(findprop(handle(a), 'Title_IS'))
                aLabels = get(a, {'XLabel_IS';'YLabel_IS';'ZLabel_IS';'Title_IS'});
                aLabels = cat(1, aLabels{:})'; % turn cell array into row vector
            else
                aLabels = [];
            end
        end        
        for idx = startIdx:length(di.textObj)
            t = di.textObj(idx).textObject;
            tcolor = di.textObj(idx).color;
            if (~isequal(tcolor,BLACK) && ~isequal(tcolor,WHITE) && ~strcmp(tcolor, 'none') )
                if find(t==aLabels)
                    %This will fail if user positions labels within Axis
                    %so that is must contrast a different color then figColor.
                    if ~isequal(tcolor,figColor)
                        set(t,'color',figContrast)
                    end
                else
                    if ~isequal(tcolor,axColor) && ~strcmp(tcolor, 'none')
                        bkColor = get(t, 'BackgroundColor');
                        if isequal(bkColor, axContrast)
                            % If the background color of the text is
                            % the same as the axis contrast color,
                            % don't set the text to it, otherwise the
                            % text color and background color will be
                            % the same, and the text will not be
                            % visible.  Use a contrasting color of the
                            % background color instead.
                            set(t, 'Color', bwcontr(bkColor));
                        else
                            set(t, 'color', axContrast)
                        end
                    end
                end
            end
        
        end
    end
   
    %----------------------------------------------------------------
    function restoreTextColors()
        % Restore text objects
        for n = 1:length(orig.textObj)
            t = orig.textObj(n).textObject;
            tcolor = orig.textObj(n).color;
            set(t,'color',tcolor)
            
            if ~isempty(findprop(handle(t), 'ColorMode'))
                set(t, 'ColorMode', orig.textObj(n).colorMode);
            end
        end
    end
    
    %---------------------------------------------------------------- 
    function saveAndChangeRectangleColors(kids)
       robjs = findall(kids,'type','rectangle', '-or', ...
                           'type','area', '-or', ...
                           'type','histogram', '-or', ...
                           'type','histogram2', '-or', ...
                           'type','categoricalhistogram', '-or', ...
                           'type','bar', ...
                           '-depth', 0);
            
        nrobjs = length(robjs);
        already.rect = length(di.rectObj);
        
        for n = 1:nrobjs
            r = robjs(n);
            recolor = get(r,'edgecolor');
            rfcolor = get(r,'facecolor');
            idx = already.rect+n;
            
            % contrastcolors doesn't change the Rectangle FaceColor, so
            % although we retrieve the value above, we don't need to save
            % it in the rectObj struct for the restore.  Similarly, we
            % don't need to save the FaceColorMode if it is a property of
            % the rectangle object.
            di.rectObj(idx).rectObject = r;
            di.rectObj(idx).EdgeColor = recolor;
            if ~isempty(findprop(handle(r), 'EdgeColorMode'))
                di.rectObj(idx).EdgeColorMode = get(r, 'EdgeColorMode');
            end
            
            %Don't change EdgeColor if it is:
            % a) it is the same as the FaceColor
            % b) is None
            % c) is same as the Axes background
            % b) it is Black or White
            if ~( isequal(recolor, rfcolor) || strcmp(recolor,'none') || isequal(recolor,axColor) ...
                    || isequal(recolor,BLACK) || isequal(recolor,WHITE) )
                if (isequal(rfcolor,axContrast))
                    set(r,'edgecolor',1-axContrast)
                else
                    set(r,'edgecolor',axContrast)
                end
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreRectangleColors()
        % Restore rectangles
        for n = 1:length(orig.rectObj)
            r = orig.rectObj(n).rectObject;
            rcolor = orig.rectObj(n).EdgeColor;
            
            set(r,'edgecolor',rcolor)
            if ~isempty(findprop(handle(r), 'EdgeColorMode'))
                set(r, 'EdgeColorMode', orig.rectObj(n).EdgeColorMode);
            end
        end
    end
    
    %----------------------------------------------------------------
    
    %----------------------------------------------------------------
   function saveAndChangePolygonColors(kids)
       pobjs = findall(kids,'type','polygon','-depth', 0);
            
        npobjs = length(pobjs);
        already.polygon = length(di.polygonObj);
        
        for n = 1:npobjs
            p = pobjs(n);
            pecolor = get(p,'edgecolor');
            pfcolor = get(p,'facecolor');
            idx = already.polygon+n;
            
            % contrastcolors doesn't change the Polygon's FaceColor, so
            % although we retrieve the value above, we don't need to save
            % it in the polygonObj struct for the restore.
            di.polygonObj(idx).polygonObject = p;
            di.polygonObj(idx).EdgeColor = pecolor;
            
            %Don't change EdgeColor if it is:
            % a) it is the same as the FaceColor
            % b) is None
            % c) is same as the Axes background
            % b) it is Black or White
            if ~( isequal(pecolor, pfcolor) || strcmp(pecolor,'none') || isequal(pecolor,axColor) ...
                    || isequal(pecolor,BLACK) || isequal(pecolor,WHITE) )
                if (isequal(pfcolor,axContrast))
                    set(p,'edgecolor',1-axContrast)
                else
                    set(p,'edgecolor',axContrast)
                end
            end
        end
   end

    %----------------------------------------------------------------
    function restorePolygonColors()
        % Restore edgecolors for Polygons
        for n = 1:length(orig.polygonObj)
            p = orig.polygonObj(n).polygonObject;
            pcolor = orig.polygonObj(n).EdgeColor;
            
            set(p,'edgecolor',pcolor);
        end
    end
    
    
    %----------------------------------------------------------------
    function saveAndChangePatchColors(kids)
        pobjs = findall(kids,'type','patch','-depth', 0);
        npobjs = length(pobjs);
        already.patch = length(di.patchObj);
        
        for n = 1:npobjs
            p = pobjs(n);
            pecolor = get(p,'edgecolor');
            pfcolor = get(p,'facecolor');
            pmecolor = get(p,'markeredgecolor');
            pmfcolor = get(p,'markerfacecolor');
            idx = already.patch+n;
            
            % Save the patch object and its current colors for the restore
            di.patchObj(idx).patchObject = p;
            di.patchObj(idx).EdgeColor = pecolor;
            di.patchObj(idx).faceColor = pfcolor;
            di.patchObj(idx).markerEdgeColor = pmecolor;
            di.patchObj(idx).markerFaceColor = pmfcolor;
            
            if ~isempty(findprop(handle(p), 'EdgeColorMode')) && ~isempty(findprop(handle(p), 'FaceColorMode')) && ...
                    ~isempty(findprop(handle(p), 'MarkerEdgeColorMode')) && ...
                    ~isempty(findprop(handle(p), 'MarkerFaceColorMode'))
                di.patchObj(idx).EdgeColorMode = get(p, 'EdgeColorMode');
                di.patchObj(idx).faceColorMode = get(p, 'FaceColorMode');
                di.patchObj(idx).markerEdgeColorMode = get(p, 'MarkerEdgeColorMode');
                di.patchObj(idx).markerFaceColorMode = get(p, 'MarkerFaceColorMode');
            end
            
            edgesUseCdata = strcmp(pecolor,'flat') | strcmp(pecolor,'interp');
            %       markerEdgesUseCdata = strcmp(pmecolor,'flat') | ...
            % 	  (strcmp(pmecolor,'auto') & edgesUseCdata);
            XdatananPos = isnan(get(p, 'xdata'));
            CdatananPos = isnan(get(p, 'cdata'));
            nanInCdata = any(CdatananPos(:));
            
            %Don't change EdgeColor if it is:
            % a) it is the same as the FaceColor
            % b) is None
            % c) is same as the Axes background
            % d) it is Black or White
            % e) the edges use cdata and there is a nan in the
            %    cdata and the position of the nans in the cdata
            %    and xdata differ (Contour plots have nans in cdata
            %    and vertices in the same positions -> we do want
            %    to change the edgecolors to black. But we do not
            %    want edges with nans in cdata without a corresponding
            %    nan in the vertices to suddenly appear when printing.)
            if ~( isequal(pecolor, pfcolor) || strcmp(pecolor,'none') || ...
                    isequal(pecolor,axColor) ...
                    || isequal(pecolor,BLACK) || isequal(pecolor,WHITE) ...
                    || (edgesUseCdata && nanInCdata && ~isequal(XdatananPos, CdatananPos)))
                if (isequal(pfcolor,axContrast))
                    set(p,'edgecolor',1-axContrast)
                else
                    set(p,'edgecolor',axContrast)
                end
                edgecolormapped = 1;
            else
                edgecolormapped = 0;
            end
            
            %Look for patches that want to be treated like lines
            %(e.g. arrow heads).  All patches where the AppData property
            %'NoDither' exists and is set to 'on' are treated like lines.
            if isappdata(p,'NoDither') && strcmp(getappdata(p,'NoDither'),'on')
                if (~isequal(pfcolor,BLACK) && ~isequal(pfcolor,WHITE) && ...
                        ~isequal(pfcolor,axColor))
                    set(p,'facecolor',axContrast)
                end
                if (~isequal(pecolor,BLACK) && ~isequal(pecolor,WHITE) && ...
                        ~isequal(pecolor,axColor))
                    set(p,'edgecolor',axContrast)
                end
            end
            
            %Don't change EdgeColor if it is
            % a) it is the same as the FaceColor
            % b) is None
            % c) is same as the Axes background
            % d) it is Black or White
            % e) the markeredges are flat and the edges weren't mapped
            % f) the marker edges are auto and the edges weren't mapped
            if ~strcmp(pmecolor,'none') && ...
                    ~isequal(pmecolor,pfcolor) && ~isequal(pmecolor,BLACK) && ...
                    ~isequal(pmecolor,WHITE) && ~isequal(pmecolor,axColor) && ...
                    ~(strcmp(pmecolor,'auto') && ~edgecolormapped) && ...
                    ~(strcmp(pmecolor,'flat') && ~edgecolormapped)
                if (isequal(pmfcolor,axContrast))
                    set(p,'markeredgecolor',1-axContrast)
                else
                    set(p,'markeredgecolor',axContrast)
                end
            end
            
            %Don't change MarkerFaceColor if it is
            % a) same as the FaceColor
            % b) None
            % c) same as the Axes Background
            % d) Black or White
            % e) the marker faces are auto and the edges weren't mapped
            if ~strcmp(pmfcolor,'none') && ...
                    ~isequal(pmfcolor,pfcolor) && ~isequal(pmfcolor,BLACK) && ...
                    ~isequal(pmfcolor,WHITE) && ~isequal(pmfcolor,axColor) && ...
                    ~(strcmp(pmfcolor,'auto') && ~edgecolormapped) && ...
                    ~(strcmp(pmfcolor,'flat') && ~edgecolormapped)
                if (isequal(pmfcolor,axContrast))
                    set(p,'markerfacecolor',1-axContrast)
                else
                    set(p,'markerfacecolor',axContrast)
                end
            end
        end
    end
    
    %----------------------------------------------------------------
    function restorePatchColors()
        % Restore patch objects
        for n = 1:length(orig.patchObj)
            p = orig.patchObj(n).patchObject;
            sfcolor = orig.patchObj(n).faceColor;
            secolor = orig.patchObj(n).EdgeColor;
            smecolor = orig.patchObj(n).markerEdgeColor;
            smfcolor = orig.patchObj(n).markerFaceColor;
            
            set(p,'facecolor',sfcolor)
            set(p,'edgecolor',secolor)
            set(p,'markeredgecolor',smecolor)
            set(p,'markerfacecolor',smfcolor)
            
            if ~isempty(findprop(handle(p), 'EdgeColorMode')) && ~isempty(findprop(handle(p), 'FaceColorMode')) && ...
                    ~isempty(findprop(handle(p), 'MarkerEdgeColorMode')) && ...
                    ~isempty(findprop(handle(p), 'MarkerFaceColorMode'))
                set(p, 'EdgeColorMode', orig.patchObj(n).EdgeColorMode);
                set(p, 'FaceColorMode', orig.patchObj(n).faceColorMode);
                set(p, 'MarkerEdgeColorMode', orig.patchObj(n).markerEdgeColorMode);
                set(p, 'MarkerFaceColorMode', orig.patchObj(n).markerFaceColorMode);
            end
        end
    end
        
    %----------------------------------------------------------------
    function saveAndChangeAnnotationColors(figKids)
        objs = findall(figKids, {'Type','arrowshape','-or',...
 	                         'Type','doubleendarrowshape','-or',...
 	                         'Type','textarrowshape','-or',...
 	                         'Type','lineshape','-or',...
 	                         'Type','ellipseshape','-or',...
 	                         'Type','rectangleshape','-or',...
 	                         'Type','textboxshape'},...
                             'Visible', 'on');
        
        naobjs = length(objs);
        already.annot = length(di.annotObj);

        % this is a best-guess. The annotations generally sit
        % on top of an axes, but we don't know which one. 
        bkgColor = get(groot, 'DefaultAxesColor');
        if strcmp(bkgColor, 'none')
            % if there's no axes color then use the underlying figure color
            bkgColor = figColor; 
        end
        
        bkgContrast = bwcontr(bkgColor);
        for n = 1:naobjs
            aObj = objs(n);
            idx = already.annot+n;
            di.annotObj(idx).annotObject = aObj;
            
            if ~isempty(findprop(handle(aObj), 'Color'))
                aColor = get(aObj,'Color');
                
                    
                di.annotObj(idx).color = aColor;
                if ~isempty(findprop(handle(aObj), 'ColorMode'))
                    di.annotObj(idx).colorMode = get(aObj, 'ColorMode');
                end
                
                if (~isequal(aColor,BLACK) && ~isequal(aColor,WHITE) && ...
                        ~strcmp(aColor,'none') && ~isequal(aColor, bkgColor))
                    set(aObj,'Color', bkgContrast)
                end
            else
                aColor = nan;
                di.annotObj(idx).color = aColor;
            end
            
            if ~isempty(findprop(handle(aObj), 'TextColor'))
                atcolor = get(aObj,'TextColor');
                di.annotObj(idx).textColor = atcolor;
                if ~isempty(findprop(handle(aObj), 'TextColorMode'))
                    di.annotObj(idx).textColorMode = get(aObj, 'TextColorMode');
                end
                
                % We don't want to change the text color if 
                % * it's already black or white 
                % * it's "none" (invisible)
                % * it's the same as the background color (because that
                %       ALSO means it's invisible) 
                % AND we don't want to change it if the color we would
                % change it to isn't valid 
                if (~isequal(atcolor, BLACK) && ~isequal(atcolor, WHITE) && ... 
                        ~strcmp(atcolor, 'none') && ~isequal(atcolor, bkgColor) && ...
                        ~any(isnan(bkgContrast)))
                   set(aObj,'TextColor', bkgContrast)
                end
            else
                di.annotObj(idx).textColor = nan;
            end
                       
            if ~isempty(findprop(handle(aObj), 'TextEdgeColor'))
                atecolor = get(aObj, 'TextEdgeColor');
                di.annotObj(idx).textEdgeColor = atecolor;
                if ~isempty(findprop(handle(aObj), 'TextEdgeColorMode'))
                    di.annotObj(idx).textEdgeColorMode = get(aObj, 'TextEdgeColorMode');
                end
                
                % Don't change TextEdgeColor if it is:
                % a) it is the same as the FaceColor
                % b) is None
                % c) is same as the Axes background
                % b) it is Black or White
                if (~isequal(atecolor, BLACK) && ~isequal(atecolor, WHITE) && ... 
                        ~strcmp(atecolor, 'none') && ~isequal(atecolor, bkgColor) && ...
                        ~any(isnan(bkgContrast)))
                   set(aObj,'TextEdgeColor', bkgContrast)
                end
            else
                di.annotObj(idx).textEdgeColor = nan;
            end
            
            if ~isempty(findprop(handle(aObj), 'EdgeColor'))
                aEdgeColor = get(aObj,'EdgeColor');
                    
                di.annotObj(idx).edgeColor = aEdgeColor;
                if ~isempty(findprop(handle(aObj), 'EdgeColorMode'))
                    di.annotObj(idx).edgeColorMode = get(aObj, 'EdgeColorMode');
                end
                
                if (~isequal(aEdgeColor,BLACK) && ~isequal(aEdgeColor,WHITE) && ...
                        ~strcmp(aEdgeColor,'none') && ~isequal(aEdgeColor, bkgColor))
                    set(aObj,'EdgeColor', bkgContrast)
                end
            else
                aEdgeColor = nan;
                di.annotObj(idx).edgeColor = aEdgeColor;
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreAnnotationColors()
        % Restore annotation objects
        for n = 1:length(orig.annotObj)
            a = orig.annotObj(n).annotObject;
            acolor = orig.annotObj(n).color;
            atcolor = orig.annotObj(n).textColor;
            atecolor = orig.annotObj(n).textEdgeColor;
            aecolor = orig.annotObj(n).edgeColor;

            % EdgeColor & EdgeColorMode
            if ~isempty(findprop(handle(a), 'EdgeColor')) && ~any(isnan(aecolor))
                set(a, 'EdgeColor', aecolor)

                if ~isempty(findprop(handle(a), 'EdgeColorMode'))
                    set(a, 'EdgeColorMode', orig.annotObj(n).edgeColorMode)
                end
            end

            % TextColor & TextColorMode
            if ~isempty(findprop(handle(a), 'TextColor')) && ~any(isnan(atcolor))
                set(a, 'TextColor', atcolor)
                
                if ~isempty(findprop(handle(a), 'TextColorMode'))
                    set(a, 'TextColorMode', orig.annotObj(n).textColorMode)
                end
            end
            
            % TextEdgeColor & TextEdgeColorMode
            if ~isempty(findprop(handle(a), 'TextEdgeColor')) && ~any(isnan(atecolor))
                set(a, 'TextEdgeColor', atecolor)
                
                if ~isempty(findprop(handle(a), 'TextEdgeColorMode'))
                    set(a, 'TextEdgeColorMode', orig.annotObj(n).textEdgeColorMode)
                end
            end

            % Color & ColorMode
            if ~isempty(findprop(handle(a), 'Color')) && ~any(isnan(acolor))
                set(a, 'Color', acolor)

                if ~isempty(findprop(handle(a), 'ColorMode'))
                    set(a, 'ColorMode', orig.annotObj(n).colorMode)
                end
            end
        end
    end

    function saveAndChangeSubplotTextColors(objs)
        
        % save subplot text objects
        noobjs = length(objs); 
        already.subplotText = length(di.subplotTextObj);
        startIdx = length(di.subplotTextObj) + 1; 
        for n = 1:noobjs
            t = objs(n);
            tcolor = get(t, 'color');
            idx = already.subplotText + n;    
            di.subplotTextObj(idx).textObject = t;
            di.subplotTextObj(idx).color = tcolor;
        end
        
        %change objects
        for idx = startIdx:length(di.subplotTextObj)
            t = di.subplotTextObj(idx).textObject;
            tcolor = di.subplotTextObj(idx).color;
            if (~isequal(tcolor,BLACK) && ~isequal(tcolor,WHITE) && ~strcmp(tcolor, 'none') )
                if ~isequal(tcolor,figColor)
                    set(t,'color',figContrast)
                end
            end
        end
    end

    function restoreSubplotTextColors()
        for n = 1:length(orig.subplotTextObj)
            t = orig.subplotTextObj(n).textObject;
            tcolor = orig.subplotTextObj(n).color;
            set(t,'color',tcolor)
        end
    end
    %----------------------------------------------------------------
    function saveAndChangeLegendColors(objs)
        % Handle other objects which may
        % not have the X/Y/Z Color properties
        noobjs = length(objs);
        already.legend = length(di.legendObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = already.legend+n;
            di.legendObj(idx).legendObject = obj;
            
            legcolor = get(obj, 'Color');
            if strcmp(legcolor, 'none') 
                legcolor = BLACK; 
            end
            legContrast = bwcontr(legcolor); 
            di.legendObj(idx).color = legcolor;
            
            legTextColor = get(obj,'TextColor');
            di.legendObj(idx).textColor = legTextColor;
            di.legendObj(idx).textColorMode = get(obj, 'TextColorMode');

            % don't change legend text color if it is already black or
            % white, and also don't change it if it's the legend color
            % (background) or 'none'
            if (~isequal(legTextColor, BLACK) && ~isequal(legTextColor, WHITE) && ...
                     ~isequal(legTextColor, legcolor) && ~strcmp(legTextColor, 'none'))
                 set(obj, 'TextColor', legContrast)
            end
            
            legEdgeColor = get(obj, 'EdgeColor');
            di.legendObj(idx).EdgeColor = legEdgeColor;
            di.legendObj(idx).EdgeColorMode = get(obj, 'EdgeColorMode');

            % Don't change EdgeColor if it is:
            % a) the same as the legend color (background)
            % b) None
            % c) Black or White
            if ~( isequal(legEdgeColor, legcolor) || strcmp(legEdgeColor,'none') || ...
                  isequal(legEdgeColor,BLACK)     || isequal(legEdgeColor,WHITE) )
                legEdgeContrast = bwcontr(legEdgeColor);
                if (isequal(legcolor ,legEdgeContrast))
                    set(obj, 'EdgeColor', 1-legEdgeContrast)
                else
                    set(obj, 'EdgeColor', legEdgeContrast)
                end
            end
            
            % Get a handle to the legend title. Use Title_I so that the
            % title object is not created if it does not already exist.
            if ~isempty(obj.Title_I) && isvalid(obj.Title_I)
                titleObj = obj.Title;
                legTitleColor = get(titleObj, 'Color');
                di.legendObj(idx).TitleColor = legTitleColor;
                di.legendObj(idx).TitleColorMode = get(titleObj, 'ColorMode');
                
                % Don't change Title Color if it is:
                % a) The same as the legend color (background)
                % b) None
                % c) Black or White
                if ~( isequal(legTitleColor, legcolor) || strcmp(legTitleColor,'none') || ...
                      isequal(legTitleColor,BLACK)     || isequal(legTitleColor,WHITE) )
                    legTitleContrast = bwcontr(legTitleColor);
                    if (isequal(legcolor ,legTitleContrast))
                        set(titleObj, 'Color', 1-legTitleContrast)
                    else
                        set(titleObj, 'Color', legTitleContrast)
                    end
                end
            else
                di.legendObj(idx).TitleColor = [];
                di.legendObj(idx).TitleColorMode = [];
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreLegendColors()
        % Restore other objects 
        for n = 1:length(orig.legendObj)
            a = orig.legendObj(n).legendObject;
            atcolor = orig.legendObj(n).textColor;
            atecolor = orig.legendObj(n).EdgeColor;
            
            % EdgeColor & EdgeColorMode
            if ~isempty(findprop(handle(a), 'EdgeColor')) && ~any(isnan(atecolor))
                set(a, 'EdgeColor', atecolor)
                
                if ~isempty(findprop(handle(a), 'EdgeColorMode'))
                    set(a, 'EdgeColorMode', orig.legendObj(n).EdgeColorMode)
                end
            end
  
            % TextColor & TextColorMode
            if ~isempty(findprop(handle(a), 'TextColor')) && ~any(isnan(atcolor))
                set(a, 'TextColor', atcolor)
                
                if ~isempty(findprop(handle(a), 'TextColorMode'))
                    set(a, 'TextColorMode', orig.legendObj(n).textColorMode);
                end
            end
            
            % Title Color
            if ~isempty(orig.legendObj(n).TitleColor) && ...
                    ~isempty(orig.legendObj(n).TitleColorMode)
                
                % Grab a handle to the title object
                titleObj = a.Title;

                % Set the color and colormode back to the way we found them.
                set(titleObj, 'Color', orig.legendObj(n).TitleColor, 'ColorMode', orig.legendObj(n).TitleColorMode);
                
            end % End Title Color
        end % End for loop
    end
    %----------------------------------------------------------------     
    function saveAndChangeChartObjColors(kids)
        coobjs = findall(kids, 'type', 'scatter', ...
                         '-depth', 0);
        ncobjs = length(coobjs);
        already.chart = length(di.chartObj);
        
        for n = 1:ncobjs
            co = coobjs(n);
            comecolor = get(co,'markeredgecolor');
            comfcolor = get(co,'markerfacecolor');
            idx = already.chart+n;
            
            % Save the line and its current colors for the restore
            di.chartObj(idx).chartObject = co;
            di.chartObj(idx).markerEdgeColor = comecolor;
            di.chartObj(idx).markerFaceColor = comfcolor;
            
            if ~isempty(findprop(handle(co), 'MarkerEdgeColorMode')) ...
                    && ~isempty(findprop(handle(co), 'MarkerFaceColorMode'))
                di.chartObj(idx).markerEdgeColorMode = get(co, 'MarkerEdgeColorMode');
                di.chartObj(idx).markerFaceColorMode = get(co, 'MarkerFaceColorMode');
            end

            %Don't change MarkerEdgeColor if it is
            % a) it is the same as the MarkerFaceColor
            % b) is None
            % c) is same as the Axes background
            % d) it is Black or White
            if ~strcmp(comecolor,'none') && ...
                    ~isequal(comecolor,comfcolor) && ~isequal(comecolor,BLACK) && ...
                    ~isequal(comecolor,WHITE) && ~isequal(comecolor,axColor)
                if (isequal(comfcolor,axContrast))
                    set(co,'markeredgecolor',1-axContrast)
                else
                    set(co,'markeredgecolor',axContrast)
                end
            end
            
            %Don't change MarkerFaceColor if it is
            % *) None
            % *) same as the Axes Background
            % *) Black or White
            if ~strcmp(comfcolor,'none') && ...
                    ~isequal(comfcolor,BLACK) && ...
                    ~isequal(comfcolor,WHITE) && ~isequal(comfcolor,axColor) 
                if (isequal(comfcolor,axContrast))
                    set(co,'markerfacecolor',1-axContrast)
                else
                    set(co,'markerfacecolor',axContrast)
                end
            end

        end
    end

    %----------------------------------------------------------------
    function restoreChartObjColors
        % Restore lines
        for n = 1:length(orig.chartObj)
            co = orig.chartObj(n).chartObject;
            comecolor = orig.chartObj(n).markerEdgeColor;
            comfcolor = orig.chartObj(n).markerFaceColor;
            
            set(co,'markeredgecolor',comecolor )
            set(co,'markerfacecolor',comfcolor)
            
            if ~isempty(findprop(handle(co), 'ColorMode')) && ~isempty(findprop(handle(co), 'MarkerEdgeColorMode')) ...
                    && ~isempty(findprop(handle(co), 'MarkerFaceColorMode'))
                set(co, 'MarkerEdgeColorMode', orig.chartObj(n).markerEdgeColorMode);
                set(co, 'MarkerFaceColorMode', orig.chartObj(n).markerFaceColorMode); 
            end
        end
    end
    
    %----------------------------------------------------------------
    function saveAndChangeColorbarColors(objs)
        % Handle colorbar objects
        noobjs = length(objs);
        already.colorbar = length(di.colorbarObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = already.colorbar+n;
            di.colorbarObj(idx).colorbarObject = obj;
            
            cbcolor = get(obj, 'Color');
            di.colorbarObj(idx).color = cbcolor;
            di.colorbarObj(idx).ColorMode = get(obj, 'ColorMode');

            % Don't change Color if it is Black or White or 'none'
            % Otherwise, if it matches figcolor, set it to figcontrast
            if ~(isequal(cbcolor,BLACK) || isequal(cbcolor,WHITE) || ...
                    isequal(cbcolor, figColor) || strcmp(cbcolor, 'none') )
                if (isequal(cbcolor ,figContrast))
                    set(obj, 'Color', 1-figContrast)
                else
                    set(obj, 'Color', figContrast)
                end
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreColorbarColors()
        % Restore colorbar objects
        for n = 1:length(orig.colorbarObj)
            cb = orig.colorbarObj(n).colorbarObject;
            cbcolor = orig.colorbarObj(n).color;
            cbmode =  orig.colorbarObj(n).ColorMode;

            set(cb, 'Color', cbcolor, 'ColorMode', cbmode);
        end
    end
    
    %----------------------------------------------------------------
    function saveAndChangeHeatmapColors(objs)
        % Handle heatmap objects
        noobjs = length(objs);
        numAlready = length(di.heatmapObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = numAlready+n;
            di.heatmapObj(idx).heatmapObject = obj;
            
            fontColor = obj.FontColor;
            cellLabelColor = obj.CellLabelColor;
            di.heatmapObj(idx).FontColor = fontColor;
            di.heatmapObj(idx).CellLabelColor = cellLabelColor;

            % Don't change FontColor if it is black, white, or 'none'.
            % Otherwise, if it matches figcolor, set it to figcontrast
            if ~(isequal(fontColor,BLACK) || isequal(fontColor,WHITE) || ...
                    isequal(fontColor, figColor) || strcmp(fontColor, 'none') )
                obj.FontColor = figContrast;
            end

            % Don't change CellLabelColor if it is black, white, 'none', or 'auto'.
            % Otherwise, change it to 'auto'.
            if ~(isequal(cellLabelColor,BLACK) || isequal(cellLabelColor,WHITE) || ...
                    strcmp(cellLabelColor, 'auto') || strcmp(cellLabelColor, 'none'))
                obj.CellLabelColor = 'auto';
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreHeatmapColors()
        % Restore heatmap objects
        for n = 1:length(orig.heatmapObj)
            h = orig.heatmapObj(n).heatmapObject;
            h.FontColor = orig.heatmapObj.FontColor;
            h.CellLabelColor = orig.heatmapObj.CellLabelColor;
        end
    end
    
    %----------------------------------------------------------------
    function saveAndChangeWordcloudColors(objs)
        % Handle wordcloud objects
        noobjs = length(objs);
        numAlready = length(di.wordcloudObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = numAlready+n;
            di.wordcloudObj(idx).wordcloudObject = obj;
            
            color = obj.Color;
            highlightColor = obj.HighlightColor;
            di.wordcloudObj(idx).Color = color;
            di.wordcloudObj(idx).HighlightColor = highlightColor;

            obj.Color = BLACK;
            obj.HighlightColor = BLACK;
        end
    end
    
    %----------------------------------------------------------------
    function restoreWordcloudColors()
        % Restore wordcloud objects
        for n = 1:length(orig.wordcloudObj)
            h = orig.wordcloudObj(n).wordcloudObject;
            h.Color = orig.wordcloudObj.Color;
            h.HighlightColor = orig.wordcloudObj.HighlightColor;
        end
    end

%----------------------------------------------------------------  
        function saveAndChangeConfusionMatrixChartColors(objs)
        % Handle ConfusionMatrixChart objects, changing FontColor if
        % needed. Unlike heatmap, we don't have a CellLabelColor exposed so
        % we don't need to handle that.
        
        noobjs = length(objs);
        numAlready = length(di.confusionMatrixChartObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = numAlready+n;
            di.confusionMatrixChartObj(idx).confusionMatrixChartObject = obj;
            
            fontColor = obj.FontColor;
            di.confusionMatrixChartObj(idx).FontColor = fontColor;
            
            % Don't change FontColor if it is black, white, or 'none'.
            % Otherwise, if it matches figcolor, set it to figcontrast
            if ~(isequal(fontColor,BLACK) || isequal(fontColor,WHITE) || ...
                    isequal(fontColor, figColor) || strcmp(fontColor, 'none') )
                obj.FontColor = figContrast;
            end
        end
    end

    function restoreConfusionMatrixChartColors()
        % Restore ConfusionMatrixChart objects
        for n = 1:length(orig.confusionMatrixChartObj)
            h = orig.confusionMatrixChartObj(n).confusionMatrixChartObject;
            h.FontColor = orig.confusionMatrixChartObj.FontColor;
        end
    end
  
%----------------------------------------------------------------  
    function saveAndChangeScatterhistogramColors(objs)
        % Handle scatterhistogram objects
        noobjs = length(objs);
        numAlready = length(di.scatterhistogramObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = numAlready+n;
            di.scatterhistogramObj(idx).scatterhistogramObject = obj;
            
            color = obj.Color;
            di.scatterhistogramObj(idx).Color = color;

            obj.Color = BLACK;
        end
    end
    
    %----------------------------------------------------------------
    function restoreScatterhistogramColors()
        % Restore scatterhistogram objects
        for n = 1:length(orig.scatterhistogramObj)
            h = orig.scatterhistogramObj(n).scatterhistogramObject;
            h.Color = orig.scatterhistogramObj.Color;
        end
    end

    %----------------------------------------------------------------  
    function saveAndChangeStackedplotColors(objs)
        % Handle stackedplot objects
        noobjs = length(objs);
        numAlready = length(di.stackedplotObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = numAlready+n;
            di.stackedplotObj(idx).stackedplotObject = obj;
            
            color = {obj.LineProperties.Color};
            markerfacecolor = {obj.LineProperties.MarkerFaceColor};
            markeredgecolor = {obj.LineProperties.MarkerEdgeColor};
            di.stackedplotObj(idx).Color = color;
            di.stackedplotObj(idx).MarkerFaceColor = markerfacecolor;
            di.stackedplotObj(idx).MarkerEdgeColor = markeredgecolor;

            for i = 1:length(obj.LineProperties)
                if ~strcmp(obj.LineProperties(i).Color, 'none')
                    obj.LineProperties(i).Color = BLACK;
                end
                if ~strcmp(obj.LineProperties(i).MarkerFaceColor, 'none')
                    obj.LineProperties(i).MarkerFaceColor = BLACK;
                end
                if ~strcmp(obj.LineProperties(i).MarkerEdgeColor, 'none')
                    obj.LineProperties(i).MarkerEdgeColor = BLACK;
                end
            end
        end
    end
    
    %----------------------------------------------------------------
    function restoreStackedplotColors()
        % Restore stackedplot objects
        for n = 1:length(orig.stackedplotObj)
            h = orig.stackedplotObj(n).stackedplotObject;
            for i = 1:length(h.LineProperties)
                h.LineProperties(i).Color = orig.stackedplotObj(n).Color{i};
                h.LineProperties(i).MarkerFaceColor = orig.stackedplotObj(n).MarkerFaceColor{i};
                h.LineProperties(i).MarkerEdgeColor = orig.stackedplotObj(n).MarkerEdgeColor{i};
            end
        end
    end
    
    %----------------------------------------------------------------
    function saveAndChangeParallelplotColors(objs)
        % Handle parallelplot objects
        noobjs = length(objs);
        numAlready = length(di.parallelplotObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = numAlready+n;
            di.parallelplotObj(idx).parallelplotObject = obj;
            
            color = obj.Color;
            di.parallelplotObj(idx).Color = color;

            obj.Color = BLACK;
        end
    end
    
    %----------------------------------------------------------------
    function restoreParallelplotColors()
        % Restore parallelplot objects
        for n = 1:length(orig.parallelplotObj)
            h = orig.parallelplotObj(n).parallelplotObject;
            h.Color = orig.parallelplotObj.Color;
        end
    end

    %----------------------------------------------------------------
    function saveAndChangeBoxChartColors(objs)
        % Handle parallelplot objects
        noobjs = length(objs);
        numAlready = length(di.boxchartObj);
        
        for n = 1:noobjs
            obj = objs(n);
            idx = numAlready+n;
            di.boxchartObj(idx).boxchartObject = obj;
            
            di.boxchartObj(idx).BoxFaceColor = obj.BoxFaceColor;
            di.boxchartObj(idx).WhiskerLineColor = obj.WhiskerLineColor;
            di.boxchartObj(idx).MarkerColor = obj.MarkerColor;
            di.boxchartObj(idx).BoxEdgeColor = obj.BoxEdgeColor;
            di.boxchartObj(idx).BoxMedianLineColor = obj.BoxMedianLineColor;

            obj.BoxFaceColor = BLACK;
            obj.WhiskerLineColor = BLACK;
            obj.MarkerColor = BLACK;
            obj.BoxEdgeColor = BLACK;
            obj.BoxMedianLineColor = BLACK;

        end
    end
    
    %----------------------------------------------------------------
    function restoreBoxChartColors()
        % Restore parallelplot objects
        for n = 1:length(orig.boxchartObj)
            h = orig.boxchartObj(n).boxchartObject;
            h.BoxFaceColor = orig.boxchartObj(n).BoxFaceColor;
            h.WhiskerLineColor = orig.boxchartObj(n).WhiskerLineColor;
            h.MarkerColor = orig.boxchartObj(n).MarkerColor;
            h.BoxEdgeColor = orig.boxchartObj(n).BoxEdgeColor;
            h.BoxMedianLineColor = orig.boxchartObj(n).BoxMedianLineColor;
        end
    end

    %----------------------------------------------------------------
    function saveAndChangeContourObjColors(kids)
        % Handle contour objects
        cobjs = findall(kids,'type','contour', '-or', 'type','functioncontour', ...
            '-depth', 0);
        
        noobjs = length(cobjs);
        already.contour = length(di.contourObj);
        
        for n = 1:noobjs
            obj = cobjs(n);
            idx = already.contour+n;
            di.contourObj(idx).contourObject = obj;
            
            facecolor = get(obj, 'FaceColor');
            di.contourObj(idx).facecolor = facecolor;
            di.contourObj(idx).facecolorMode = get(obj, 'FaceColorMode');
            linecolor = get(obj, 'LineColor');
            di.contourObj(idx).linecolor = linecolor;
            di.contourObj(idx).linecolorMode = get(obj, 'LineColorMode');

            faceFilled = strcmpi(obj.Fill, 'on'); 
            if faceFilled
                % Filled Contour: don't change lineColor if the
                % current linecolor is
                %    black or white, or 
                %    matches axes color
                %    none, flat or auto
                if ~(isequal(linecolor,BLACK) || isequal(linecolor,WHITE) || ...
                        isequal(linecolor, axColor) || ...
                        any(strcmp(linecolor, {'none', 'flat', 'auto'})) )
                    if (isequal(linecolor ,axContrast))
                        set(obj, 'LineColor', 1-axContrast)
                    else
                        set(obj, 'LineColor', axContrast)
                    end
                end
            else
                % Unfilled contour: don't change line color if the current 
                % linecolor is: 
                %    black or white, or 
                %    the axes color, or
                %    is 'none' 
                %  if we're changing the color, set it to axContrast if the
                %  current color is either:
                %      'flat', 'auto', or not already the axContrast color
                if ~(isequal(linecolor,BLACK) || isequal(linecolor,WHITE) || ...
                        isequal(linecolor, axColor) || ...
                        strcmp(linecolor, 'none') )
                    if any(strcmp(linecolor, {'flat', 'auto'}))
                        set(obj, 'LineColor', axContrast)
                    elseif (isequal(linecolor ,axContrast))
                        set(obj, 'LineColor', 1-axContrast)
                    else
                        set(obj, 'LineColor', axContrast)
                    end
                end
                
            end
        end
    end
    %----------------------------------------------------------------  
    function restoreContourObjColors()
        % Restore contours
        for n = 1:length(orig.contourObj)
            l = orig.contourObj(n).contourObject;

            set(l, 'FaceColor',orig.contourObj(n).facecolor);
            set(l, 'FaceColorMode', orig.contourObj(n).facecolorMode);
            set(l, 'LineColor', orig.contourObj(n).linecolor);
            set(l, 'LineColorMode', orig.contourObj(n).linecolorMode); 
        end
    end
   
    %----------------------------------------------------------------     
    function saveAndChangeBaselineObjColors(kids)
        allBaselines = [];
        thisBaselineParent = findall(kids,'-property', 'BaseLine', 'ShowBaseline', 'on', '-depth', 0);
        if ~isempty(thisBaselineParent) && length(thisBaselineParent) > 1
           thisBaselineParent = thisBaselineParent(1); % there's really only one
        end 
        if ~isempty(thisBaselineParent)
           theBaseline = get(thisBaselineParent, 'BaseLine');
           if LocalIsProp(theBaseline, 'Color')
               if isempty(allBaselines)
                   allBaselines = theBaseline;
               else
                  allBaselines(end+1,1) = theBaseline;
               end
           end
        end
        
        nlobjs = length(allBaselines);
        already.baseline = length(di.baselineObj);
        
        for n = 1:nlobjs
            l = allBaselines(n);
            
            lcolor = get(l,'color');
            idx = already.baseline+n;
            
            % Save the line and its current colors for the restore
            di.baselineObj(idx).baselineObject = l;
            di.baselineObj(idx).color = lcolor;
            
            if ~isempty(findprop(handle(l), 'ColorMode'))
                di.baselineObj(idx).colorMode = get(l, 'ColorMode');
            end
            
            if (~isequal(lcolor,BLACK) && ~isequal(lcolor,WHITE) && ...
                    ~isequal(lcolor,axColor))
                set(l,'color',axContrast)
            end
        end
    end

    %----------------------------------------------------------------
    function restoreBaselineObjColors
        % Restore baselineslines
        for n = length(orig.baselineObj):-1:1
            l = orig.baselineObj(n).baselineObject;
            lcolor = orig.baselineObj(n).color;
           
            set(l,'color',lcolor )
            
            if ~isempty(findprop(handle(l), 'ColorMode')) 
                set(l, 'ColorMode', orig.baselineObj(n).colorMode);
            end
        end
    end
    
    %----------------------------------------------------------------     
    function results = LocalIsProp(h, prop)
        results = zeros(size(h));
        for i = 1:length(h)
            try
                get(h(i), prop);
                results(i) = 1;
            catch
            end
        end
    end
    % -------------------------------
    function startIdx = saveRulerColors(ha)
        % save current state of ruler colors and modes 
        startIdx = 0; % assume no rulers
        already.ruler = length(di.rulerObj); 
        rulerNames = getAxisDimensionNames(ha); % names of each of rulers 
        rulerProps = {};
        rulers = matlab.graphics.GraphicsPlaceholder.empty;
        for idx = 1:length(rulerNames)
            rulerProps{end+1} = [rulerNames{idx} 'Axis'];
            thisRuler = get(ha, rulerProps{end});
            for rIdx = 1:length(thisRuler)
                rulers(end+1) = thisRuler(rIdx); 
            end
        end
        % now that we have all the rulers, store color props for each one 
        if length(rulers) 
            startIdx = already.ruler + 1; % where we will start adding enties
        end
        for n = 1:length(rulers) 
            idx = already.ruler + n;
            r = rulers(n); 
            di.rulerObj(idx).rulerObject = r; 
            di.rulerObj(idx).color = r.Color;
            if ~isempty(findprop(r, 'ColorMode'))
                di.rulerObj(idx).colorMode = r.ColorMode;
            end
        end
    end
    %----------------------------------------------------------------
    function changeRulerColors(startIdx)
        % change ruler colors and modes to one of 
        % Make sure that axes colors are one of
        %   - white
        %   - black
        %   - figColor
        %   - figContrast 
        if ~startIdx 
            return; % nothing to do
        end
        for idx = startIdx:length(di.rulerObj)
            hr = di.rulerObj(idx).rulerObject;
            currColor = di.rulerObj(idx).color;
            if (~isequal(currColor,BLACK) && ~isequal(currColor,WHITE) && ~isequal(currColor,figColor))
               hr.Color = figContrast;
            end            
        end
    end
    %----------------------------------------------------------------
    function restoreRulerColors()
        for idx = 1:length(orig.rulerObj)
            hr = orig.rulerObj(idx).rulerObject;
            origColor = orig.rulerObj(idx).color;
            hr.Color = origColor;
            if ~isempty(findprop(hr, 'ColorMode'))
                hr.ColorMode = orig.rulerObj(idx).colorMode;
            end
            
        end
    end
    %----------------------------------------------------------------
    function dims = getDimensionNames(ax)
        dims = {'X','Y','Z'};
        if ~isempty(findprop(ax,'DimensionNames')) 
            names = ax.DimensionNames;
            if iscell(names) && length(names) == 3
                dims = names;
            end
        end
    end
    % -------------------------------
    function names = getAxisDimensionNames(ha)
        % get dimension names, remove Z (3rd) dim if no Z props
        names = getDimensionNames(ha);
        hasZ = hasZProperties(ha);
        if ~hasZ
            names(3)= [];
        end
    end            
end