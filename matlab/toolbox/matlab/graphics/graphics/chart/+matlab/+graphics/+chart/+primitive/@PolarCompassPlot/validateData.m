function validateData(dataMap)
arguments
    dataMap (1,1) matlab.graphics.data.DataMap
end

channels = string(fieldnames(dataMap.Map));
keep = ismember(channels, ["Theta", "R"]);
channels = channels(keep);
for c = channels'
    subscript = dataMap.Map.(c);
    data = dataMap.DataSource.getData(subscript);
    for d = 1:numel(data)
        matlab.graphics.chart.primitive.PolarCompassPlot.validateDataPropertyValue(c, data{d});
    end
end
end