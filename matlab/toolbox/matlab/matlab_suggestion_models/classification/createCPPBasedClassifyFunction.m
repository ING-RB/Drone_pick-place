function createCPPBasedClassifyFunction(outdir, modname, opts)
% Function used by Makefile.module at build time in BaT to code generate C++ Lib function for classification.
% Not intended for direct use.
% Inputs:
%   Output directory to store generated files
%   Name of the module where code generation is taking place in

%   Copyright 2022-2023 The MathWorks, Inc.

    arguments
        outdir (1,1) string {mustBeTextScalar} = pwd;
        modname (1,1) string = "classification";
        opts.debug (1,1) logical = false;
    end

    arch  = computer('arch');

    % C++ Lib configuration settings for code generation.
    coderConfig = coder.config('lib');

    % Turn off the following checks for performance.
    coderConfig.RuntimeChecks = false;

    % The file partitioning method must be explicitly specified to avoid
    % throwing EMLRT linker errors.
    coderConfig.FilePartitionMethod = 'SingleFile';
    % The codegenrules.mk harness assumes generated code will have cpp file
    % extensions.
    coderConfig.TargetLang = 'C++';
    % OpenMP support is not yet available via codegenrules.mk.
    coderConfig.EnableOpenMP = false;
    % We do not need to compile and link within MATLAB as the codegenrules
    % build harness will do so.
    coderConfig.GenCodeOnly = false;
    % Code generation deep learning library configuration.
    coderConfig.DeepLearningConfig = coder.DeepLearningConfig('none');

    if opts.debug
        coderConfig.VerificationMode = 'SIL';
        coderConfig.SILDebugging = true;
    end

    % Create testInputData such that it expects a
    % [embeding length x feature queue length]size array where the
    % second dimension is variable in length at prediction time.
    load(fullfile(matlabroot, 'toolbox/matlab/matlab_suggestion_models/+matlab/+internal/+codesuggest/+codingSuggestion/+model/preprocessingWorkspace.mat'), 'wordEmbeddingMatrix')
    embedLength = size(wordEmbeddingMatrix,2);
    exampleInputData = zeros(embedLength, 1, 'single');
    exampleInputData = {coder.typeof(exampleInputData,[embedLength,inf],[0,1])};

    % Use exampleInputData to create argument block for code
    % generation.
    args = {exampleInputData};
    % Function to generated code from.
    entryPointFun = fullfile(matlabroot, 'toolbox', 'matlab', 'matlab_suggestion_models', 'classification', 'private', 'standaloneClassify.m');

    % Run code generation.
    fprintf("starting source code generation for %s on arch=%s", modname, arch);
    codegen('-d', outdir, '-config', coderConfig, '-o', modname, entryPointFun, '-args', args);
    disp('done');
end

% LocalWords:  codegenrules embeding mlai modname
