function y = cat(dim, varargin)
%CAT Concatenate arrays
%   CAT(DIM,A,B) concatenates the arrays A and B along
%   the dimension DIM.
%
%   B = CAT(DIM,A1,A2,A3,A4,...) concatenates the input
%   arrays A1, A2, etc. along the dimension DIM.
%
%   All inputs need to be of the same type.
%
%   See also horzcat, vertcat.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Validate
    coder.internal.assert(isa(dim, "numeric"), "shared_spatialmath:matobj:CatDimNotNumeric");
    validateattributes(dim, "numeric", {'real', 'positive', ...
                                        'integer', 'scalar', 'finite'}, "cat", "dim");

    % Wrap into a call with coder.const to ensure compile time computation
    if coder.const(~anyCell(varargin{:}))
        % No cell arrays. Normal se & so concatenation
        % Make sure all elements are of the same type
        matlabshared.spatialmath.internal.SpatialMatrixBase.parseSpatialMatrixInput(varargin{:});

        n = numel(varargin);
        d = varargin{1}.Dim;

        if n == 1
            % Return right away if only a single input is provided.
            y = varargin{1};
            return;
        end

        % We have at least 2 inputs
        T1 = varargin{1};
        T2 = varargin{2};

        % Do a concatenation of the indices. Since we need index tuples
        % (which matrices from each object array to concatenate),
        % we use a little trick: we use a complex
        % number for the second index. The concatenation will then be complex,
        % but each element will have index1 in the real part and index2 in the
        % imaginary part.
        % This line will fail if concatenation is not possible (incompatible
        % input sizes) and throws a reasonable error message.
        catTuples = cat(dim, T1.MInd, T2.MInd*1i);

        % Create numeric matrix array and new indices
        [catM, catMInd] = concatenateFromIndices(catTuples, d, T1.M, T2.M);

        % Do the concatenation step-by-step for the remaining inputs.
        for i = 3:n
            % Declare variables variable sized, since they will change in the
            % loop.
            coder.varsize("catM")
            coder.varsize("catMInd")

            T2 = varargin{i};
            catTuples = cat(dim, catMInd, T2.MInd*1i);
            [catM, catMInd] = concatenateFromIndices(catTuples, d, catM, T2.M);
        end

        % Create object array from numeric matrix array
        y = varargin{1}.fromMatrix(catM, size(catMInd));
    else
        % Input contains cell arrays. Base cat handles it.
        N = numel(varargin);
        v = cell(1,N);
        for ii=1:N
            if isa(varargin{ii}, 'matlabshared.spatialmath.internal.SpatialMatrixBase')
                % Wrap in a cell
                v{ii} = {varargin{ii}};
            else
                v{ii} = varargin{ii};
            end
        end
        y = cat(dim, v{:});
    end
end
