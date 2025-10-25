function vOut = makeUniqueVarNames(timetables, timetableNames)
    % This function is for internal use only and will change in a future release.
    % Do not use this function.

    %MAKEUNIQUEVARNAMES attempts to make unique any variable names 
    % that are duplicated across the input timetables
    %
    % T = MAKEUNIQUEVARNAMES(TIMETABLES) searches through
    % the cell array of timetables TIMETABLES to find
    % non-unique variable names and appends "_<d>" to the table's
    % variable names, where <d> is an integer incremented to make
    % the variable names unique 
    %
    % T = MAKEUNIQUEVARNAMES(TIMETABLES, TIMETABLENAMES)
    % searches through TIMETABLES to find non-unique variable
    % names and appends "_<s>" to the table's variable names, where
    % <s> is a string (based on TIMETABLENAMES)

    %   Copyright 2021 The MathWorks, Inc.

    vOut = timetables;
    if nargin < 2
        % make an empty cell array with enough space to be filled
        % in below
        timetableInputNames = cell(1,length(timetables));
    else 
        % input names were already handled for us
        timetableInputNames = timetableNames; 
    end

    % Get the var names in, and the workspace name of, each input timetable
    nTimetables = length(vOut);
    varNames = cell(1,nTimetables);
        
    nVarNames = zeros(1,nTimetables);
    for i = 1:nTimetables
        varNames{i} = vOut{i}.varDim.labels;
        nVarNames(i) = vOut{i}.varDim.length;
        if isempty(timetableInputNames{i})
            timetableInputNames{i} = num2str(i,'%-d'); % no input name, just add a unique number
        end
    end
    
    % Combine all the names, check for duplicates across timetables. The names are
    % already known to be unique within each timetable
    allVarNames = [varNames{:}];
    [uniqueVarNames,firstOccurrences] = unique(allVarNames,'stable');
    if length(uniqueVarNames) < length(allVarNames)
        % Find all the duplicated var names. Don't care what is a duplicate of what,
        % adding a suffix that's specific to each input will make them all unique
        duplicatedOccurrences = 1:length(allVarNames); duplicatedOccurrences(firstOccurrences) = [];
        repeatedNames = unique(allVarNames(duplicatedOccurrences));
        needsUniqueifying = ismember(allVarNames,repeatedNames); 
        % Uniqueify the duplicate var names by adding the timetable's workspace name as
        % a suffix
        all2which = repelem(1:nTimetables,nVarNames);
        allVarNames(needsUniqueifying) = append(allVarNames(needsUniqueifying),'_',timetableInputNames(all2which(needsUniqueifying)));
        % Don't allow the uniqueified names on either side to duplicate existing
        % names from either side
        allVarNames = matlab.lang.makeUniqueStrings(allVarNames,needsUniqueifying,namelengthmax);
        
        % Put the unique names back into the timetables
        varNames = mat2cell(allVarNames,1,nVarNames);
        for i = 1:nTimetables
            vOut{i}.varDim = vOut{i}.varDim.setLabels(varNames{i});
        end
    end
end