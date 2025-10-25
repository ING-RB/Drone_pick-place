classdef (Abstract) UISelectionStrategy
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2018 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        Validator
        Options
    end
    
    methods
        
        function strategy = UISelectionStrategy(validator, options)
            strategy.Validator = validator;
            strategy.Options = options;
        end
        
        function index = validate(strategy, option)
            
            if strategy.isIndex(option)
                index = strategy.validateIndex(option);
                return;
            end
            
            text = convertCharsToStrings(option);
            if strategy.Validator.isValidTextInput(strategy, text)
                index = strategy.validateText(text);
                return;
            end
            
            strategy.Validator.handleInvalidInput(strategy);
        end
    end
    
    methods (Access = protected)
        function index = validateIndex(strategy, index)
            
            % Defer to core indexing validation
            N = numel(strategy.Options);
            arr = 1:N;
            % this will throw if it's bad
            [~] = arr(index);
        end
    end
    
    methods (Abstract, Access = protected)
        bool = isIndex(strategy,A)
        index = validateText(strategy, text)
    end
    
    methods (Abstract, Hidden)
        bool = isValidTextShape(strategy, text)
        handleInvalidInputsForSingleLineText(strategy)
        handleInvalidInputsForMultiLineText(strategy)
    end
    
end