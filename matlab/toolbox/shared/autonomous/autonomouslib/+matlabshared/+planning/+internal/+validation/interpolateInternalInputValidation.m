function samples = interpolateInternalInputValidation(...
    motionLengths, totalLength, varargin)
    %This function is for internal use only. It may be removed in the future.

    %interpolateInternalInputValidation
    %   Utility function to validate interpolateInternal inputs. This code has
    %   been used by matlabshared.planning.internal.DubinsPathSegments &
    %   matlabshared.planning.internal.ReedsSheppSegments.
    %
    %   Syntaxes:
    %   samples = interpolateInternalInputValidation(motionLengths, len)
    %
    %   samples = interpolateInternalInputValidation(motionLengths, len, samples)
    %
    %   samples = interpolateInternalInputValidation(motionLengths, len, samples, excludeStart)
    %
    %   samples = interpolateInternalInputValidation(motionLengths, len, samples, excludeStart, addTransitions)
    %   Inputs
    %   ------
    %   motionLengths  - Length of each motion along segment
    %   totalLength    - Total length of segment
    %   excludeStart   - True or false, indicating whether sample corresponding
    %                    to start should be returned. If this input is not
    %                    provided, a default of false is used.
    %   addTransitions - True or false, indicating whether to add transition
    %                    lengths. A default of true is used.
    %
    % Copyright 2018 The MathWorks, Inc.

    %#codegen

    samples     = zeros(0,1);

    if nargin >= 3

        if isempty(varargin{1})
            validateattributes(varargin{1}, {'single', 'double'}, ...
                               {'nonsparse'}, 'interpolate', 'samples');
        else
            validateattributes(varargin{1}, {'single', 'double'}, ...
                               {'vector', 'finite', 'real', 'nonsparse', 'nonnegative',...
                                'nondecreasing', '<=', totalLength}, 'interpolate', 'samples');
        end
        samples = double(varargin{1}(:));
    end

    % Add start if needed
    if nargin<4 || ~varargin{2}
        samples = [0; samples];
    end

    % Add transition lengths and take unique samples
    if nargin<5 || varargin{3}
        samples = [samples(:); cumsum(motionLengths(:))];
    end

    samples = unique(samples, 'sorted');
end
