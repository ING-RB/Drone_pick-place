function allContent = findAllSubcontent(content, getSubContentFcn)
% Function to find all subcontent recursively contained in content.
% Function getSubContentFcn(content) should return the subcontent directly
% contained in content.

%   Copyright 2022 The MathWorks, Inc.

import matlab.unittest.internal.findAllSubcontent
allContent = content;
for idx = 1:numel(content)
    thisContent = content{idx};
    subContent = findAllSubcontent(getSubContentFcn(thisContent), getSubContentFcn);
    allContent = [allContent, subContent]; %#ok<AGROW>
end
end
