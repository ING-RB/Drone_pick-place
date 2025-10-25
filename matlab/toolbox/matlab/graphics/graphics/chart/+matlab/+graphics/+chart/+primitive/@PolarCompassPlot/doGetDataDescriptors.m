function descriptors = doGetDataDescriptors(obj,index,~)
%

%  Copyright 2024 The MathWorks, Inc.

repPos = obj.getReportedPosition(index, 0);
loc = repPos.getLocation(obj);
descriptors = matlab.graphics.chart.interaction.dataannotatable.internal.createPositionDescriptors(obj,loc);
end