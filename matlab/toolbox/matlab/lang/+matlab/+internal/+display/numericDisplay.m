function varargout = numericDisplay(data, input_data_subset, namedargs)
    % This helper function is used to get the formatted display output for
    % the given numeric/logical data. It returns two outputs:
    % 1) A string array representation of the display output. 
    % 2) The scaling factor for the given data
    %
    % This helper function only works with numeric data up to two
    % dimensions.
    % 
    % The second argument is an optional input which could be either be:
    % a. A numeric array, OR
    % b. An instance of matlab.display.internal.NumericDisplayFormatter
    %
    % If the second argument is a numeric array, we compute the formatted
    % display output of this input based on the characteristics of the
    % first input. In this case, this input should be a subset of the
    % numeric array in the first argument.
    % If the second argument is an instance of
    % matlab.display.internal.NumericDisplayFormatter, we use the
    % properties of this object to compute the formatted display output of
    % the numeric array.
    %
    % It also takes in a set of optional Name-Value pairs that provide
    % additional information for processing the data:
    %
    % 'Format': This specifies the numeric display format. It can be one of
    % these - +, bank, hex, long, longE, longEng, longG, rat short, shortE,
    % shortEng, shortG. The default is the current format.
    %
    % 'ScalarOutput': This is a logical value. If this is set to true, the
    % output is returned as a 1x1 string array. Otherwise, the output is
    % returned as a string array which has the same dimensions as that of
    % the input. The default value is false.
    %
    % 'OmitScalingFactor': This is a logical value. If this is set to true,
    % the scaling factor of the output display string will be 1.

    %Copyright 2017-2024 The MathWorks, Inc.
    
    arguments
        data {mustBeNumericOrLogical, mustBeTwoDimensional}
        input_data_subset = data
        namedargs.ScalarOutput (1,1) logical = false
        namedargs.Format {mustBeNonempty, mustBeTextScalar, mustBeNonzeroLengthText} = matlab.internal.display.format
        namedargs.OmitScalingFactor (1,1) logical = false
    end
    
    % If optional second input is a formatter, get the format and
    % complexity information from it
    if isa(input_data_subset, 'matlab.display.internal.NumericDisplayFormatter')        
        % Get format information
        namedargs.Format = input_data_subset.Format;
        
        % Get complexity information
        is_formatter_complex = input_data_subset.Complex;
        is_data_complex = ~isreal(data);
        if is_formatter_complex ~= is_data_complex
            if is_formatter_complex
                % Update the complexity of the data
                data = complex(data);
            else
                % Formatter object is not complex but the data is complex
                error('MATLAB:numericDisplay:InconsistentWithFormatterObject', ...
                    message('MATLAB:numericDisplay:InconsistentWithFormatterObject').getString());
            end
        end
    elseif isnumeric(input_data_subset) || islogical(input_data_subset)
        isValidSubNumericDataOrFormatter(input_data_subset, data);
    else
         error('MATLAB:class:RequireNumeric', message('MATLAB:class:RequireNumeric').getString());
    end
    
    [out, scale] = matlab.internal.display.numericDisplayHelper(data, ...
        input_data_subset, namedargs);

    if (nargout == 0 || nargout ==1)
        varargout{1} = out;
    elseif nargout == 2
        varargout{1} = out;
        varargout{2} = scale;
    end
end


function isValidNumericData(data)
    if ~(isnumeric(data) || islogical(data))
        error('MATLAB:class:RequireNumeric', message('MATLAB:class:RequireNumeric').getString());
    end
    
     if numel(size(data)) > 2
         error('MATLAB:class:RequireNDims', message('MATLAB:class:RequireNDims', 2).getString());
     end
end

function isValidSubNumericDataOrFormatter(data, superset_data)
    if ~isa(data, 'matlab.display.internal.NumericDisplayFormatter')
        % Option second input is a numeric data
        isValidNumericData(data);
     
        if ~strcmp(class(data), class(superset_data))
            error('MATLAB:class:RequireClass', message('MATLAB:class:RequireClass', class(superset_data)).getString());
        end

        orig_data_sparseness = issparse(superset_data);
        orig_data_complexity = isreal(superset_data);
        sub_data_sparseness = issparse(data);
        sub_data_complexity = isreal(data);    

        if orig_data_sparseness ~= sub_data_sparseness
            if orig_data_sparseness
                error('MATLAB:services:printmat:mustBeSparse', message('MATLAB:services:printmat:mustBeSparse').getString());
            else
                error('MATLAB:class:RequireClass', message('MATLAB:class:RequireClass', class(superset_data)).getString());
            end         
        end

        if orig_data_complexity ~= sub_data_complexity
            if orig_data_complexity
                error('MATLAB:validators:mustBeReal', message('MATLAB:validators:mustBeReal').getString());
            else
                error('MATLAB:services:printmat:mustBeComplex', message('MATLAB:services:printmat:mustBeComplex').getString());            
            end        
        end    
    end        
end

function mustBeTwoDimensional(data)
     if numel(size(data)) > 2
         error('MATLAB:class:RequireNDims', message('MATLAB:class:RequireNDims', 2).getString());
     end
end