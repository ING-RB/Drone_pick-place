function serializedStruct = copyAxesRelationships(serializedStruct, obj)
% Capture axes relationships

% Copyright 2012-2024 The MathWorks, Inc.

parentax = ancestor(obj, 'matlab.graphics.axis.AbstractAxes');

if isempty(parentax)
    return
end

if strcmp(obj.Type,'text') && strcmp(obj.PositionMode,'auto')
    if get(parentax,'Title') == obj
        serializedStruct.specialChild = 'Title';
    elseif ~isa(parentax,'matlab.graphics.axis.PolarAxes')
        if get(parentax,'XLabel') == obj
            serializedStruct.specialChild = 'XLabel';
        elseif get(parentax,'YLabel') == obj
            serializedStruct.specialChild = 'YLabel';
        elseif get(parentax,'ZLabel') == obj
            serializedStruct.specialChild = 'ZLabel';
        end
    end
end

%if the axes is not Cartesian - copy the constructor so that the object
%will pasted to the correct same axes
if ~isa(parentax,'matlab.graphics.axis.Axes')
    serializedStruct.specialParent = class(parentax);
end

end
