function scores = standaloneClassify(customXEmbeddings)
% Entry point function used by code generation to create C++ function for classification
% Not intended for direct use.
% Inputs:
%   Processed X embeddings used for classification

%   Copyright 2022 The MathWorks, Inc.

%#codegen

    persistent pretrainedNetwork;

    if isempty(pretrainedNetwork)
        pretrainedNetwork = coder.loadDeepLearningNetwork( ...
            coder.const([matlabroot, '/', 'toolbox', '/', 'mwtools', '/', 'matlab_suggestion_models_nonshipping', '/', '+mlai',...
            '/', '+codingSuggestion', '/', '+modelInfo', '/', 'network.mat']));
    end
    miniBatchSize = coder.const(10);
    scores = pretrainedNetwork.predict(customXEmbeddings, ...
                                       'ReturnCategorical', false, ...
                                       'MiniBatchSize', miniBatchSize, ...
                                       'SequenceLength', 'longest');

end

% LocalWords:  mlai
