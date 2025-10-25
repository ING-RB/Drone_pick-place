function [metadataCode,warnmsg] = variableEditorMetadataCode(this,varName,index,propertyName,propertyString)
% This function is for internal use only and will change in a
% future release.  Do not use this function.

% Generate MATLAB command to modify table metadata at positions defined
% by index input.

%   Copyright 2011-2024 The MathWorks, Inc.

warnmsg = '';
if matches("VariableNames",propertyName,"IgnoreCase",true)
    % Validation
    matlab.internal.tabular.validateVariableNameLength({propertyString},'MATLAB:table:VariableNameLengthMax');
    
    % Check for duplicates (exclude the current column)
    currLabels = this.varDim.labels;
    if matches(currLabels{index}, propertyString)
        metadataCode = '';
    else
        currLabels(index) = [];
        if any(matches(currLabels,propertyString))
            error(message('MATLAB:table:DuplicateVarNames',propertyString));
        end
        metadataCode = [matlab.internal.tabular.generateVariableNameAssignmentString(this, index, propertyString, varName) ';'];
    end
elseif any(matches(propertyName,["VariableUnits", "VariableDescriptions"],"IgnoreCase",true))
    if ~isvarname(this.varDim.labels{index})
        metadataCode = [varName '.Properties.' propertyName '{' num2str(index) '} = ''' fixquote(propertyString) ''';'];
    else
        metadataCode = [varName '.Properties.' propertyName '{''' this.varDim.labels{index} '''} = ''' fixquote(propertyString) ''';'];
    end
elseif matches("Format", propertyName,"IgnoreCase",true)
    % Set the Format for any datetime columns
    [colNames, varIndices, colClasses] = variableEditorColumnNames(this);
    if isdatetime(this.rowDim.labels) || isduration(this.rowDim.labels)
        % colNames, varIndices and colClasses include the rownames, if
        % they are datetimes or duration.  These aren't needed for the
        % metadata function.
        colNames(1) = [];
        colClasses(1) = [];
        varIndices(end) = [];
    end
    
    idx = (colClasses == "datetime");
    metadataCode = '';
    if any(idx)
        for col=varIndices(idx)
            d = this.data{col};
            if d.TimeZone ~= "UTCLeapSeconds"
                if ~isvarname(colNames{col})
                    metadataCode =  [metadataCode varName '.(' num2str(col) ').Format = ''' propertyString '''; ']; %#ok<AGROW>
                else
                    metadataCode =  [metadataCode varName '.' colNames{col} '.Format = ''' propertyString '''; ']; %#ok<AGROW>
                end
            end
        end
    end
    % Use the format for the row labels as well, if they are times.
    if isdatetime(this.rowDim.labels)
        % Only one specific form is currently allowed for UTCLeapSeconds
        if this.rowDim.labels.TimeZone ~= "UTCLeapSeconds"
            metadataCode =  [metadataCode '; ' varName '.Properties.RowTimes.Format = ''' propertyString '''; '];
        end
    elseif isduration(this.rowDim.labels)
        metadataCode =  [metadataCode '; ' varName '.Properties.RowTimes.Format = ''' propertyString '''; '];
    end
end
end