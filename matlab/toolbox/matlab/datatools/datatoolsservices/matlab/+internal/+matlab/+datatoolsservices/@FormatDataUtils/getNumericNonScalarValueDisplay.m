% Returns cellVal as a string containing concatenated display of currentVal

% Copyright 2015-2023 The MathWorks, Inc.

function cellVal = getNumericNonScalarValueDisplay(currentVal, currentFormat)
    arguments
        currentVal
        currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
    end
    import internal.matlab.datatoolsservices.FormatDataUtils;

    [numericDisp, scaleFactor] = matlab.internal.display.numericDisplay(currentVal, Format = currentFormat);
    if size(currentVal,1) == 1 && scaleFactor == 1
        cellVal = char("[" + join(numericDisp, ",") + "]");
    elseif size(currentVal,2) == 1 && scaleFactor == 1
        cellVal = char("[" + join(numericDisp, ";") + "]");
    else
        currData = currentVal;
        cellVal = '';
        vals = cell(1,size(currentVal,2));
        for cellCol=1:size(currentVal,2)
            if ~isa(currData, 'half')
                if ~isreal(currData)
                    d = complex(currData(:,cellCol));
                else
                    d = currData(:,cellCol);
                end
                vals{cellCol} = {cellstr(matlab.internal.display.numericDisplay(d, d, 'ScalarOutput', false, 'Format', currentFormat, 'OmitScalingFactor', true))};
            else
                % TODO: Remove when g2577149 is resolved
                if ~isreal(currData)
                    r=evalc('disp(complex(currData(:,cellCol)))');
                else
                    r=evalc('disp(currData(:,cellCol))');
                end
                vals{cellCol} = FormatDataUtils.parseNumericColumn(r, currData(:,cellCol), currentFormat);
            end
        end

        for cellRow=1:size(currentVal,1)
            if cellRow>1
                cellVal = [cellVal ';']; %#ok<*AGROW>
            end
            for cellCol=1:size(currentVal,2)
                if cellCol>1
                    cellVal = [cellVal ','];
                end

                colData = vals{cellCol};
                cellVal = [cellVal colData{1}{cellRow}];
            end
        end

        cellVal = ['[' cellVal ']'];
    end

    % Fix to make sure integer values don't show trailing zeros TODO:  Ideally
    % the display API's do this, but currently there is a difference between the
    % disp of the numeric display and the contained disp of the numeric display
    if strcmp(currentFormat, "short")
        cellVal = strrep(cellVal, '.0000', '');
    end
end
