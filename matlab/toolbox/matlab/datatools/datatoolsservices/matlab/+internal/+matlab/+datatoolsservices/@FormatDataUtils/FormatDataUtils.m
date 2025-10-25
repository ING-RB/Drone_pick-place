classdef FormatDataUtils < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % FORMATDATAUTILS

    % Copyright 2015-2024 The MathWorks, Inc.

    properties(Constant)
        MAX_DISPLAY_ELEMENTS = 11;
        MAX_DISPLAY_DIMENSIONS = 2;
        CHAR_WIDTH = 7;         % Width of each character in the string
        HEADER_CHAR_WIDTH = 8; % Client side mirrored in liveeditor/InteractiveVariableOutputUtils.js
        HEADER_UPPER_CHAR_WIDTH = 10;
        HEADER_UPPER_LEN_CUTOFF = 0.75;
        HEADER_BUFFER = 10;     % The amount of room(leading and trailing space) the header should have after resizing to fit the header name
        MAX_CATEGORICALS = 25001;
        MAX_TEXT_DISPLAY_LENGTH = 100000;

        % Always use the multiplication symbol instead of lower-case 'x'.  We no
        % longer use matlab.internal.display.getDimensionSpecifier, because that
        % can change for MATLAB Online/MATLAB mobile applications, which isn't
        % desirable.
        TIMES_SYMBOL = char(215);

        % TODO: Tech Debt: Remove once we switch to client side computation of default widths
        VE_HEADER_PADDING = 7;
        VE_HEADER_CUSTOM_ICON = 12;
        VE_HEADER_MENU = 12;
        VE_RESIZER = 7;
        CARRIAGE_RETURN = char(13);
        NUM_DIMENSIONS_TO_SHOW = 4;
        EXPANDABLE_MATRIX_CLASSES = ["categorical", "nominal", "ordinal", "datetime", "duration", "calendarDuration"];
        ERR_DISPLAYING_VALUE = getString(message('MATLAB:codetools:workspacefunc:ErrorDisplayingValue'));
        WORKSPACE_NAME = 'who.';
        NO_VALUE_PLACEHOLDER = getString(message('MATLAB:codetools:variableeditor:NoValue'));
    end

    properties
        % We want this prop to be static across instances.
        RowLimitForWidthCalc = containers.Map;
    end

    methods(Access='public')
        setRowLimitCutoff(this, userContext, limit);
        jsonData = getJSONforCell(~, data, longData, isMeta, editorValue, row, col);
        [renderedData, renderedDims, metaData] = formatSingleDataForMixedView(this, currentData, currentFormat);
    end

    methods(Static)
        subsExpr = generateDotSubscriptingForDataset(t, subs, tname, forceNumericIndex);
        [varNameExpr, subsExpr, validRHS] = generateVariableNameAssignmentStringDataset(t, subs, vname, tname);
        nameWidth = computeHeaderWidthUsingLabels(name);
        [isUniform, className] = uniformTypeData(data);
        actualClassName = getLookupClassName(originalClass, sampleSet, actualClassName);
        structDataAsCell = convertStructToCell(structData);
        objDataAsCell = convertObjectArrayToCell(objArray, props);
        objAsCell = obj2cell(objArray, props);
        [renderedData, renderedDims, metaData] = formatDataBlockForMixedView(startRow,endRow,startColumn,endColumn,currentData, currentFormat, NVPairs);
        renderedData = getClassUnderlyingTypeSummary(currentVal);
        cellVal = getCharCellVal(currentVal);
        [renderedData, isDimsAndClassName] = getCompactDisplayForData(currentVal, displayConfig);
        cellVal = getTallCellVal(currentVal);
        szz = getSizeString(value);
        [renderedData, renderedDims] = getJSONForArrayData(data, startRow, endRow, startColumn, endColumn);
        jsonStr = convertToJSON(varargin);
        vals = replaceNewLineWithWhiteSpace(r);
        displaySize = formatSize(data, truncateDimensions);
        formattedSize = getFormattedSize(s, truncateDimensions);
        loadPerformance(es);
        [secondaryType, secondaryStatus] = getVariableSecondaryInfo(vardata);
        [secondaryType, secondaryStatus] = getTallData(vardata);
        tallInfoSize = getTallInfoSize(tallInfo);
        s = checkIsString(var);
        [startRow, endRow, startColumn, endColumn] = resolveRequestSizeWithObj(startRow, endRow, startColumn, endColumn, sz);
        varSize = getVariableSize(value, varargin);
        tableSize = getActualTableSize(value);
        b = isVarEmpty(var);
        result = isValueSummaryClass(className);
        result = isExpandableScalar(className);
        isSummary = isSummaryValue(data);
        [isSummary, valuesToExpand] = isSummaryValueForCellType(data);
        valuesummary = getValueSummaryString(currentVal, underlyingClass);
        clazz = getClassString(value, useShortClassName, useParens);
        clazz = addComplexSparseToClass(clazz, isReal, isSparse, useParens);
        cellVal = getNumericNonScalarValueDisplay(currentVal, currentFormat);
        vals = parseNumericColumn(r, currentData, currentFormat);
        [fullData, subsetData] = getNumericValue(fullData, subsetData);
        [varNameExpr, subsExpr, validRHS] = generateVariableNameAssignmentString(vname, tname, ind);
        editValue = getDisplayEditValue(dataValue, format);
        numType = isNumericType(type);
        [currentFormat, c] = getCurrentNumericFormat (shouldRestoreFormat);
        restoreNumericFormat (formatToRestore, hasTempFormat);
        val = getVirtualObjPropSize(obj, propName);
        val = getVirtualObjPropValue(obj, propName);
        val = getVirtualObjPropClass(obj, propName);
        [isFiltered, filteredRowCount] = getSetFilteredVariableInfo(varName, filteredRowCount, isFiltered);
        str = dimensionString(inp);
        b = getDesktopInUse();
        cellValueStr = strArrayParsing(d,dSize);
        cellValue = expandableArrayParsing(d,dSize);
        isNonPrimitiveObject = checkNonPrimitiveObject(value);
        fieldsAfterWorkspaceName = extractFieldsAfterWorkspaceName(selectedFields);
        d = correctDimensionSpec(dispData);
        v = formattedClassValue(editValue, primaryDataType);
    end
end
