function results = detectTypes(typeIDs,options)
% get the types and meta-data rows from typeIDs

% Copyright 2016-2020 The MathWorks, Inc.

import matlab.io.internal.TypeDetection;
emptyType = TypeDetection.getEmptyType(options.EmptyColumnType);
% Find the trailing columns which do not contain data.
results.EmptyTrailing = find(~all(TypeDetection.isEmpty(typeIDs),1),1,'last')+1;

blanks = TypeDetection.isBlank(typeIDs);
text = TypeDetection.isText(typeIDs);
blankColumns = all(blanks,1);

if any(blankColumns)
    % Fill all blank types as empty type to prevent them from causing
    % confusion later.
    typeIDs(:,blankColumns) = emptyType;
end

% Convert to double to add NaNs to take advantage of MODE ignoring NaN
typeIDs = double(typeIDs);
typeIDs(blanks) = NaN;

replaceFirstRow = options.DetectVariableNames && ~isempty(typeIDs) && all(blanks(1,:)|text(1,:));
if replaceFirstRow
    % Treat blanks as Text in the first row
    typeIDsOriginalFirstRow = typeIDs(1,:);
    typeIDs(1,blanks(1,:)) = TypeDetection.getTextTypeID();
end

results.MetaRows = 0;
if options.DetectMetaRows
    results.MetaRows = matlab.io.internal.detectMetaRows(typeIDs,options.DetectVariableNames);
    if options.DetectVariableNames
        options.ReadVariableNames = results.MetaRows > 0;
    else
        results.MetaRows = max([options.ReadVariableNames,results.MetaRows]);
    end
else
    results.MetaRows = options.MetaRows;
end

if replaceFirstRow && results.MetaRows == 0 && ~isempty(typeIDs)
    typeIDs(1,:) = double(typeIDsOriginalFirstRow);
end

% Now that we know the MetaRows, we can tell the correct types
if height(typeIDs) == 1
    if results.MetaRows == 0
        dominantType = typeIDs;
    else
        dominantType = repmat(emptyType,1,width(typeIDs));
    end  
else
    % Compute the dominant type of all rows excluding metaRows
    dominantType = mode(typeIDs((results.MetaRows+1):end,:),1);
end

dominantType(isnan(dominantType)) = emptyType;
 
if all(TypeDetection.isText(dominantType)) && (results.MetaRows > 0)
    % If all columns had String dominantType, the only metadata that
    % can be detected are variable names
    results.MetaRows = min(size(typeIDs,1),double(options.ReadVariableNames));
end
results.Types = TypeDetection.getTypeName(dominantType);
end
