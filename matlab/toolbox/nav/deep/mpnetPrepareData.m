function datastore = mpnetPrepareData(dataset, mpnet)
%

% Copyright 2023 The MathWorks, Inc.

    arguments
        dataset {validateDataset}
        mpnet (1,1) nav.internal.MPNET
    end

    numColsDataset = width(dataset);

    if numColsDataset==1 && prod(mpnet.EncodingSize)>0
        error(message('nav:navalgs:mpnet:EncodingSizeMustBeZero'))
    end

    % Extract environment and paths from the dataset
    switch numColsDataset

      case 1  % For single column dataset containing paths for single environment
        if istable(dataset)
            paths = table2cell(dataset);
        else
            paths = dataset;
        end
        envEncoded = []; % no environment encoding required

      case 2  % For two column dataset containing environment and path
        if istable(dataset)
            envs = table2cell(dataset(:,1));
            paths = table2cell(dataset(:,2));
        else
            envs = dataset(:,1);
            paths = dataset(:,2);
        end
        envEncoded = preprocessEnvironments(mpnet, envs); % prepare environment encoding
    end

    % Preprocess path data and prepare data for training
    inputs = cell(height(dataset), 1);
    targets = cell(height(dataset), 1);
    envPre = [];
    for i = 1:height(dataset)
        statesPre = mpnet.preprocessState(paths{i});
        numStates = height(statesPre)-1;
        if ~isempty(envEncoded)
            envPre = envEncoded(i,:);
            envPre = repmat(envPre, numStates, 1);
        end
        goalPre = repmat(statesPre(end,:), numStates, 1);
        inputs{i} = [statesPre(1:end-1,:), goalPre, envPre];
        targets{i} = statesPre(2:end,:);
    end
    inputs = cell2mat(inputs);
    targets = cell2mat(targets);

    % Convert to datastore
    inputsDatastore = arrayDatastore(inputs, ReadSize=4096);
    outputsDatastore = arrayDatastore(targets, ReadSize=4096);
    datastore = combine(inputsDatastore, outputsDatastore);

end

function envEncoded = preprocessEnvironments(mpnet, envs)
% preprocessEnvironments Convert the raw environment into encodings that
% will be input to the deep learning model

    envSize = length(mpnet.preprocessEnvironment(envs{1}));
    envEncoded = zeros(length(envs), envSize);
    for i = 1:length(envs)
        if i>1 && isequal(envs{i},envs{i-1}) % environment same as previous one
            envEncoded(i,:) = envEncoded(i-1,:);
        else
            envEncoded(i,:) = mpnet.preprocessEnvironment(envs{i}); % encode environment
        end
    end
end


function validateDataset(input)
%validateDataset Validate the dataset input
    validateattributes(input, {'cell','table'}, {'nonempty'},...
                       'mpnetPrepareData', 'dataset');
    if width(input)>2
        error(message("nav:navalgs:mpnet:IncorrectDatasetSize"))
    end
end
