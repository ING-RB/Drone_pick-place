function [sonifiedData, Fs] = sonify(xData,yData,options)
    % SONIFY generates audio to describe the characteristics of the data.
    % This function converts input data (x, y) into an audio representation based on various parameters.
    % The audio reflects the pattern and distribution of the data, allowing for auditory analysis.
    %
    % Inputs:
    %    x - Independent variable data. If not provided, indices of y are used.
    %    y - Dependent variable data to be sonified.
    %   Name-Value Pairs:
    %       'FrequencyRange' - Two-element vector specifying the frequency range.
    %       'Playback' - Logical indicating whether to play the sound.
    %       'Duration' - Duration of the sound in seconds.
    %
    % Outputs:
    %    sonifiedData - The generated audio signal representing the input data.
    %    Fs - The sampling frequency used for the audio signal.

    %   Copyright 2024 The MathWorks, Inc.

    arguments
        xData (1,:) {mustBeNumeric, mustBeFinite, mustBeReal, mustBeNonNan, mustBeNonempty} 
        yData (1,:) {mustBeNumeric, mustBeFinite, mustBeReal, mustBeNonNan}  = []
        options.FrequencyRange (1,:)  {mustBeNumeric, mustBeFinite, mustBeNonNan, mustBeValidFrequencyRange} =  [audiovideo.internal.sonification.SonificationConstants.DefaultFrequencyMin, audiovideo.internal.sonification.SonificationConstants.DefaultFrequencyMax]
        options.Playback (1,1)  {mustBeLogicalOrNumericBinary,mustBeFinite} = audiovideo.internal.sonification.SonificationConstants.DefaultPlayback
        options.Duration (1,1)  {mustBeNumeric, mustBePositive, mustBeFinite}  = audiovideo.internal.sonification.SonificationConstants.DefaultDuration
    end
    % check with xData and yData is provided and one of them is empty
    if nargin == 2
        if isempty(xData) && ~isempty(yData) || ~isempty(xData) && isempty(yData)
            throwAsCaller(MException('Input:DimensionMismatch', message('MATLAB:audiovideo:sonification:DimensionMismatch')));
        end
    end
    try
        % Adjust inputs if necessary
        [xData, yData] = adjustInputs(xData, yData);

        % Validate 'xData' and 'yData' after handling input adjustments
        validateInputs(xData, yData);

        % Create an instance of the sonification class with parsed options
        sonifyObj = audiovideo.internal.sonification.DataSonifier(xData,yData,'FrequencyRange', options.FrequencyRange, 'Playback', options.Playback, 'Duration', options.Duration);

        % Generate the sonified data
        [sonifiedData, Fs] = sonify(sonifyObj);
    catch exception
        throwAsCaller(exception);
    end

end

% adjustInputs Prepares xData and yData inputs for sonification.
% This function adjusts xData and yData if any of them is empty.
% - If both are empty, an error is raised.
% - If yData is empty but xData is provided, it assigns xData to yData and generates indices for xData.
% - If neither is empty, xData and yData are used as provided.
function [xAdjusted, yAdjusted] = adjustInputs(xData, yData)
    if isempty(yData)
        % If yData is empty but xData is provided, assign xData to yData
        % and create default xData
        yAdjusted = xData(:);
        xAdjusted = (1:length(yAdjusted))';
    else
        xAdjusted = xData(:);
        yAdjusted = yData(:);
    end
end

% validateInputs Validates the inputs for sonification.
% This function performs several checks on xData and yData to ensure they are valid for sonification.
% - It checks if xData and yData are of equal length.
% - It verifies that xData is monotonically increasing.
function validateInputs(xData, yData)
    % Validate xData and yData length
    mustBeEqualLength(xData, yData);

    % check if xData is monotonically increasing
    mustBeMonotonicallyIncreasing(xData);
end

% mustBeValidFrequencyRange Validates the frequency range for sonification.
% This function checks if the provided frequency range is within the valid frequency limits for sonification.
% - The frequency range must be a numeric vector of length 2 and must be increasing.
% - The frequency range must fall within the valid frequency minimum and maximum defined in SonificationConstants.
function mustBeValidFrequencyRange(range)
    import audiovideo.internal.sonification.SonificationConstants
    validateattributes(range, {'numeric'}, {'vector', 'numel', 2, 'increasing'});
    if range(1) < SonificationConstants.ValidFrequencyMin || range(2) > SonificationConstants.ValidFrequencyMax
        throwAsCaller(MException('Input:InvalideFrequencyRange', message('MATLAB:audiovideo:sonification:InvalideFrequencyRange')));
    end
end

% mustBeEqualLength Checks if xData and yData are of equal length.
function mustBeEqualLength(xData, yData)
    if length(xData) ~= length(yData)
        throwAsCaller(MException('Input:DimensionMismatch', message('MATLAB:audiovideo:sonification:DimensionMismatch')));
    end
end

% mustBeMonotonicallyIncreasing Checks if xData is monotonically increasing.
function mustBeMonotonicallyIncreasing(xData)
    if any(diff(xData) <= 0)
        throwAsCaller(MException('Input:NotContinuouslyIncreasing', message('MATLAB:audiovideo:sonification:NotContinuouslyIncreasing')));
    end
end

% mustBeLogicalOrNumericBinary Checks if the Playback input is logical or numeric binary.
function mustBeLogicalOrNumericBinary(value)
    if ~(islogical(value) || (isnumeric(value) && any(value == [0, 1])))
        throwAsCaller(MException('Input:InvalidPlayback', message('MATLAB:audiovideo:sonification:InvalidPlayback')));
    end
end
