function setLegendScatters(obj,groupnames,cdata,mfc,mec)
%

%   Copyright 2020 The MathWorks, Inc.

% Set DisplayName, color, and alpha properties for internal scatter objects 
% used for BubbleCloud's legend

if isempty(groupnames)
    delete(obj.LegendScatters);
    obj.LegendScatters=matlab.graphics.chart.primitive.Scatter.empty;
    return
end
if isnumeric(groupnames)
    missinglabel='NaN';
else
    missinglabel='<missing>';
end

groupnames=string(groupnames);
groupnames(ismissing(groupnames))=missinglabel;

for i = 1:numel(groupnames)
    if numel(obj.LegendScatters)<i
        obj.LegendScatters(i)=...
            matlab.graphics.chart.primitive.Scatter('Parent',obj.Axes);
    end

    set(obj.LegendScatters(i),'DisplayName',groupnames(i),...
        'MarkerFaceColor',mfc,'MarkerEdgeColor',mec,...
        'CData',cdata(i,:),'MarkerFaceAlpha',obj.FaceAlpha);
end

% Remove extra scatters
unused=(numel(groupnames)+1):numel(obj.LegendScatters);
if ~isempty(unused)
    delete(obj.LegendScatters(unused));
    obj.LegendScatters(unused)=[];
end

end