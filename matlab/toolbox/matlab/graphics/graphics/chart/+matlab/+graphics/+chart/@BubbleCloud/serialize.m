function data=serialize(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% This method is called during serialization. It stores data/table properties
% based on whether they are empty, and other properties iff they are
% manual.

% Serialization and deserialization both use the public interface (i.e. no
% _I properties) so there is no need to serialize modes.

% Data/Variable properties are checked individually rather than
% using UsingTableForData to allow a future where table/vector
% workflows can be mixed.

if strcmp(obj.SourceTableMode,'manual')
    data.SourceTable=obj.SourceTable;
end
if ~isempty(obj.SizeVariable)
    data.SizeVariable=obj.SizeVariable;
elseif ~isempty(obj.SizeData)
    data.SizeData=obj.SizeData;
end
if ~isempty(obj.LabelVariable)
    data.LabelVariable=obj.LabelVariable;
elseif ~isempty(obj.LabelData)
    data.LabelData=obj.LabelData;
end
if ~isempty(obj.GroupVariable)
    data.GroupVariable=obj.GroupVariable;
elseif ~isempty(obj.GroupData)
    data.GroupData=obj.GroupData;
end
if strcmp(obj.FontColorMode,'manual')
    data.FontColor = obj.FontColor;
end
if strcmp(obj.FontNameMode,'manual')
    data.FontName = obj.FontName;
end
if strcmp(obj.FontSizeMode,'manual')
    data.FontSize = obj.FontSize;
end
if strcmp(obj.FaceColorMode,'manual')
    data.FaceColor = obj.FaceColor;
end
if strcmp(obj.EdgeColorMode,'manual')
    data.EdgeColor = obj.EdgeColor;
end
if strcmp(obj.ColorOrderMode,'manual')
    data.ColorOrder = obj.ColorOrder;
end
if strcmp(obj.FaceAlphaMode,'manual')
    data.FaceAlpha = obj.FaceAlpha;
end
if strcmp(obj.TitleMode,'manual')
    data.Title = obj.Title;
end
if strcmp(obj.LegendVisibleMode,'manual')
    data.LegendVisible = obj.LegendVisible;
end
if strcmp(obj.MaxDisplayBubblesMode,'manual')
    data.MaxDisplayBubbles = obj.MaxDisplayBubbles;
end
if strcmp(obj.LegendTitleMode,'manual')
    data.LegendTitle = obj.LegendTitle;
end

% Store the MATLAB version and date.
[v,d] = version;
data.Version = v;
data.Date = d;

end