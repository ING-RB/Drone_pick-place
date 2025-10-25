classdef DataFormatUtils
    %DATAFORMATUTILS Shared utilities responsible for formatting data
    
    
    methods (Static)
        function formattedValue = formatNumericData(value, numericFormat)
            % FORMATNUMERICDATA - Returns a cellstr of the same size as
            % value with the char array versions of the numbers

            % In the case where the input is 'rat', update it to 'rational'
            if strcmp(numericFormat, "rat")
                numericFormat = "rational";
            end

            % This is an internal assert here while development work is
            % underway.  This function is not expected to error in
            % practice.
            assert(...
                any(string(numericFormat) == ...
                ["+", "bank", "hex", "long", "longE", "longEng", "longG",...
                "rational", "short", "shortE", "shortEng", "shortG"]), ...
                "Numeric format was not supported")

            % Sparse arrays must be shown consistently to how table arrays
            % show the values.  The numericDisplay requires the casted
            % version of the data in order to achieve this display.
            if issparse(value)
                [formattedStringArray, scalingFactor]  = ...
                    matlab.internal.display.numericDisplay(full(value), full(value), 'Format', numericFormat);            
            else
                [formattedStringArray, scalingFactor]  = ...
                    matlab.internal.display.numericDisplay(value, value, 'Format', numericFormat);
            end

            if scalingFactor == 1
                formattedValue = cellstr(formattedStringArray);
            else

                % Use linear indexing to simplify logic
                % Formatting must honor the non scaled version of the data,
                % as if the individual number was display on commandline.
                if issparse(value)
                    formattedText = matlab.internal.display.containedDisplay(reshape(full(value), 1, numel(full(value))), 100000, 'Format', numericFormat, 'CommaDelimiter', true); 
                else
                    formattedText = matlab.internal.display.containedDisplay(reshape(value, 1, numel(value)), 100000, 'Format', numericFormat, 'CommaDelimiter', true); 
                end
                textFormat = '%s';
                scannedData = textscan(formattedText,textFormat,'Delimiter',',');
                formattedValue = reshape(strtrim(scannedData{1}), size(value, 1), size(value, 2));
            end
        end
    end
end

