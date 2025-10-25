classdef TokenizerGPT
%TOKENIZERGPT   tokenize the GPT observations into indices.

%   Copyright 2023 The MathWorks, Inc.

    properties (Access = private)
        TokenToIndexMapping
        MaxNumberOfLookBackTokens
        Words
    end

    methods (Access = public)

        function this = TokenizerGPT(tokenToIndexMapping, maxNumberOfLookBackTokens)

            arguments
                tokenToIndexMapping;
                maxNumberOfLookBackTokens (1, 1) double;
            end

            this.TokenToIndexMapping = tokenToIndexMapping;

            % Create the words string that contains all the matlab tokens
            tokenKey = keys(this.TokenToIndexMapping);
            tokenValue = values(this.TokenToIndexMapping);
            this.Words = strings(1, length(this.TokenToIndexMapping));
            this.Words(tokenValue) = string(tokenKey);

            this.MaxNumberOfLookBackTokens = maxNumberOfLookBackTokens;
        end


        function outputTokens = encoder(this, inputTokens)

            arguments (Input)
                this
                inputTokens (1, 1) string;
            end

            if inputTokens == ""
                outputTokens = [];

            else
                % Tokenize the observation file.
                inputTokens = split(strip(inputTokens))';

                % Attach [CLS] to the begining and [SEP] to the end of the observation.
                inputTokens = ["[CLS]", inputTokens, "[SEP]"];

                if all(isKey(this.TokenToIndexMapping, inputTokens))
                    outputTokens = this.TokenToIndexMapping(inputTokens);
                else
                    % Create a vector to store the indices values.
                    outputTokens = double.empty(numel(inputTokens), 0);

                    for tokenIndex = 1:length(inputTokens)
                        % Get the current token from the observation.
                        token = string(inputTokens(tokenIndex));
                        % If this token does not exist in the vocabulary, use the [UNK]
                        % index, otherwise, use the token index.
                        if isKey(this.TokenToIndexMapping, token) == 0
                            outputTokens(tokenIndex) = this.TokenToIndexMapping("[UNK]");
                        else
                            outputTokens(tokenIndex) = this.TokenToIndexMapping(token);
                        end
                    end
                end
            end
        end


        function outputLabel = encoderLabel(this, inputLabel)

            arguments (Input)
                this
                inputLabel (1, 1) string;
            end

            inputLabel = strip(inputLabel);

            if isKey(this.TokenToIndexMapping, inputLabel)
                outputLabel = this.TokenToIndexMapping(inputLabel);
            else
                outputLabel = this.TokenToIndexMapping('[UNK]');
            end
        end


        function outputTokens = decoder(this, inputTokens)

            arguments (Input)
                this
                inputTokens (1, 1) double;
            end

            if isempty(inputTokens)
                outputTokens = "";
            else
                outputTokens = this.Words(inputTokens);
            end
        end


        function outputObservation = unifyLength(this, inputObservation, opts)
        % UNIFYLENGTH   Unify the input observation length to the maximum number of look
        % back tokens.

            arguments (Input)
                this
                inputObservation (1, :) double;
                opts.padding (1, 1) logical = false;
            end

            sequenceLength = numel(inputObservation);
            % Consider the start and end keywords in padding and truncating.
            if sequenceLength > this.MaxNumberOfLookBackTokens
                outputObservation = [inputObservation(1) inputObservation(3:this.MaxNumberOfLookBackTokens) inputObservation(end)];
            elseif sequenceLength < this.MaxNumberOfLookBackTokens && opts.padding == true
                outputObservation = [inputObservation(1) zeros(1, this.MaxNumberOfLookBackTokens-seqSize)+this.TokenToIndexMapping('[PAD]') inputObservation(2:end)];
            else
                outputObservation = inputObservation;
            end
        end
    end
end
