function metaRows = detectMetaRows(typeIDs,detectingVarNames)
% given type ID detect meta rows

% Copyright 2020 The MathWorks, Inc.

import matlab.io.internal.TypeDetection;
if isempty(typeIDs)
    metaRows = 0;
    return
end
blanks = TypeDetection.isBlank(typeIDs);
text = TypeDetection.isText(typeIDs);

blankRows = all(blanks,2);
textRows = all(text,2);

h = height(typeIDs);
% always include varname line unless readVarNames is false
metaRowsMin = max([0,find(~(blankRows|textRows),1)-1]);

if metaRowsMin == h
    % Everything was text or blank, return only varNamesLine as Meta
    metaRows = double(detectingVarNames);
else
    typeIDs = fillBlankTypes(typeIDs,metaRowsMin,blanks);
    metaRowsMax = getMaxMetaRows(typeIDs);
    if metaRowsMax == h
        % All text
        metaRowsMin = double(detectingVarNames);
    end
    if metaRowsMax > h/2 % More rows are meta than data, this is probably wrong.
        metaRowsMax = double(detectingVarNames);
    end
    metaRows = max(metaRowsMin, metaRowsMax);
end
end
% -------------------------------------------------------------------------
function [typeIDs,domType] = fillBlankTypes(typeIDs,metaRowsMin,blanks)
% Get the dominant type of the rows that might be meta.
domType = mode(typeIDs(metaRowsMin+1:end,:),1);
domType(isnan(domType)) = matlab.io.internal.TypeDetection.getTextTypeID();
for jj = 1:width(typeIDs)
    b = blanks(:,jj);
    b(1:metaRowsMin) = false;
    typeIDs(b,jj) = domType(jj);
end
end
% -------------------------------------------------------------------------
function metaRowsMax = getMaxMetaRows(typeIDs)
% Get the per-column, meta-row. The actual meta-Rows should be the
% min value among those.
import matlab.io.internal.TypeDetection;
metaRowsMax = height(typeIDs);
text = TypeDetection.isText(typeIDs);
blanks = TypeDetection.isBlank(typeIDs);
for jj = 1:width(typeIDs)
    if ~all(blanks(:,jj)) && ~all(text(:,jj))
        metaRowsMax = min([metaRowsMax,find(~text(:,jj),1)-1]);
    end
    if metaRowsMax == 0
        break;
    end
end
end