classdef FilterFigure < internal.matlab.datatoolsservices.figure.FigureController
%

%   Copyright 2018-2019 The MathWorks, Inc.

    properties
        Workspace;
        VariableName;
        VariablesChangedListener;
        Histogram;
        Stem;
        MinPatch;
        MaxPatch;
        MinLine;
        MaxLine;
        IsInt;
        datatip;        
    end
    
    properties(Access='private')
        MouseDownHitPosition;
        MouseDragging=false;
        DragLine;
        LastDragLine;
        LastRange;
        LastDragLineMsg;
        Data;
        OrigData;
        YLim;
        OrigGroupSummary;
        hCursor;
        GroupSummaryForStem;
        MouseWithinViewPort = false;
        hasCurrentSelection = false;        
        jiggleIndex = 0;
        DataTipLocator {mustBe_matlab_graphics_shape_internal_TipLocator};
    end
    
    properties(Constant)
        % tex formatted strings for datatips label and value fields
        TEX_LABELSTRING = '\color[rgb]{.15 .15 .15}\rm';
        TEX_VALUESTRING = '\color[rgb]{0 0.5 1}\bf';
        PATCH_UPDATE_BUFFER = 0.2;
    end
    
    methods
        function this = FilterFigure(workspace, varName)
            this.Workspace = workspace;
            this.VariableName = varName;
            this.VariablesChangedListener = event.listener(workspace, 'FilteredDataChanged', @(es,ed)this.updatePlot);
            this.setupPlot();
        end
        
        %Returns true if the figure should be of type stem and false for
        %histograms
        function isInt = isIntegerLike(~, var)
            if isdatetime(var)
                isInt = true;
            elseif isduration(var)
                isInt = false;
            else
                isInt = isinteger(var) & ~issparse(var);
                if ~isInt
                    if issparse(var)
                        var = full(var);
                    end
                    isInt = all(int64(var(~isnan(var))) == var(~isnan(var))) & ~all(isnan(var));
                end
            end
        end       
        
        % Sets up the plot
        function setupPlot(this)
            this.EmbeddedFigure.Color = [250/256 250/256 250/256];
            this.EmbeddedFigure.Position = [0 0 246 170];
            this.EmbeddedFigure.Units = 'pixels';
            origTable = this.Workspace.OriginalTable;
            this.OrigData = origTable.(this.VariableName);
            
            % g1788994: Inf or -Inf values in Columns need to be ignored
            % while creating the filtering visualizations
            if ~(isdatetime(this.OrigData) || isduration(this.OrigData))
                this.Data = this.OrigData(this.OrigData > -Inf & this.OrigData < Inf);
            else
                this.Data = this.OrigData;
            end
            if isempty(this.Data)
                this.Data = this.OrigData;
            end
            
            minVal = min(this.Data);
            maxVal = max(this.Data);
            this.IsInt = this.isIntegerLike(this.Data);
            if this.IsInt
                origTableNoMissing = origTable(~ismissing(origTable.(this.VariableName)),:);
                this.OrigGroupSummary = groupsummary(origTableNoMissing, this.VariableName);
                this.Stem = stem(this.EmbeddedAxes,this.OrigGroupSummary.(this.VariableName), this.OrigGroupSummary.GroupCount, 'Marker', 'none', 'LineWidth', 2);
                xMin = minVal;
                this.EmbeddedAxes.XLim = [minVal-1 maxVal+1];
            else
                if ~isnan(minVal) && ~isnan(maxVal) && ~isinf(minVal) && ~isinf(maxVal)
                    this.Histogram = histogram(this.EmbeddedAxes, this.Data, 'EdgeColor', 'blue', 'EdgeAlpha', 0.25, 'BinLimits', [minVal, maxVal]);                    
                else 
                    this.Histogram = histogram(this.EmbeddedAxes, this.Data, 'EdgeColor', 'blue', 'EdgeAlpha', 0.25);                    
                end                
                this.Histogram.BinLimitsMode = 'manual';
                xMin = this.EmbeddedAxes.XLim(1);
                if ~isduration(this.OrigData)
                    this.Histogram.DataTipTemplate.DataTipRows(2).Format = '%0.4f';
                end
            end
            
            xMax = this.EmbeddedAxes.XLim(2);
            yMax = this.EmbeddedAxes.YLim(2);
            if (isdatetime(xMin) || isdatetime(xMax)) || ...
                    (isduration(xMin) || isduration(xMax))
                r = this.EmbeddedAxes.XRuler;
                xMin = ruler2num(xMin, r);
                xMax = ruler2num(xMax, r);
            end
            this.MinPatch = patch(this.EmbeddedAxes, [xMin, xMin, xMin, xMin], [0 yMax yMax 0], 'white', 'EdgeColor', 'none', 'FaceAlpha', 0.85, 'XLimInclude', 'off', 'YLimInclude', 'off');
            this.MaxPatch = patch(this.EmbeddedAxes, [xMax, xMax, xMin, xMin], [0 yMax yMax 0], 'white', 'EdgeColor', 'none', 'FaceAlpha', 0.85, 'XLimInclude', 'off', 'YLimInclude', 'off');
            this.MinLine = internal.matlab.legacyvariableeditor.Actions.Filtering.AxesRangeHandle(this.EmbeddedAxes);
            this.MaxLine = internal.matlab.legacyvariableeditor.Actions.Filtering.AxesRangeHandle(this.EmbeddedAxes);
            this.EmbeddedAxes.XLimMode = 'manual';
            this.updatePlot();
            xMin = this.EmbeddedAxes.XLim(1);
            xMax = this.EmbeddedAxes.XLim(2);
            this.MinLine.Position = xMin;
            this.MaxLine.Position = xMax;
            
        end
        
        % Function returns the datatip for every mouse motion of the user
        function datatip = getDataTip(this, es, ed, dataHitPosition, src)
            position = ed.Position;
            hitPositionX = position(1);   
            hitPositionY = position(2);
            tipLocatorVisible = 'on';
            this.datatip.Visible = 'on'; 
            isKeyEvent = nargin >4 && strcmp(src, 'key');
            
            % Update position value to rounded off value and trimmed
            % precision for hists.
            if this.IsInt
                if isdatetime(this.OrigData)
                    r = this.EmbeddedAxes.XRuler;
                    hitPositionX = num2ruler(hitPositionX, r);
                    if nargin > 4
                        hitPositionX = num2ruler(dataHitPosition(1), r);
                        hitPositionY = this.GroupSummaryForStem.GroupCount(this.GroupSummaryForStem.Values == hitPositionX);                         
                    end
                    hitPositionX = char(hitPositionX);
                else
                    if nargin > 4
                      hitPositionX = dataHitPosition(1);                                     
                      hitPositionY = this.GroupSummaryForStem.GroupCount(this.GroupSummaryForStem.Values == round(hitPositionX));
                    end
                    hitPositionX = num2str(round(hitPositionX));
                end
                
                if isempty(hitPositionY) 
                    hitPositionY = 0;
                end                    
                xVal = [this.TEX_LABELSTRING ' X ' this.TEX_VALUESTRING  hitPositionX ];
                yVal = [this.TEX_LABELSTRING ' Y ' this.TEX_VALUESTRING num2str(hitPositionY)];
            else                 
                dataDescriptor = this.hCursor.getDataDescriptors;
                xName = 'Value';
                yName = 'Bin Edges';
                [xValue, yValue] = dataDescriptor.Value;                
                
                if isKeyEvent
                    dragLine = this.LastDragLine;
                else
                    dragLine = this.DragLine;
                end
                
                if isduration(this.OrigData)
                    % Required since the pointDataCursor.getDataDescriptors
                    % returns a char for durations
                    yValue = strsplit(regexprep(yValue, '[[,]]', ''), ' ');
                    y1 = yValue{1};
                    y2 = yValue{2};
                    if (nargin > 4)
                        origMin = min(this.OrigData);
                        origMax = max(this.OrigData);
                        r = this.EmbeddedAxes.XRuler;
                        hitPositionX = num2ruler(dataHitPosition(1), r);
                        if ((dragLine == this.MaxLine) && (hitPositionX < origMax))                   
                            y2 = char(hitPositionX);                       
                        elseif (dragLine == this.MinLine && hitPositionX > origMin)                   
                            y1 = char(hitPositionX);                       
                        end
                    end
                else
                    binEdges = regexp(yValue,'\d*[.]\d+', 'match'); 
                    y1 = binEdges{1};
                    y2 = binEdges{2};
                    % nargin > 4 for mouse drag and key events. We will be updating
                    % datatip values as hitPosition rather than nearest neighbor
                    % value.
                    if (nargin > 4)
                        origMin = min(this.OrigData);
                        origMax = max(this.OrigData);
                        hitPositionX = dataHitPosition(1);
                        if ((dragLine == this.MaxLine) && (hitPositionX < origMax))                   
                            y2 = num2str(hitPositionX,'%0.04f');                       
                        elseif (dragLine == this.MinLine && hitPositionX > origMin)                   
                            y1 = num2str(hitPositionX,'%0.04f');                       
                        end                                      
                    end
                end
                
                xVal = [this.TEX_LABELSTRING xName ' ' this.TEX_VALUESTRING mat2str(xValue)];
                yVal = [this.TEX_LABELSTRING yName ' ' this.TEX_VALUESTRING '[' y1 ' ' y2 ']'];
            end 
            
            
            if (nargin > 4)
                if ~this.IsInt
                    if (hitPositionX > origMax) || (hitPositionX < origMin)                       
                        tipLocatorVisible = 'off';                                                                          
                    end
                end
                this.DataTipLocator.Visible = tipLocatorVisible;                  
                this.DataTipLocator.Position = [dataHitPosition(1) hitPositionY 0];
                % For mouseDragging, we have updated HitPosition,
                % calculate pixelPos for this position and move datatips.
                pixelPos = matlab.graphics.chart.internal.convertDataSpaceCoordsToViewerCoords(this.EmbeddedAxes, [dataHitPosition(1);0;0]);
                this.hCursor.moveTo(pixelPos);
            end
            
            this.datatip.FontSize = 8;             
            datatip = {xVal, yVal};
            % If Key event, do not hide datatips
            if (~this.MouseWithinViewPort && ~isKeyEvent)                
                this.HideDataTips;
            end
        end
        
        % Updates the plot to either stem or histogram depending on the
        % type
        function updatePlot(this)
            this.Data = this.Workspace.(this.VariableName);
            this.YLim = this.EmbeddedAxes.YLim;
            if this.IsInt
                this.updateStem();
            else
                this.updateHistogram();
            end
        end
        
        % Updates stem plot (Both the patches and the line)
        function updateStem(this)
            % g1788994: Plots should ignore Inf and -Inf values
            if ~isdatetime(this.OrigData)
                origData = this.OrigData(this.OrigData > -Inf & this.OrigData < Inf);
            else
               origData = this.OrigData;
            end
            origMin = min(origData);
            origMax = max(origData);
            xData = this.OrigGroupSummary.(this.VariableName);
            xData = xData(~ismissing(xData));
            this.Stem.XData = xData;
            this.GroupSummaryForStem = groupsummary(this.Data(~ismissing(this.Data.Values),:), 'Values');
            yData = zeros(height(this.OrigGroupSummary),1);
            
            xMatchIndicies = find(ismember(xData,this.GroupSummaryForStem.Values));
            xMatchValues = this.OrigGroupSummary{xMatchIndicies,this.VariableName};
            yData(xMatchIndicies) = this.GroupSummaryForStem.GroupCount(this.GroupSummaryForStem.Values == xMatchValues);          
            
            
            this.Stem.YData = yData;
            this.EmbeddedAxes.YLimMode = 'auto';

            if ~isempty(this.Data) && ~all(ismissing(this.Data.Values))
                rMin = this.Data.SelectedRangeMin(1);
                rMax = this.Data.SelectedRangeMax(1);
                this.updateRanges(rMin, rMax, origMin, origMax, false);
            end
            drawnow;
        end
        
        % Updates the histogra,(Both patches and the line)
        function updateHistogram(this)
            this.Histogram.Data = this.Data.Values;

            if ~isempty(this.Data) && ~all(isnan(this.Data.Values) | isinf(this.Data.Values))
                rMin = this.Data.SelectedRangeMin(1);
                rMax = this.Data.SelectedRangeMax(1);
                % g1788994: Plots should ignore Inf and -Inf values
                origData = this.OrigData(this.OrigData > -Inf & this.OrigData < Inf);
                origMin = min(origData);
                origMax = max(origData);
                this.updateRanges(rMin, rMax, origMin, origMax, false);
            end
            drawnow;
        end
        
        % Updates ranges for the correct plot
        function updateRanges(this, rMin, rMax, origMin, origMax, isInteractive)
            if this.IsInt
                this.updateStemRange(rMin, rMax, origMin, origMax, isInteractive);
            else
                this.updateHistogramRange(rMin, rMax, origMin, origMax, isInteractive);
            end
        end
        
        % Updates the stem range by setting correct vertices for the
        % patches
        function updateStemRange(this, rMin, rMax, origMin, origMax, isInteractive)
            xMin = this.EmbeddedAxes.XLim(1);
            xMax = this.EmbeddedAxes.XLim(2);
            axesLimits = this.EmbeddedAxes.XLim;

            if isdatetime(xMin) || isdatetime(xMax)
                r = this.EmbeddedAxes.XRuler;
                xMin = ruler2num(xMin, r);
                xMax = ruler2num(xMax, r);
                rMin = ruler2num(rMin, r);
                rMax = ruler2num(rMax, r);
                origMin = ruler2num(origMin, r);
                origMax = ruler2num(origMax, r);
                axesLimits = ruler2num(axesLimits, r);
            end

            yMax = max(this.Stem.YData);
            currMinX = this.MinPatch.Vertices(3,1);
            currMaxX = this.MaxPatch.Vertices(3,1);

            if ~isInteractive
                yMax = this.EmbeddedAxes.YLim(2);
            else
                yMax = this.YLim(2);
            end

            rangeMin = max(rMin, xMin);
            rangeMax = min(rMax, xMax);

            showMinRange = origMin ~= rangeMin;
            showMaxRange = origMax ~= rangeMax;
            % For sprase values, convert to full in order to update
            % patches.
            if issparse(this.Data.Values)
               rangeMin = full(rangeMin);
               rangeMax = full(rangeMax);
               showMinRange = full(showMinRange);
               showMaxRange = full(showMaxRange);
            end
            % Do not start the patch from exactly the axes, this will hide the figure boundaries 
            delta = this.PATCH_UPDATE_BUFFER;
            this.MinPatch.Vertices = [xMin+delta,0; xMin+delta,yMax; rangeMin,yMax; rangeMin,0];
            this.MaxPatch.Vertices = [xMax-delta,0; xMax-delta,yMax; rangeMax,yMax; rangeMax,0];
            this.MinPatch.Visible = showMinRange;
            this.MaxPatch.Visible = showMaxRange;

            % Do not let minLine go beyond Right limits and maxline below Left limits
            if showMinRange
                this.MinLine.Position = min(rangeMin, axesLimits(2));
            else
                this.MinLine.Position = axesLimits(1);
            end
            if showMaxRange
                this.MaxLine.Position = max(rangeMax, axesLimits(1));
            else
                this.MaxLine.Position = axesLimits(2);
            end
        end
        
        % Updates histogram by setting the correct vertices for the
        % histogram range
        function updateHistogramRange(this, rMin, rMax, origMin, origMax, isInteractive)
            xMin = this.EmbeddedAxes.XLim(1);
            xMax = this.EmbeddedAxes.XLim(2);
            axesLimits = this.EmbeddedAxes.XLim;            
            
            if isduration(xMin) || isduration(xMax)
                r = this.EmbeddedAxes.XRuler;
                xMin = ruler2num(xMin, r);
                xMax = ruler2num(xMax, r);
                rMin = ruler2num(rMin, r);
                rMax = ruler2num(rMax, r);
                origMin = ruler2num(origMin, r);
                origMax = ruler2num(origMax, r);
                axesLimits = ruler2num(axesLimits, r);
            end
            
            yMax = max(this.Histogram.BinCounts);
            currMinX = this.MinPatch.Vertices(3,1);
            currMaxX = this.MaxPatch.Vertices(3,1);
            
            if ~isInteractive
                yMax = this.EmbeddedAxes.YLim(2);
            else
                yMax = this.YLim(2);
            end

            rangeMin = max(rMin, origMin);
            rangeMax = min(rMax, origMax);
            showMinRange = origMin ~= rangeMin;
            showMaxRange = origMax ~= rangeMax;
            snapMaxToMin = rMin >= origMax;
            snapMinToMax = rMax <= origMin;
            
            if snapMaxToMin
                rangeMax = min(rangeMin, axesLimits(2));
            end
            if snapMinToMax
                rangeMin = max(rangeMax, axesLimits(1));
            end
            % For sparse values, convert to full in order to update
            % patches.
            if issparse(this.Data.Values)
               rangeMin = full(rangeMin);
               rangeMax = full(rangeMax);
               showMinRange = full(showMinRange);
               showMaxRange = full(showMaxRange);
               snapMinToMax = full(snapMinToMax);
               snapMaxToMin = full(snapMaxToMin);
            end
            
            this.MinPatch.Vertices = [xMin,0; xMin,yMax; rangeMin,yMax; rangeMin,0];
            this.MaxPatch.Vertices = [xMax,0; xMax,yMax; rangeMax,yMax; rangeMax,0];
            this.MinPatch.Visible = showMinRange || snapMinToMax;
            this.MaxPatch.Visible = showMaxRange || snapMaxToMin;
            % Do not let minLine go beyond Right limits and maxline below Left limits
            
            if showMinRange || snapMinToMax
                this.MinLine.Position = min(rangeMin, axesLimits(2));                
            else
                this.MinLine.Position = axesLimits(1);
            end
            if showMaxRange || snapMaxToMin
                this.MaxLine.Position = max(rangeMax, axesLimits(1));                
            else
                this.MaxLine.Position = axesLimits(2);
            end
        end
        
        function handleFigureMouseUp(this, msg)
            this.handleFigureMouseUp@internal.matlab.datatoolsservices.figure.FigureController(msg);
            this.MouseDragging = false;
            this.MinLine.Selected = false;
            this.MaxLine.Selected = false;
            [mouseUpHitPosition, pixelHitPosition] = this.getHitPosition(msg);
            mouseDownHitPosition = this.MouseDownHitPosition;
            if this.IsInt
                mouseUpHitPosition = round(mouseUpHitPosition);
                mouseDownHitPosition = round(mouseDownHitPosition);
            end
            
            if ~isempty(this.DragLine)                
                this.LastDragLine = this.DragLine;
                if this.DragLine == this.MinLine
                    counterDrag = this.MaxLine;
                else
                    counterDrag = this.MinLine;
                end
                
                mouseDownHitPosition = counterDrag.Position;
                if this.IsInt
                    mouseDownHitPosition = round(mouseDownHitPosition);
                end
                this.LastDragLine.Hover = false;
                this.LastDragLine.Selected = true;                
            else                
                % When both lines snap, MaxLine will always be selected
                isOverMinLine = this.MinLine.isMouseOver(pixelHitPosition);
                isOverMaxLine = this.MaxLine.isMouseOver(pixelHitPosition);                                 
                if (this.hasCurrentSelection)                    
                    this.handleFigureBlur(msg);                    
                elseif(isOverMinLine && isOverMaxLine) || isOverMaxLine 
                    this.MaxLine.Selected = true;                    
                    this.LastDragLine = this.MaxLine;                         
                elseif isOverMinLine
                    this.MinLine.Selected = true;                    
                    this.LastDragLine = this.MinLine;                                                       
                end                 
            end
            
            % Reset hasCurrentSelection for any subsequent mouse events to update figure.
            if (this.hasCurrentSelection)
                this.hasCurrentSelection = false;
                this.jiggleIndex = 0;            
            else
                this.updateNumericRanges(mouseDownHitPosition, mouseUpHitPosition); 
            end            
            this.HideDataTips();
            this.DragLine = [];
        end
        
        function handleFigureMouseDown(this, msg)
            this.handleFigureMouseDown@internal.matlab.datatoolsservices.figure.FigureController(msg);
            this.MouseDragging = true;
            this.MouseDownHitPosition = this.getHitPosition(msg); 
            % If there was an existing selection in one of the handlebars,
            % mark hasCurrentSelection as true. This will prevent
            % consecutive mouse events from updating figure.
            isSnapped = this.MinLine.Position == this.MaxLine.Position;            
            if ((this.MinLine.Selected) || (this.MaxLine.Selected)) && ~isSnapped                
                this.hasCurrentSelection = true;                                
            end
            this.MinLine.Selected = false;
            this.MaxLine.Selected = false;
            [mouseHitPosition, pixelHitPosition] = this.getHitPosition(msg);
            % If mouse is over either of the handlebars at mousedown time, reset hasCurrentSelection flag.
            if this.MinLine.isMouseOver(pixelHitPosition)
                this.DragLine = this.MinLine;
                this.MinLine.Selected = true;
                this.LastDragLineMsg = msg;
                this.hasCurrentSelection = false;                
            elseif this.MaxLine.isMouseOver(pixelHitPosition)
                this.DragLine = this.MaxLine;
                this.MaxLine.Selected = true;
                this.LastDragLineMsg = msg;
                this.hasCurrentSelection = false;                
            elseif ~this.hasCurrentSelection           
                this.DragLine = [];
                this.LastDragLineMsg = [];
                this.MinLine.Selected = false;
                this.MaxLine.Selected = false;

                rMin = min(mouseHitPosition(1), this.MouseDownHitPosition(1));
                rMax = max(mouseHitPosition(1), this.MouseDownHitPosition(1));
                origData = this.OrigData;
                origMin = min(origData);
                origMax = max(origData);
                this.updateRanges(rMin, rMax, origMin, origMax, true);
            end
            
            if ~isempty(this.datatip)
                this.datatip.Visible = 'on';
                this.datatip.DataTipStyle = matlab.graphics.shape.internal.util.PointDataTipStyle.TipOnly;                
            end
        end
        
        function handleFigureMouseMove(this, msg)
            this.handleFigureMouseMove@internal.matlab.datatoolsservices.figure.FigureController(msg);
            [dataHitPosition, pixelHitPosition] = this.getHitPosition(msg);
            if ~isempty(this.Data)
                this.createDataTip(dataHitPosition);
                this.updateDataTipOnMouseMove(dataHitPosition, pixelHitPosition);

                % We want the tipLocator (Secondary Marker) to be turned on
                % only for dragging usecase
                if ~isempty(this.DataTipLocator)                
                    this.DataTipLocator.Visible = 'off';
                end   
                
                if this.MouseDragging                       
                    this.MinLine.Hover = false;
                    this.MaxLine.Hover = false;
                    if isempty(this.DragLine)                        
                        rMin = min(dataHitPosition(1), this.MouseDownHitPosition(1));
                        rMax = max(dataHitPosition(1), this.MouseDownHitPosition(1));
                        % Since mousemove is part of a click, maintain a jiggleIndex to keep track 
                        % of mouseEvents to ignore.
                        if (this.hasCurrentSelection)
                           if (this.jiggleIndex == 0)                            
                                this.jiggleIndex = 1; 
                           else
                               this.hasCurrentSelection = false;
                               this.jiggleIndex = 0;
                           end                           
                        elseif (rMin < this.MinLine.Position)
                            this.DragLine = this.MinLine;
                            this.MinLine.Selected = true;                            
                        elseif (rMax > this.MaxLine.Position)
                            this.DragLine = this.MaxLine;
                            this.MaxLine.Selected = true;                            
                        end
                    else                        
                        if this.DragLine == this.MinLine
                            counterDrag = this.MaxLine;
                        else
                            counterDrag = this.MinLine;
                        end
                        rMin = min(dataHitPosition(1), counterDrag.Position);
                        rMax = max(dataHitPosition(1), counterDrag.Position);
                    end
                    if isdatetime(this.OrigData) || isduration(this.OrigData)
                        r = this.EmbeddedAxes.XRuler;
                        rMin = num2ruler(rMin, r);
                        rMax = num2ruler(rMax, r);
                    end
                    origData = this.OrigData;
                    origMin = min(origData);
                    origMax = max(origData);
                    if rMax > this.EmbeddedAxes.XLim(2)
                        rMax = this.EmbeddedAxes.XLim(2);
                    end
                    if rMin < this.EmbeddedAxes.XLim(1)
                        rMin = this.EmbeddedAxes.XLim(1);
                    end
                    
                    if this.DragLine == this.MinLine & dataHitPosition(1) >= this.MaxLine.Position
                        this.DragLine = this.MaxLine;
                        this.MinLine.Selected = false;
                        this.MaxLine.Selected = true;
                    elseif this.DragLine == this.MaxLine & dataHitPosition(1) <= this.MinLine.Position
                        this.DragLine = this.MinLine;
                        this.MinLine.Selected = true;
                        this.MaxLine.Selected = false;
                    end
                   
                    if ~(this.hasCurrentSelection)                   
                        this.updateRanges(rMin, rMax, origMin, origMax, true);
                    end
                    
                else                    
                    if this.MinLine.isMouseOver(pixelHitPosition)
                        this.MinLine.Hover = true;                        
                    elseif this.MaxLine.isMouseOver(pixelHitPosition)
                        this.MaxLine.Hover = true;                        
                    else
                        this.MinLine.Hover = false;
                        this.MaxLine.Hover = false;
                    end
                end
            end
        end
        
        % Handle Figure blur will deselect any AxesRangeHandles
        function handleFigureBlur(this, msg)
            this.MinLine.Selected = false;
            this.MaxLine.Selected = false;
            this.LastDragLine = [];
            if (~isempty(this.datatip))
                this.datatip.Visible = 'off';
            end
            this.MouseDragging = false;
        end
        
        function handleFigureMouseEnter(this, msg)
            this.MouseWithinViewPort = true;           
        end
        
        function handleFigureMouseLeave(this, msg)
            this.MouseWithinViewPort = false;            
            this.HideDataTips; 
            if (isfield(msg,'eventContext') && strcmp(msg.eventContext, "destroy"))
                this.handleFigureBlur(msg);
            end
        end
        
        % Creates datatip if one does not already exist
        function createDataTip(this, dataHitPosition)            
             if (isempty(this.datatip))
                hitObj = [];
                if this.IsInt
                    hitObj = this.Stem;
                else
                    hitObj = this.Histogram;
                end
                this.hCursor = matlab.graphics.shape.internal.PointDataCursor(hitObj);                
                this.hCursor.Interpolate = 'on';

                % Create the PointDataTip            
                this.datatip = matlab.graphics.shape.internal.PointDataTip(this.hCursor, ...
                    'Visible','on',...
                    'HandleVisibility','off',...
                    'DataTipStyle',matlab.graphics.shape.internal.util.PointDataTipStyle.MarkerAndTip);
               this.datatip.Interpreter = 'tex';               
               this.datatip.UpdateFcn = @(es,ed)this.getDataTip(es,ed,dataHitPosition);
               if isempty(this.DataTipLocator)
                    this.DataTipLocator = matlab.graphics.shape.internal.PointTipLocator;                
                    this.datatip.addNode(this.DataTipLocator);                    
               end               
            end           
        end
        
        % Hide both the DataTip as well as the locator (secondary marker)
        function HideDataTips(this)
            if ~isempty(this.DataTipLocator)                
                this.DataTipLocator.Visible = 'off';
            end   
            if ~isempty(this.datatip)
                this.datatip.Visible = 'off';                                
                this.datatip.DataTipStyle = matlab.graphics.shape.internal.util.PointDataTipStyle.MarkerAndTip;                                
            end
        end
        
        % We should pass in src only if there is a drag operation and
        % should not update the tip when we go beyond the axes.
        function updateDataTipOnMouseMove(this, hitPosition, pixelPosition) 
            x = hitPosition(1,1);
            xlim = this.EmbeddedAxes.XLim;
            if isdatetime(xlim) || isduration(xlim)
                r = this.EmbeddedAxes.XRuler;
                x = num2ruler(x, r);
            end
            isVisible = (x >= xlim(1) && x <= xlim(2));
            % If mouse is on either of the dragLines, this is still a
            % dragging usecase, update datatips accordingly.
            isMouseOnDragLine = this.MinLine.isMouseOver(pixelPosition) || this.MaxLine.isMouseOver(pixelPosition);
            if (this.MouseDragging && isMouseOnDragLine && isVisible)
                this.datatip.DataTipStyle = matlab.graphics.shape.internal.util.PointDataTipStyle.TipOnly;                
                this.datatip.UpdateFcn = @(es,ed)this.getDataTip(es,ed,hitPosition, 'mouse');
            else  
                this.datatip.UpdateFcn = @(es,ed)this.getDataTip(es,ed,hitPosition); 
                this.hCursor.moveTo(pixelPosition);
            end
        end     

        function updateNumericRanges(this, pos1, pos2)
            if isempty(pos1) || isempty(pos2)
                return;
            end
            xMin = min(pos1(1), pos2(1));
            xMax = max(pos1(1), pos2(1));
            [lb, ub] = this.Workspace.getNumericFilterBounds(this.VariableName);
            this.LastRange = [lb, ub];
            if isdatetime(this.EmbeddedAxes.XLim) || isduration(this.EmbeddedAxes.XLim)
                wsVar = this.Workspace.(this.VariableName)(1,:);
                r = this.EmbeddedAxes.XRuler;
                xMin = num2ruler(xMin, r);
                xMin.Format = wsVar.SelectedRangeMin.Format;
                xMax = num2ruler(xMax, r);
                xMax.Format = wsVar.SelectedRangeMax.Format;
            end
            this.Workspace.setNumericRange(this.VariableName, xMin, xMax);
        end
        
        function handleFigureKeyUp(this, msg)
            if ~isempty(msg) && ~isempty(msg.code)
                if strcmp(msg.code, 'Escape')
                    if ~isempty(this.LastRange)
                        this.Workspace.setNumericRange(this.VariableName, this.LastRange(1), this.LastRange(2));
                        this.LastRange = [];
                    else
                        this.Workspace.clearNumericRange(this.VariableName);
                    end
                elseif strcmp(msg.code, 'Delete') || strcmp(msg.code, 'Backspace')
                    this.handleDeleteKey(msg);
                elseif strcmp(msg.code, 'ArrowLeft') || strcmp(msg.code, 'ArrowRight')
                    this.handleArrowKey(msg);
                else
                    %disp(msg);
                end
            end
            message.publish(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figurekeyup/KeyPosition'], struct());
        end
        
        function handleDeleteKey(this, ~)
            [lb, ub] = this.Workspace.getNumericFilterBounds(this.VariableName);
            if this.LastDragLine == this.MinLine
                this.Workspace.clearNumericRange(this.VariableName);
                [origlb, ~] = this.Workspace.getNumericFilterBounds(this.VariableName);
                this.updateNumericRanges(origlb, ub);
            elseif this.LastDragLine == this.MaxLine
                this.Workspace.clearNumericRange(this.VariableName);
                [~, origub] = this.Workspace.getNumericFilterBounds(this.VariableName);
                this.updateNumericRanges(lb, origub);
            end
        end

        function handleArrowKey(this, msg)
            [lb, ub] = this.Workspace.getNumericFilterBounds(this.VariableName);
            if strcmp(msg.code, 'ArrowLeft')
                step = -1*this.getIncrementStep(msg.shiftKey);
            else
                step = this.getIncrementStep(msg.shiftKey);
            end
            % When minline and maxline coincide, ensure that both lines
            % move together.
            minLinePos = this.MinLine.Position;
            maxLinePos = this.MaxLine.Position;            
            if isequal(minLinePos, maxLinePos) && ~isempty(this.LastDragLine) 
                this.MaxLine.Selected = true;
                this.updateNumericRanges(lb+step, ub+step);
                this.renderKeyRange([lb+step, ub+step], lb+step);
            elseif (this.MinLine.Selected && this.LastDragLine == this.MinLine)               
                this.updateNumericRanges(lb+step, ub);                
                % Switch which line we're adjusting if we cross over
                if step > 0 && (lb+step >= ub)
                    this.LastDragLine = this.MaxLine;
                    this.MaxLine.Selected = true;
                    this.MinLine.Selected = false;
                end                
                % Update datatips after dragLine is updated
                this.renderKeyRange([lb+step, ub], lb+step);
            elseif (this.MaxLine.Selected && this.LastDragLine == this.MaxLine)                
                this.updateNumericRanges(lb, ub+step);                
                % Switch which line we're adjusting if we cross over
                if step < 0 && (ub+step < lb)
                    this.LastDragLine = this.MinLine;
                    this.MinLine.Selected = true;
                    this.MaxLine.Selected = false;
                end   
                % Update datatips after dragLine is updated
                this.renderKeyRange([lb, ub+step], ub+step);
            end
        end
        
        % Update tips on every key movement
        function renderKeyRange(this, position, xPos)                            
            if ~isempty(position) && ~isempty(this.LastDragLine)
                this.createDataTip(position);                
                positionToUpdate = [];
                if this.LastDragLine == this.MinLine
                    positionToUpdate = [this.MinLine.Position position(2) 0];
                end
                if this.LastDragLine == this.MaxLine
                    positionToUpdate = [this.MaxLine.Position position(2) 0];
                end
                % Move datatip location for key movements as well.                
                pixelPos = matlab.graphics.chart.internal.convertDataSpaceCoordsToViewerCoords(this.EmbeddedAxes, [xPos;0;0]);                  
                this.hCursor.moveTo([pixelPos(1) pixelPos(2)]);
                % We will move the marker along with the lines, so set the
                % marker to be tip only for key movements.
                this.datatip.DataTipStyle = matlab.graphics.shape.internal.util.PointDataTipStyle.TipOnly;
                this.datatip.UpdateFcn = @(es,ed)this.getDataTip(es,ed, positionToUpdate, 'key');                    
            end
        end
        
        function step = getIncrementStep(this, accelerate)
            if this.IsInt
                if accelerate
                    step = round((this.EmbeddedAxes.XLim(2)-this.EmbeddedAxes.XLim(1))/10);
                else
                    step = 1;
                end
            else
                if accelerate
                    step = (this.EmbeddedAxes.XLim(2)-this.EmbeddedAxes.XLim(1))/10;
                else
                    step = (this.EmbeddedAxes.XLim(2)-this.EmbeddedAxes.XLim(1))/100;
                end
            end
        end
        
        function clientEventData = getClientMouseEventData(this, msg)
            clientEventData = this.getClientMouseEventData@internal.matlab.datatoolsservices.figure.FigureController(msg);
            hitPosition = clientEventData.hitPosition;
            mouseDownHitPosition = this.MouseDownHitPosition;
            [dataHitPosition, pixelHitPosition] = this.getHitPosition(msg);
            if this.IsInt
                hitPosition = round(hitPosition);
                mouseDownHitPosition = round(mouseDownHitPosition);
                dataHitPosition(1) = round(dataHitPosition(1));
            end
            clientEventData.augmentedHitPosition = hitPosition;
            clientEventData.isDragEvent = this.MouseDragging;            
            clientEventData.mouseDownHitPosition = this.MouseDownHitPosition;
            clientEventData.augmentedMouseDownHitPosition = mouseDownHitPosition;
            clientEventData.isMinDrag = this.DragLine==this.MinLine;
            clientEventData.isMaxDrag = this.DragLine==this.MaxLine;
            clientEventData.isOverMaxLine = this.MaxLine.isMouseOver(pixelHitPosition);
            clientEventData.isOverMinLine = this.MinLine.isMouseOver(pixelHitPosition);
            clientEventData.xPosition = dataHitPosition(1);
            clientEventData.yPosition = round(dataHitPosition(2));
        end
                
        function figH = getFigureHandle(this)
            figH = this.EmbeddedFigure;
        end
        
        % gets the figure data
        function figD = getFigureData(this)
            figD = struct('figID', this.EmbeddedFigureID, 'varName', this.VariableName);
        end
        
        function openBrowser(this)
            this.getFigureHandle; % Make sure figure has been created

            url = sprintf('/toolbox/matlab/datatools/datatoolsservices/js/datatoolsservices/src/Data/EmbeddedFiguresTest.html?canvasID=%s',this.EmbeddedFigureID);
            nurl = connector.getUrl(url);
            web(nurl, '-browser');
        end
        
        function delete(this)            
            if ~isempty(this.VariablesChangedListener)
                delete(this.VariablesChangedListener);
            end
            if ~isempty(this.datatip)
                delete(this.datatip);
            end
            if ~isempty(this.DataTipLocator)
                delete(this.DataTipLocator);
            end
            this.VariablesChangedListener = [];               
        end
    end
end

function mustBe_matlab_graphics_shape_internal_TipLocator(input)
    if ~isa(input, 'matlab.graphics.shape.internal.TipLocator') && ~isempty(input)
        throwAsCaller(MException('MATLAB:type:PropSetClsMismatch','%s',message('MATLAB:type:PropSetClsMismatch','matlab.graphics.shape.internal.TipLocator').getString));
    end
end
