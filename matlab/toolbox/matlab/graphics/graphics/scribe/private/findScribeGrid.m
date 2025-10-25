function SG = findScribeGrid(fig)
% Given a figure, return the scribe grid associated with it.

%   Copyright 2010-2020 The MathWorks, Inc.

scribeunder = matlab.graphics.annotation.internal.getDefaultCamera(fig,'underlay');
scribeunder.Serializable = 'on';
SG = matlab.graphics.annotation.internal.getScribeGrid(scribeunder);
