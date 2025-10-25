% function is used for formatting data for rendering in the variable editor.
% This formatted data can be used by types like structure arrays and cell arrays
% where each cell entry can be a different data type

% Copyright 2015-2024 The MathWorks, Inc.

function [renderedData, renderedDims, metaData] = formatDataBlockForMixedView(startRow,endRow,startColumn,endColumn,currentData, currentFormat, NVPairs)
    arguments
        startRow
        endRow
        startColumn
        endColumn
        currentData
        currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
        NVPairs.ShowCompactDisplay (1,1) logical = true;
        NVPairs.VarName = ''; % Underlying variable name of the currentData;
    end

    import internal.matlab.datatoolsservices.FormatDataUtils;
    sRow = max(1,startRow);
    eRow = min(size(currentData,1),endRow);
    sCol = max(startColumn,1);
    eCol = min(endColumn,size(currentData,2));
    metaData = false(eRow-sRow+1, eCol-sCol+1);
    renderedData = cell(eRow-sRow+1, eCol-sCol+1);
    displayConfig = [];
    % Loop through the cells
    if ~isempty(currentData)
        colCount = 1;
        for column=sCol:eCol
            rowCount = 1;
            for row=sRow:eRow
                try
                    currentVal = currentData{row,column};
                    currentClass = char(class(currentVal));
                    isNumericClass = false;
                    try
                        isNumericClass = isnumeric(currentVal);
                    catch
                    end

                    % empty data 0x0 struct data should be rendered as '0x0
                    % struct'
                    if isNumericClass && FormatDataUtils.isVarEmpty(currentVal) && ~isa(currentVal, 'tall')
                        renderedData{rowCount,colCount} = '[ ]';
                        metaData(rowCount,colCount) = false;
                    elseif isa(currentVal, 'distributed') || isa(currentVal, 'codistributed') ...
                            || isa(currentVal, 'gpuArray') || isa(currentVal, 'dlarray')
                        % Check for these types before others, because they can
                        % return true to some of the other checks (like
                        % isnumeric). Use classUnderlying fn to determine the
                        % underlying class of these types, if it is available.
                        renderedData{rowCount, colCount} = FormatDataUtils.getClassUnderlyingTypeSummary(currentVal);
                        metaData(rowCount,colCount) = true;
                    elseif isa(currentVal, "matlab.mixin.CustomCompactDisplayProvider") && NVPairs.ShowCompactDisplay
                        if isempty(displayConfig)
                            displayConfig = matlab.display.DisplayConfiguration();
                        end
                        [formattedVal, isDimsAndClassName] = internal.matlab.datatoolsservices.FormatDataUtils.getCompactDisplayForData(currentVal, displayConfig);
                        renderedData{rowCount, colCount} = formattedVal;
                        metaData(rowCount,colCount) = isDimsAndClassName;
                    elseif isa(currentVal, 'timeseries')
                        renderedData{rowCount,colCount} = strtrim([num2str(size(currentVal,1)) FormatDataUtils.TIMES_SYMBOL num2str(size(currentVal,2)) ...
                            ' ' class(get(currentVal, 'Data')) ' ' char(FormatDataUtils.getClassString(currentVal))]);
                        metaData(rowCount,colCount) = true;

                        % char data
                    elseif ischar(currentVal) && ...
                            size(currentVal, 1) <= 1 && ...
                            size(currentVal, 2) < internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH
                        cellVal = FormatDataUtils.getCharCellVal(currentVal);
                        metaData(rowCount,colCount) = false;
                        renderedData{rowCount,colCount} = ['''' cellVal ''''];
                        % String data
                    elseif FormatDataUtils.checkIsString(currentVal) && ...
                            isscalar(currentVal) && ...
                            (ismissing(currentVal) || strlength(currentVal) < FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH)
                        cellVal = currentData{row,column};
                        if(ismissing(cellVal))
                            cellVal = strtrim(evalc('disp(cellVal)'));
                        else
                            cellVal = char(strrep(cellVal, char(0), ' '));
                        end
                        if ~strcmp(currentData{row,column},'""')
                            cellVal = regexprep(cellVal,'(^"|"$)','');
                        end
                        metaData(rowCount,colCount) = false;
                        % If the scalar string is <missing>, set metaData to
                        % true
                        if ismissing(currentVal)
                            metaData(rowCount,colCount) = true;
                            renderedData{rowCount,colCount} = cellVal;
                        else
                            renderedData{rowCount,colCount} = ['"' cellVal '"'];
                        end
                    elseif islogical(currentVal)
                        if isscalar(currentVal)
                            cellVal = strtrim(evalc('disp(currentVal)'));
                        else
                            cellVal = [FormatDataUtils.getSizeString(currentVal) ' ' FormatDataUtils.getClassString(currentVal)];
                            metaData(rowCount,colCount) = true;
                        end
                        renderedData{rowCount,colCount} = cellVal;

                        % numeric data
                    elseif isNumericClass && ~issparse(currentVal)
                        isNumericSummary = false;
                        if FormatDataUtils.isSummaryValue(currentVal)
                            isNumericSummary = true;
                        else
                            metaData(rowCount,colCount) = false;
                            % For numeric objects, convert to numeric before
                            % formatting (g2044078)
                            try
                                currentVal = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(currentVal);

                                % case where c{1} = 1;2;3;4;5
                                if ~isscalar(currentVal)
                                    cellVal = FormatDataUtils.getNumericNonScalarValueDisplay(currentVal, currentFormat);
                                else
                                    cellVal = char(matlab.internal.display.numericDisplay(currentVal, 'Format', currentFormat));
                                end
                            catch
                                % Some objects lie about being numeric, treat them as summaries
                                isNumericSummary = true;
                            end
                        end

                        if isNumericSummary
                            val = currentVal;
                            cellVal = [FormatDataUtils.getSizeString(val) ' ' FormatDataUtils.getClassString(val)];
                            metaData(rowCount,colCount) = true;
                        end
                        renderedData{rowCount,colCount} = cellVal;

                    elseif isa(currentVal, 'tall')
                        % Special handling for tall variables.

                        %-------------------------------------------------------
                        % NOTE - checking for tall must happen before other
                        % steps (like calling isscalar), because this can result
                        % in the tall variable being unintentionally gathered.
                        %-------------------------------------------------------

                        renderedData{rowCount, colCount} = FormatDataUtils.getTallCellVal(currentVal);
                        metaData(rowCount, colCount) = true;

                    elseif isscalar(currentVal) && FormatDataUtils.isExpandableScalar(currentClass)
                        % Note: Call cellstr so that missing values in
                        % cat/datetime are preserved as is.
                        renderedData{rowCount,colCount} = string(cellstr(currentVal));
                        metaData(rowCount,colCount) = ismissing(currentVal);
                        % if it is a value class (not a handle class) whose
                        % summary value has to be displayed in the variable
                        % editor
                    elseif FormatDataUtils.isValueSummaryClass(currentClass) && ~isa(currentVal,'handle')
                        % table, dataset, cell, struct, categorical, object,
                        % nominal, ordinal data

                        summaryVal = [internal.matlab.datatoolsservices.FormatDataUtils.dimensionString(currentVal) ...
                            ' ' char(FormatDataUtils.getClassString(currentVal)) ];
                        metaData(rowCount,colCount) = true;
                        if istabular(currentVal) && ~isempty(NVPairs.VarName)
                            [isFiltered, rowCount] = internal.matlab.datatoolsservices.FormatDataUtils.getSetFilteredVariableInfo(NVPairs.VarName);
                            if isFiltered
                                summaryVal = [summaryVal ' | ' getString(message('MATLAB:codetools:variableeditor:FilteredVariableSummary', rowCount))];
                            end
                        end
                        renderedData{rowCount,colCount} = summaryVal;
                    elseif isa(currentVal, 'function_handle') && isscalar(currentVal)
                        cellVal = FormatDataUtils.getDisplayEditValue(currentVal, currentFormat);
                        renderedData{rowCount,colCount} = cellVal;
                        metaData(rowCount,colCount) = true;
                    else
                        s = FormatDataUtils.getVariableSize(currentVal);

                        if isa(currentVal, 'ss')
                            s = FormatDataUtils.getSizeString(currentVal);
                        elseif ~FormatDataUtils.isVarEmpty(s) && isnumeric(s) && ~isscalar(s)
                            if isa(currentVal, 'matlab.mixin.internal.CustomSizeString')
                                % This class creates a custom size string for
                                % whos, so we need to use the same value.
                                w = whos('currentVal');
                                s = w.size;
                            end
                            s = string(s);
                            s(ismissing(s)) = "NaN";
                            s = char(join(s, FormatDataUtils.TIMES_SYMBOL));
                        else
                            s = ['1' FormatDataUtils.TIMES_SYMBOL '1'];
                        end
                        cellVal = [s ' ' FormatDataUtils.getClassString(currentVal)];
                        % We used to trim cellVal like this:
                        % strtrim(regexprep(cellVal, '(^[)|(^{)|(}$)|(]$)',''));
                        % But it cuts off 'Jlabel[' in workspace, so it's not
                        % removed.
                        renderedData{rowCount,colCount} = cellVal;
                        metaData(rowCount,colCount) = true;
                    end
                catch
                    % Show "error displaying value" if there's an error (which
                    % can happen when an object is open in the editor, and an
                    % error is inserted)
                    renderedData{rowCount, colCount} = internal.matlab.datatoolsservices.FormatDataUtils.ERR_DISPLAYING_VALUE;
                end
                rowCount = rowCount + 1;
            end
            colCount = colCount + 1;
        end
    end
    renderedDims = size(renderedData);
end
