function models = listModels

    blockDiagrams = find_system('Type', 'block_diagram');

    % remove any libraries
    blockDiagrams(strcmp(get_param(blockDiagrams, 'blockdiagramtype'), 'library')) = [];

    % return the models
    if isempty(blockDiagrams)
        models = [];
    else
        models = get_param(blockDiagrams, 'uddobject');
        models = [models{:}];
    end

%   Copyright 2002-2004 The MathWorks, Inc.
