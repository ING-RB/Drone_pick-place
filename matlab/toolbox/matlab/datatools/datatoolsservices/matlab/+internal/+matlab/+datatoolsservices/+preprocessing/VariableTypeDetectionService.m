classdef VariableTypeDetectionService
    % This class consists of logic to help determine the most appropriate
    % datatype for a given variable
    
    % Copyright 2018-2020 The MathWorks, Inc.
       
    methods(Static)
        % detects and returns the text/string columns which are more appropriate as
        % categorical columns
        function categoricalContainerColumns = getPossibleCategoricalColumnsFromData(data)
            import internal.matlab.datatoolsservices.preprocessing.VariableTypeDetectionService;

            if ~isstring(data)
                data = string(data);
            end
            categoricalContainerColumns = false(1, size(data, 2));
            for col = 1:size(data, 2)
                categoricalContainerColumns(col) = VariableTypeDetectionService.isPossibleCategoricalVector(data(:, col));
            end
        end
        
        % detects is a column vector of data could be of type categorical
        function ispossiblecategorical = isPossibleCategoricalVector(colVector)
            if ~isstring(colVector)
                colVector = string(colVector);
            end
            [~, ia, ~] = unique(colVector);
            
            % strtrim to avoid empty text from effecting the calculations
            ispossiblecategorical = (length(ia)/length(colVector(strtrim(colVector) ~= '')) < 0.7);
        end
        
        % Checks to see if the string array colData contains text which appears
        % to be numeric.  For example, ["5km"; "3km"; "2.5km"] returns true.
        % Specify the decimalSeparator to use, and set the flag
        % requireAllNumeric to true to only return true if all of the data
        % appears to be numeric.
        function [isNumericCol, prefixes, suffixes] = isPossibleNumericVector(...
                colVector, decimalSeparator, requireAllNumeric)
            import internal.matlab.datatoolsservices.preprocessing.VariableTypeDetectionService;
            
            % Convert to string if necessary
            if ~isstring(colVector)
                colVector = string(colVector);
            end

            % Find numeric indices, prefixes and suffixes
            [Inumeric, prefixes, suffixes] = VariableTypeDetectionService.findNumericDataIndices(...
                colVector, decimalSeparator);
            
            if (requireAllNumeric)
                % If the requireAllNumeric flag is set, return true only if all
                % of the indices are numeric.
                isNumericCol = all(Inumeric);
            else
                % Otherwise, use the prefixes and suffixes, along with the data,
                % to determine if this could be considered numeric.
                numNonEmptyRows = length(colVector) - sum(colVector == '' | ismissing(colVector));
                isNumericCol = VariableTypeDetectionService.isNumericColFromParts(...
                    numNonEmptyRows, Inumeric, prefixes, suffixes);
                
                if ~isNumericCol && any(Inumeric) && length(Inumeric) > 1
                    % There are some numbers, but still unsure if this
                    % column should be treated as numeric. Try again, but
                    % only with unique values.  This handles the case where
                    % there are some numbers, and a lot of a single text
                    % value.  Something like:
                    % 1,NA,NA,NA,NA,2,NA,NA,NA,3,NA,...
                    % (Don't do this for very large files, where we want to
                    % default to these columns being text, for better
                    % performance).
                    c = rmmissing(unique(colVector));
                    c(c == "") = [];
                    [Inumeric, prefixes, suffixes] = VariableTypeDetectionService.findNumericDataIndices(...
                        c, decimalSeparator);
                    numNonEmptyRows = length(colVector) - sum(colVector == '' | ismissing(colVector));
                    isNumericCol = VariableTypeDetectionService.isNumericColFromParts(...
                        numNonEmptyRows, Inumeric, prefixes, suffixes);
                end
            end
        end
        
        % Extracts any numeric values using the same regexp criteria that the
        % isPossibleNumericVector function uses.  If there is no numeric value
        % to extract, the return value is empty [].  Input text value is a sclar
        % string or char row vector.
        function dblValue = extractNumberFromText(textValue, decimalSeparator, thousandsSeparator)
            import internal.matlab.datatoolsservices.preprocessing.VariableTypeDetectionService;
            dblValue = [];
            
            if (isStringScalar(textValue) || ischar(textValue))
                % Use default values if empty
                if isempty(decimalSeparator)
                    decimalSeparator = ".";
                end
                if isempty(thousandsSeparator)
                    thousandsSeparator = ",";
                end
                regexstr = VariableTypeDetectionService.getNumericRegexpStr(...
                    decimalSeparator, thousandsSeparator);
                extractedVal = regexp(textValue, regexstr, 'Names');
                if isstruct(extractedVal) && ~isempty(extractedVal) && ~isempty(extractedVal.numbers)
                    if ~isequal(thousandsSeparator, ",")
                        % If the thousands separator is non-default, remove it
                        % before the conversion to double.
                        extractedVal.numbers = replace(extractedVal.numbers, thousandsSeparator, "");
                    end
                    if ~isequal(decimalSeparator, ".")
                        % If the decimal separator is non-default, replace it
                        % with the default "." before the conversion to double.
                        extractedVal.numbers = replace(extractedVal.numbers, decimalSeparator, ".");
                    end
                    if endsWith(extractedVal.numbers, "+") 
                        extractedVal.numbers = extractBefore(extractedVal.numbers, "+");
                    elseif endsWith(extractedVal.numbers, "-")
                        extractedVal.numbers = extractBefore(extractedVal.numbers, "-");
                    end
                    dblValue = str2double(extractedVal.numbers);
                elseif strcmpi(textValue, "nan")
                    % Any variations of the word nan should be treated as NaN
                    dblValue = NaN;
                end
            end
        end
    end
    
    methods(Static, Hidden)
        % Checks to see if a column of data appears to be numeric, based on the
        % number of non-empty rows, a logical array of whether text contains
        % numeric valus, and the prefixes and suffixes for the data.
        function isNumericCol = isNumericColFromParts(numNonEmptyRows, Inumeric, prefixes, suffixes)
            isNumericCol = false;
            
            % Assume non-numeric for small sets of data, where there's too
            % little data to predict well.  Erring on the side of non-numeric
            % results in better performance too, because it won't require
            % slow-path processing.
            minNumColumnsToPredict = 3;
            if numNonEmptyRows <= minNumColumnsToPredict && ~all(Inumeric)
                return;
            end
            
            if numNonEmptyRows > 0 && sum(Inumeric) >= numNonEmptyRows/2
                [~, ~, Iprefixes] = unique(prefixes);
                [~, modeCount] = mode(Iprefixes);
                if modeCount >= numNonEmptyRows/2
                    [~ ,~ ,Isuffixes] = unique(suffixes);
                    [~, modeCount] = mode(Isuffixes);
                    if modeCount >= numNonEmptyRows/2
                        isNumericCol = true;
                    end
                end
            end
        end       

        function regexstr = getNumericRegexpStr(decimalSeparator, thousandsSeparator)
            regexstr = "(?<prefix>.*?)(?<numbers>([ ]*[-\+]{0,1}([0-9]+[\" + ...
                thousandsSeparator + "]*)+[\" + decimalSeparator + ...
                "]{0,1}[0-9]*[eEdD]{0,1}[-+]*[0-9]*[i]{0,1})|([-]*([0-9]+[\" + ...
                thousandsSeparator + "]*)*[\" + decimalSeparator + ...
                "]{1,1}[0-9]+[eEdD]{0,1}[0-9]*[i]{0,1}))(?<suffix>[-+]*.*)";
        end
        
        % Returns numeric data contained in a string array, including its
        % prefixes and suffixes.  For example, ["5km"; "3km"; "2.5km"] returns
        % [true; true; true], prefixes as [""; ""; ""], and suffixes as ["km";
        % "km"; "km"].
        function [numbers, prefix, suffix] = findNumericDataIndices(numberCol, decimalSeparator)
            import internal.matlab.datatoolsservices.preprocessing.VariableTypeDetectionService;
                        
            numberCol(ismissing(numberCol)) = '';
            numbers = false(size(numberCol));
            if nargin < 2 || isempty(decimalSeparator)
                decimalSeparator = '.';
            else
                decimalSeparator = convertStringsToChars(decimalSeparator);
            end
            if nargin < 3
                if decimalSeparator == '.'
                    thousandsSeparator = ',';
                elseif decimalSeparator == ','
                    thousandsSeparator = '.';
                else
                    thousandsSeparator = '';
                end
            end
            
            % Parse '.123'
            regexstr = VariableTypeDetectionService.getNumericRegexpStr(decimalSeparator, thousandsSeparator);
            try
                result = regexp(numberCol, regexstr, 'names');
                % result is a cell arrays of structures... not very useful.
                % Convert to a structure array.
                if iscell(result)
                    st = [result{:}];
                else
                    st = result;
                end
                
                numbersStr = [st.numbers]';
                invalidThousandsSeparator = false(size(numberCol));
                if any(numbersStr.contains(thousandsSeparator))
                    thousandsRegExp = ['^[0-9]+?(\' thousandsSeparator  '[0-9]{3})*\' decimalSeparator '{0,1}[0-9]*$'];
                    res = regexp(numbersStr, thousandsRegExp, 'once');
                    invalidThousandsSeparator = cellfun(@isempty, res);
                    numbersStr(invalidThousandsSeparator) = '';
                end
                
                numbersStr = strrep(numbersStr, thousandsSeparator, '');
                numbersStr = strrep(numbersStr, decimalSeparator, '.');
                
                for i = 1:size(numbersStr, 1)
                    if ~invalidThousandsSeparator(i)
                        val = textscan(numbersStr(i), '%f');
                        val = val{1};
                        if ~isempty(val) && isscalar(val)
                            numbers(i) = true;
                        end
                    end
                end
            catch me %#ok<NASGU>
            end
            
            try
                prefix = [st.prefix]';
            catch me %#ok<NASGU>
                prefix = string;
            end
            
            try
                % Consider text with numbers in the suffix to not be detected as
                % numeric.  For example "3 out of 5 people" will have 3 as the
                % number, but the suffix as "out of 5 people".  Don't treat this
                % as numeric.
                suffix = [st.suffix]';
                res = regexp(suffix, '[0-9]');
                if iscell(res)
                    numsInSuffix = ~cellfun('isempty', res);
                    numbers(1:length(res)) = ~numsInSuffix;
                else
                    numsInSuffix = ~isempty(res);
                    numbers = ~numsInSuffix;
                end
                
            catch me %#ok<NASGU>
                suffix = string;
            end
        end
    end
end

