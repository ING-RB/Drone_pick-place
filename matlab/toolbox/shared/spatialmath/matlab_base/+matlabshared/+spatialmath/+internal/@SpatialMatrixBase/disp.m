function disp(obj, varargin)
%DISP Display array of transformations or rotations

%   Copyright 2022-2024 The MathWorks, Inc.

    if nargin < 2
        name = inputname(1);
    else
        name = varargin{1};
    end

    matrixDisplay(obj, name);
end


function matrixDisplay(obj, varname)
%matrixDisplay Display matrices contained in spatial matrix object
%   Based on the spec, display the matrices in linear order, with the array
%   index called out in the header of each matrix. For example:
%   >> T3 = se3(R_row)
%   T3 =
%      1x2 se3 array
%   T3(1,1) =
%      -0.2019   -0.6395   -0.7418         0
%       0.9684   -0.2437   -0.0535         0
%      -0.1466   -0.7292    0.6684         0
%            0         0         0         1
%   T3(1,2) =
%      -0.7795   -0.3760   -0.5010         0
%      ...

    if isempty(obj)
        return;
    end

    % The object has at least 1 matrix to display

    % Is format loose or compact
    isLoose = strcmp(matlab.internal.display.formatSpacing,'loose');
    if isLoose
        looseline = '\n';
    else
        looseline = '';
    end

    % For each matrix in array
    for i = 1:numel(obj)
        M = obj.M(:,:,i);

        % Find index in multi-dimensional array
        [idxCell{1:numel(size(obj))}] = ind2sub(size(obj), i);
        idx = [idxCell{:}];

        if length(obj) > 1
            % Print the matrix index for non-scalar objects
            % Precede and succeed with looseline to match format of
            % multi-dimensional numeric matrix printout.
            fprintf(looseline);
            fprintf('%s(%s) = \n', varname, string(idx).join(","));
            fprintf(looseline);
        end

        % Print matrix. Use standard numeric disp.
        % This will automatically handle formatting for long/short/etc. and
        % sign alignment.
        disp(M);
    end
end
