function customXEmbeddings = tokenizeUserInput(featureQueue, TokenizerGPT)
%TOKENIZEUSERINPUT Generate ranked predictions and confidence scores.
% Perform preprocessing steps on feature queue string vector.
% Convert feature queue to word embedding.
% Get ranked predictions from the trained network.

%  Copyright 2021-2023 The MathWorks, Inc.

    % Return if featureQueue is empty.
    if isempty(featureQueue) || all(strlength(featureQueue)==0)
        return;
    end

    % Parse events and retrieve function calls and variables.
    events = matlab.internal.codesuggest.codingSuggestion.Tokenization.tokenize(FeatureQueue=featureQueue);
    observationSample = strjoin(events);

    % Tokenize observation.
    sample = TokenizerGPT.encoder(observationSample);
    customXEmbeddings{1} = TokenizerGPT.unifyLength(sample)';
end
