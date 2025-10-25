function [suggestion, confidence] =  predictFromFeatureQueue(FeatureQueue, UserInputString, opts)
%PREDICTFROMFEATUREQUEUE Generate prediction using code suggestion model.
% Take the feature queue as an input and return the confidence values.

%   Copyright 2021-2023 The MathWorks, Inc.

    arguments
        FeatureQueue (:, 1) {mustBeText};
        UserInputString {mustBeTextScalar};
        opts.Model = false;
        opts.LimitOutput (1,1) logical = true;
        opts.Flush (1,1) logical = false;
    end
    
    persistent model;

    if opts.Flush
        model = [];
        return;
    end

    if isempty(model)
        if ~isempty(opts.Model) && isa(opts.Model, "matlab.internal.codesuggest.codingSuggestion.iSuggestionsModel")    % set a specific model
            model = opts.Model;
        else
            model = matlab.internal.codesuggest.codingSuggestion.SuggestionsModelFused;
        end
    elseif model ~= opts.Model && isa(opts.Model, "matlab.internal.codesuggest.codingSuggestion.iSuggestionsModel")     % flush and replace
        model = opts.Model;
    end
    
    % Return empty suggestion if featureQueue=='' (empty, a 0x1 char vector)
    % or "" (a string without any characters)
    if isempty(FeatureQueue) || all(strlength(FeatureQueue)==0)
        suggestion = [];
        confidence = [];
        return;
    end

    % Get suggestions and confidence scores from the model
    [suggestion, confidence] = model.getSuggestions(FeatureQueue, UserInputString);

    % Remove any empty string in the suggestoin list.
    if numel(suggestion) > 0
        nonEmptySuggestion = suggestion ~= "";
        suggestion = suggestion(nonEmptySuggestion);
        confidence = confidence(nonEmptySuggestion);

        % Limit the number of suggestions to 10.
        if opts.LimitOutput && (numel(suggestion) > 10)
            suggestion = suggestion(1:10);
            confidence = confidence(1:10);
        end
    end
end
% LocalWords:  tc tokenization
