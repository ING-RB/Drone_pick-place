classdef CategoricalConverter < handle
% CATEGORICALCONVERTER - Class to handle categorical2numeric and
% numeric2categorical conversions

% Copyright 2019 The MathWorks, Inc.

    properties
        % Categories - Cell array of category names to be used for conversion 
       Categories cell = {}
    end
    
    properties(Access = private)
       % Num2CatLUT - LUT for numeric to categorical conversion 
       Num2CatLUT categorical = [];
       
       %isInputOrdinal - Oridinality of the Input categorical array
       isInputOrdinal(1,1) logical = false;
    end
    
    methods
        function obj = CategoricalConverter(categories)
            obj.Categories = categories;
            obj.cacheNum2CategoricalLUT();
            
            
        end
        
        function out = numeric2Categorical(obj, numericIn)
            % NUMERIC2CATEGORICAL converts numeric array to a categorical.
            % The conversion is performed using the cached categories.
            %
            % in            - numeric input to be converted
            % out           - converted categorical array
           
            assert(isnumeric(numericIn), 'Error. Input is expected to be numeric');
            if(~isempty(obj.Num2CatLUT) && ~obj.isInputOrdinal)    
                % Use LUT for conversion.
                
                % Shift values by 1, to account for the '0' label. The LUTCache
                % already includes this shift.
                out = reshape(obj.Num2CatLUT(numericIn+1),size(numericIn));
            else
                out = categorical(numericIn, 1:numel(obj.Categories),obj.Categories,...
                    'Ordinal',obj.isInputOrdinal);
            
            end
        end
        
        function out = categorical2Numeric(obj, categoricalIn)
            % CATEGORICAL2NUMERIC converts categorical array to a numeric array with
            % datatype dependent on number of categories.
            %
            % in            - categorical input to be converted
            % out           - converted numeric array
            
            assert(iscategorical(categoricalIn), 'Error. Input is expected to be categorical');
            numCategories = numel(obj.Categories);
            obj.isInputOrdinal = isordinal(categoricalIn);

            if(numCategories <= 2^8)
                out = uint8(categoricalIn); 
            elseif(numCategories > 2^8) && (numCategories <= 2^16)
                out = uint16(categoricalIn);  
            else
                out = double(categoricalIn); 
            end
        end
        
        function value = getNumericValue(obj, className)
            % GETNUMERICVALUE returns the numeric value for a given
            % category classname or returns 0 for missing value
            
            if ischar(className) && any(strcmp(obj.Categories, className))
                idx = ismember(obj.Categories, className);
                value = find(idx);
            elseif ~ischar(className) && ~isnumeric(className) && isscalar(className) && ismissing(className)
                value = 0;
            else
                assert(false, 'Error. Classname should be a character array or missing value');
            end
        end
        
    end
    
    methods (Access = private)
        function cacheNum2CategoricalLUT(obj)
            % Create a LUT to convert a numeric array into categorical. The
            % categories are shifted by 1 to accommodate '0' label.
            %
            % categories - Cell array of category/class names. The max allowed length
            %              of categories is 256.
            
            if(numel(obj.Categories) < 256)
                % Shift value set for labels by 1, to account for '0' label,
                % corresponding to '<undefined>' pixels.
                numericLUT = (1:256+1);
                obj.Num2CatLUT = categorical(numericLUT, 2:numel(obj.Categories)+1, obj.Categories,...
                    'Ordinal',obj.isInputOrdinal);
            end
        
        end
    end
    
    
end