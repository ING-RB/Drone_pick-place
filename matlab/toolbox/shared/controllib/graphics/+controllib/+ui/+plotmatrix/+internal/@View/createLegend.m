function createLegend(hObj)
%

%   Copyright 2015-2020 The MathWorks, Inc.

if hObj.Legend
    if hObj.ShowView
        BackAx = getAxes(hObj.Axes,'Background');
        set(BackAx,'NextPlot','add');
        hh = findobj(BackAx,'Tag','LegendLines_GV');
        hh.delete; 
        hh = findobj(BackAx,'Tag','LegendLines_Empty');
        hh.delete;
        hh = findobj(BackAx,'Tag','LegendLines_Color');
        hh.delete;
        hh = findobj(BackAx,'Tag','LegendLines_Marker');
        hh.delete;
        hh = findobj(BackAx,'Tag','LegendLines_MarkerSize');
        hh.delete;
        hh = findobj(BackAx,'Tag','LegendLines_LineStyle');
        hh.delete;
        LegendString = cell(0,1);
        LegendTitleIdx = [];
        for ct =1:numel(hObj.GroupingVariableStyle)
            % Empty line for titles
            [b,~] = ismember(hObj.GroupingVariableStyle{ct}, {'XAxis','YAxis'});
            if ~b
                hh = plot(NaN,NaN,'LineStyle','none','Marker','none','Tag','LegendLines_GV','Parent',BackAx(1));
                LegendString = [LegendString; sprintf('%s', hObj.GroupingVariableLabels{ct})];
                LegendTitleIdx = [LegendTitleIdx; numel(LegendString)];
            end
            if strcmpi(hObj.GroupingVariableStyle{ct},'Color')
                for grpct = 1:size(hObj.GroupColor,1)
                    hh = plot(NaN,NaN,'Color',hObj.GroupColor(grpct,:),...
                        'Marker','.', 'LineStyle','none','Tag','LegendLines_Color','Parent',BackAx(1));
                    LegendString = [LegendString; {sprintf('%s',hObj.GroupLabels{ct}{grpct})}];
                end
            elseif strcmpi(hObj.GroupingVariableStyle{ct},'MarkerType')
                for grpct = 1:size(hObj.GroupMarker,2)
                    hh = plot(NaN,NaN,'Color',BackAx(1).ColorOrder(1,:),'LineStyle','none','Marker',hObj.GroupMarker{grpct},'Tag','LegendLines_Marker','Parent',BackAx(1));
                    LegendString = [LegendString; {sprintf('%s',hObj.GroupLabels{ct}{grpct})}];
                end
            elseif strcmpi(hObj.GroupingVariableStyle{ct},'MarkerSize')
                for grpct = 1:size(hObj.GroupMarkerSize,2)
                    hh = plot(NaN,NaN,'Color',BackAx(1).ColorOrder(1,:),'LineStyle','none','Marker','.','MarkerSize',hObj.GroupMarkerSize(grpct),'Tag','LegendLines_MarkerSize','Parent',BackAx(1));
                    LegendString = [LegendString; {sprintf('%s',hObj.GroupLabels{ct}{grpct})}];
                end
            elseif strcmpi(hObj.GroupingVariableStyle{ct},'LineStyle')
                for grpct = 1:size(hObj.GroupLineStyle,2)
                    hh = plot(NaN,NaN,'Color',BackAx(1).ColorOrder(1,:),'LineStyle',hObj.GroupLineStyle{grpct},'Tag','LegendLines_LineStyle','Parent',BackAx(1));
                    LegendString = [LegendString; {sprintf('%s',hObj.GroupLabels{ct}{grpct})}];
                end
            end
            if numel(hObj.GroupingVariableStyle)>1 && ct<numel(hObj.GroupingVariableStyle) && ~b
                % Empty line to separate grouping variables
                hh = plot(NaN,NaN,'LineStyle','none','Marker','none','Tag','LegendLines_Empty','Parent',BackAx(1));
                LegendString = [LegendString; {' '}];
            end
            
        end
        
        if ~isempty(LegendString)
            hObj.Legend_I = legend(BackAx(1),LegendString, 'Interpreter', 'none','Location','northeastoutside');
            
            % The drawnow here ensures that the legend and the background axes
            % resize is completed before we set the 'Position' property of the View
            % from BackgroundAxes.
            drawnow;
            hObj.Position = BackAx(1).Position;
            % Setting the position of the View to re-layout the axes based on
            % background axis size. The background axis size might change because
            % of legend positioning.
            set(BackAx,'NextPlot','replace');
        end
    end
else
    delete(hObj.Legend_I);
    if ~isempty(hObj.Axes)
        BackAx = getAxes(hObj.Axes,'Background');
        
        % At this point, we make the axes position  [0.1300    0.1100    0.7750
        % 0.8150] (That is, the width of the axes is 77.5% the width of the
        % parent container, which is the HG default)
        if ~isempty(BackAx)
            hObj.Position(3) = .775;
        end
    end
end

end
