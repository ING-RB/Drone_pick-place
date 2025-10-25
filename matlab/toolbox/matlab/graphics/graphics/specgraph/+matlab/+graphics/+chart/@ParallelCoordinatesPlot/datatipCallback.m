function datatipTxt = datatipCallback(~,evt,pc)
% datatip callback for parallelplot. evt is a line that has been clicked
% on, pc is the ParallelCoordinatesPlot object

%   Copyright 2018-2024 The MathWorks, Inc.

% Get stored app data
target = get(evt,'Target');
ind = get(evt,'DataIndex');
grp = getappdata(target,'grp');

% Find the actual row number in the data
ncols = pc.NumColumns;
indByGroup = ceil(ind/(ncols+1));
ind = mod(ind,ncols+1);
mbrs = find(pc.GroupIndex == grp);
gind = mbrs(indByGroup);
dataind = pc.CoordinateData(ind);

% Get group names if data is grouped
if ~isempty(pc.GroupNames)
    gname = pc.GroupNames{grp};
else
    gname = [];
end

% Format for datatips
[texLabelFormat, texValueFormat] = getTexLabelAndValueFormat(target);

% Get strings from message catalogue
rowStr = getString(message('MATLAB:Chart:DatatipRow'));
groupStr = getString(message('MATLAB:Chart:DatatipGroup'));

% Get variable names for each column of data
if pc.UsingTableForData
    % Generate datatip string for the coordinate variable
    coordVarname = pc.VariableName{ind};
    
    tiplabel = coordVarname; % text string to use for data tip label
    
    % if there are (non-empty) custom ticks, replace the tipname with the tick label string
    if strcmp(pc.CoordinateTickLabelsMode,'manual')
        ticklabelmatch = pc.Axes.XAxis.TickLabels{ind};
        if ~isempty(ticklabelmatch)
            tiplabel = ticklabelmatch;
        end
    end
    
    datatipTxt = [texLabelFormat,tiplabel,': ',texValueFormat,char(string(pc.SourceTable.(coordVarname)(gind,:)))];
    varnames = pc.getDataTipVariables();
else
    varnames = string(pc.Axes.XAxis.TickLabels);
    var = [texLabelFormat,varnames{ind},': ',texValueFormat,num2str(pc.Data(gind,dataind))];
    % Generate text for individual observation.
    datatipTxt = {
        var...
        [texLabelFormat,rowStr,': ',texValueFormat,num2str(gind)]...
        };
    if ~isempty(gname)
        datatipTxt{end+1} = [texLabelFormat,groupStr,': ',texValueFormat,gname];
    end
end

% Generate text for all coordinates (variables)
datatip_var_txt = cell(length(varnames),1);
for i=1:length(varnames)
    
    tiplabel = varnames{i}; % text string to use for data tip label
    
    % Coordinate is numeric
    if pc.UsingTableForData
        % We use first dimension names of the table instead of always using
        % hard-coded 'Row' string. The first dimension name of the table is
        % usually 'Row' unless user customizes it. This was done to avoid
        % conflicting table column name 'Row' which user can possbily do
        % when customizing the first dimension name of the table.
        srcTble = pc.SourceTable;
        if strcmp(srcTble.Properties.DimensionNames{1},varnames{i}) && isa(srcTble,'table') && ...
                isempty(srcTble.Properties.RowNames)
            % If the RowNames is empty, we show table row number by
            % default in the data tip
            tipVal = gind;
        elseif strcmp(varnames{i},getString(message('MATLAB:Chart:DatatipGroup'))) && ...
                ~isempty(pc.GroupVariableName) && i<=2
            tipVal = srcTble.(pc.GroupVariableName)(gind,:);                 
        else
            tipVal = srcTble.(varnames{i})(gind,:);
            
            % if there are (non-empty) custom ticks, replace the tipname with the tick label string
            if strcmp(pc.CoordinateTickLabelsMode,'manual') 
                if isempty(pc.GroupVariableName) && i > 1
                    % If there's no grouping, varnames starts with 'Row',
                    % followed by the variable names.
                    ticklabelmatch = pc.Axes.XAxis.TickLabels{i-1};
                elseif ~isempty(pc.GroupVariableName) && i > 2
                    % Grouping exists, pc.getDataTipVariables() includes
                    % 'Row and 'Group' as first two elements
                    ticklabelmatch = pc.Axes.XAxis.TickLabels{i-2};
                end
                if ~isempty(ticklabelmatch)
                    tiplabel = ticklabelmatch;
                end
            end
        end
        tipVal = matlab.graphics.datatip.internal.formatDataTipValue(tipVal,'auto');
    else
        tipVal = num2str(pc.Data(gind,pc.CoordinateData(i)));
    end
    datatip_var_txt{i} = [texLabelFormat,tiplabel,': ',texValueFormat,tipVal];
end
datatipTxt = [datatipTxt(:)' datatip_var_txt(:)'];
end

function [texLabelFormat, texValueFormat] = getTexLabelAndValueFormat(target)
    themedContainer = ancestor(target,'matlab.graphics.mixin.ThemeContainer');
    currentTheme = themedContainer.Theme;
    if isempty(currentTheme)
        % Assume light theme if theme is empty.
        currentTheme = matlab.graphics.internal.themes.lightTheme;
    end

    labelColorRGB = matlab.graphics.internal.themes.getAttributeValue(currentTheme,'--mw-color-primary'); 
    labelColorStr = mat2str(labelColorRGB);
    texLabelFormat = sprintf('\\color[rgb]{%s}\\rm',labelColorStr(2:end-1));

    valueColorRGB = matlab.graphics.internal.themes.getAttributeValue(currentTheme,'--mw-color-list-primary'); 
    valueColorStr = mat2str(valueColorRGB);
    texValueFormat = sprintf('\\color[rgb]{%s}\\bf',valueColorStr(2:end-1));
end
