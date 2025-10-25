function setTextStringsAndVertices(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% Set the strings and vertices of label text object, trimming strings that
% don't fit (based on length) and appending an ellipsis.

if isempty(obj.LabelStrings)
    obj.Text.VertexData=[];
    obj.Text.String={};
    obj.Text.Visible='off';
    return
end
labels=obj.LabelStrings(obj.RadiusIndex);
labelnchars=obj.LabelNChars(obj.RadiusIndex);

maxchars=obj.Marker.Size/obj.FontSize;

displaystr=strings(size(labels));

% Bubbles that can fit a little more than a character are set
% with just an ellipsis
displaystr(maxchars>=1.5 & maxchars<2)=char(8230);

% Bubbles which can't fit the whole label get an ellipsis
% appended
ind=maxchars>=2 & maxchars<labelnchars;
displaystr(ind)=labels(ind).extractBefore(fix(maxchars(ind)))+char(8230);

% Bubbles which can fit the whole label get the whole label
displaystr(maxchars>=labelnchars)=labels(maxchars>=labelnchars);

% Any remaining bubbles have an empty string (maxchars < 1.5)

obj.Text.String=cellstr(displaystr)';
obj.Text.VertexData=obj.Marker.VertexData;
obj.Text.Visible='on';
end

% LocalWords:  maxchars
