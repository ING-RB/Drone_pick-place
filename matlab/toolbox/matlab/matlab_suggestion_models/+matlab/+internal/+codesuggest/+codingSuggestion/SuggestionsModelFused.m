classdef (Sealed) SuggestionsModelFused < matlab.internal.codesuggest.codingSuggestion.iSuggestionsModel
    %SUGGESTIONSMODELMAT represents the MATLAB machine learning suggestion model

    %   Copyright 2022-2023 The MathWorks, Inc.
    
    properties (Access = private)
        NetworkMatFile (1,1) string;
        WorkspaceMatFile (1,1) string;
        Net;
        TokenizerGPT;
        TokenToIndexMapping;
        Words;
    end
    
    methods (Access = public)

        function this = SuggestionsModelFused(networkFile, workspaceFile)
            arguments
                networkFile (1,1) string = fullfile(matlabroot, 'toolbox', 'matlab', 'matlab_suggestion_models', ...
                                     '+matlab','+internal', '+codesuggest', '+codingSuggestion','+model', 'network.mat');
                workspaceFile (1,1) string {mustBeFile} = ...
                            fullfile(matlabroot, 'toolbox', 'matlab', 'matlab_suggestion_models', ...
                                     '+matlab','+internal', '+codesuggest', '+codingSuggestion', '+model','preprocessingWorkspace.mat');
            end            
            
            this.NetworkMatFile = networkFile;
            this.WorkspaceMatFile = workspaceFile;

            % Load the pre-trained network "net" from the .MAT file.
            if isfile(this.NetworkMatFile)
                load(this.NetworkMatFile, "params");
                net = matlab.internal.codesuggest.codingSuggestion.params2engine(params);
                this.Net = net;
            else
                 % File does not exist.
                 this.Net = false;
            end

            % Load the "tokenToIndexMapping" dictionary 
            % that has 1-to-1 mapping between MATLAB token and the unique index 
            % of that token from the preprocessingWorkspace.MAT.
            load(this.WorkspaceMatFile, "tokenToIndexMapping");

            this.TokenToIndexMapping = tokenToIndexMapping;
            
            % Create the words string that contains all the matlab tokens
            this.Words = strings(1, length(this.TokenToIndexMapping));
            tokenKey = keys(this.TokenToIndexMapping);
            tokenValue = values(this.TokenToIndexMapping);
            if numel(tokenValue) > 1
                this.Words(tokenValue) = string(tokenKey);
            end
            this.TokenizerGPT = matlab.internal.codesuggest.codingSuggestion.TokenizerGPT(tokenToIndexMapping, 512);
        end
        
        function [suggestion, confidence] = getSuggestions(this, FeatureQueue, UserInputString)
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

            if this.Net == false
                suggestion = [];
                confidence = [];
                return;
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
            % TOKENIZEANDCLASSIFY Generate ranked predictions and confidence scores.
            arguments (Input)
                this;
                FeatureQueue (:, 1) {mustBeText};
            end

            arguments (Output)
                scores;
            end         

            indices = matlab.internal.codesuggest.codingSuggestion.tokenizeUserInput(FeatureQueue, this.TokenizerGPT);
            indices = reshape(indices{1}, [1 , 1, size(indices{1},1)]); % CBT format
            scores = this.getScores(indices);
        end

        function scores = getScores(this,indices)
            %GETSCORES Get the scores for input embeddings

            arguments (Input)
                this;
                indices;
            end

            arguments (Output)
                scores;
            end
            
            % important to transpose here so that sorting happens across
            % the correct dimension in trainFromDatastore
            scores = predict(this.Net, [], single(indices))';

        end
    end
end
