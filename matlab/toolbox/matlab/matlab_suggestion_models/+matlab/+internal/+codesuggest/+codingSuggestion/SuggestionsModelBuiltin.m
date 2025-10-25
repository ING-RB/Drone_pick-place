classdef (Sealed) SuggestionsModelBuiltin < matlab.internal.codesuggest.codingSuggestion.iSuggestionsModel
    %SUGGESTIONSMODELBUILTIN represents the C++ machine learning suggestion model

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties (Access = private)
        VocabSize (1, 1) double {mustBeInteger, mustBeFinite};
        WorkspaceMatFile (1,1) string = ...
                    fullfile(matlabroot, 'toolbox/matlab/matlab_suggestion_models/+matlab/+internal/+codesuggest/+codingSuggestion/+model/preprocessingWorkspace.mat');
        WordEmbeddingMatrix;
        TokenToIndexMapping;
        Words;
    end

    methods (Access = public)

        function this = SuggestionsModelBuiltin()
            % Load the "wordEmbeddingMatrix" and "tokenToIndexMapping" dictionary 
            % that has 1-to-1 mapping between MATLAB token and the unique index 
            % of that token from the preprocessingWorkspace.MAT.
            load(this.WorkspaceMatFile, "wordEmbeddingMatrix", "tokenToIndexMapping");

            % Assign loaded variables to object properties
            this.WordEmbeddingMatrix = wordEmbeddingMatrix;
            this.TokenToIndexMapping = tokenToIndexMapping;

            % Create the words string that contains all the matlab tokens
            this.Words = strings(1, length(this.TokenToIndexMapping));
            tokenKey = keys(this.TokenToIndexMapping);
            tokenValue = values(this.TokenToIndexMapping);
            this.Words(tokenValue) = string(tokenKey);

            % Calculate vocabulary size
            this.VocabSize = numel(this.Words);
        end

        function [suggestion, confidence] =  getSuggestions(this, FeatureQueue, UserInputString)
            %GETSUGGESTIONS Get the expected suggestion and confidence
            %scores
            %
            % Steps:
            %   1. Preprocess feature queue
            %   2. Convert feature queue to word embedding
            %   3. Get predictions from pre-trained network
            %   4. Get ranked classes
            %   5. Output top k functionCalls
            arguments (Input)
                this
                FeatureQueue (:,1) {mustBeText}
                UserInputString (1,:) {mustBeTextScalar}
            end

            arguments (Output)
                suggestion
                confidence
            end

            scores = this.tokenizeAndClassify(FeatureQueue);

            % Return empty suggesting and confidence values if tokenizeAndClassify
            % returns not scores.
            if isempty(scores)
                suggestion = [];
                confidence = [];
                return;
            end

            % Sort the prediction based on their classification confidence scores
            % from the highest the lowest score.
            [customSortedScores, customTopScoreIndices] = sort(scores, 2, 'descend');

            % Get the predicted labels based on the sorted confidence scores.
            customYPredTopWords = this.Words(customTopScoreIndices);
            suggestion = customYPredTopWords.';
            confidence = customSortedScores.';

            % Remove predictions that do not match the following regexp.
            if strlength(UserInputString) ~= 0
                % The regexp matches on 3 patterns:
                %   - f_userInputString
                %   - f_[dot notation function signature].userInputString
                %   - f_[multiple alternative function signatures]|userInputString
                mask = startsWith(suggestion, regexpPattern('f_(' + UserInputString + '|.*\|' + UserInputString + ')'), "IgnoreCase", true);                
                suggestion = suggestion(mask);
                confidence = confidence(mask);
            end
        end


        function tf = eq(this, inputModel)
            %EQ Operator '==' overload for checking object equivalence 
            tf = false;
            if isequal(class(this), class(inputModel)) && isequal(this, inputModel)
                tf = true;
            end
        end
    end

    methods (Access = private)

        function scores = tokenizeAndClassify(this, FeatureQueue)
            %TOKENIZEANDCLASSIFY Generate ranked predictions and confidence scores.
            arguments
                this;
                FeatureQueue (:, 1) {mustBeText};
            end

            customXEmbeddings = matlab.internal.codesuggest.codingSuggestion.tokenizeUserInput(FeatureQueue, this.WordEmbeddingMatrix, this.TokenToIndexMapping);
            scores = this.getScores(customXEmbeddings);
        end

        function scores = getScores(this, xEmbeddings)
            %GETSCORES Get prediction scores for the input embedding
            arguments (Input)
                this;
                xEmbeddings;
            end

            arguments (Output)
                scores;
            end

            embeddingLength = size(xEmbeddings{1}, 1);
            scores = matlab.internal.codesuggest.codingSuggestion.codingSuggestionClassify(xEmbeddings, this.VocabSize, embeddingLength);
        end
    end
end
