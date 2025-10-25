function obj = parenAssignSim(obj, rhs, className, varargin)
%This method  is for internal use only. It may be removed in the future.

%parenAssignSim Invoked when assigning data into the object array during simulation
%   For performance reasons, each of the concrete classes (se3, so3, ...)
%   has separate parenAssign implementations for sim vs. codegen. The
%   simulation implementation is agnostic to the type of object, so we can
%   single-source it here.

%   Copyright 2022-2024 The MathWorks, Inc.


    if (isa(obj,"double") && isempty(obj))
        % Building a new array. obj is unassigned.
        % e.g. S(3,3) = se3
        % This will not work in code generation.
        if isscalar(varargin)
            varargin = [ {1},varargin ];  % Single index makes a row vector
        end

        % Evaluate input to get right sizing
        a(varargin{:}) = uint8(0);

        % Create the right number of identity transforms to initialize new
        % object array.
        tform = repmat(eye(rhs.Dim,underlyingType(rhs)),1,1,numel(a));
        obj = rhs.fromMatrix(tform, size(a));

        % Use standard assignment for the rhs
        % Note that you cannot call obj(varargin{:}) here to avoid infinite
        % recursion into parenAssign.
        indices = obj.MInd(varargin{:});
        obj.M(:,:,indices) = rhs.M;
    elseif isempty(rhs)
        % Deletion of element, e.g. S(2) = []
        % This will not work in code generation.
        MInd = obj.MInd;
        indices = MInd(varargin{:});

        % Delete actual data and indices (to get right shape)
        obj.M(:,:,indices) = [];
        MInd(varargin{:}) = [];
        obj.MInd = obj.newIndices(size(MInd));
    else
        % This is probably the most commonly called branch. Standard indexing.
        coder.internal.assert(isa(rhs,className), "shared_spatialmath:matobj:RHSAssign", className, class(rhs));

        mind = obj.MInd;
        mind(varargin{:}) = 0;
        if ~isequal(size(mind), size(obj.MInd))
            % Array size changed. For example, this can happen when
            % indexing with end+1 or far beyond the end of the current
            % array. This will not work in code generation.
            origM = obj.M;
            origMIndSize = size(obj.MInd);

            % Cannot use newIndices method here, since obj.M doesn't
            % have right size yet.
            obj.MInd = cast(reshape(1:numel(mind), size(mind)), "like", obj.M);

            % Initialize the resized array with identity transforms. The
            % original data in M is stored in origM. We can't leave the
            % data in place, since the linear indexing might change when
            % the array size changes.
            identTform = repmat(eye(rhs.Dim,underlyingType(rhs)),1,1,numel(mind));
            obj.M = identTform;

            % Place original elements in the right location in the "upper
            % left" (multi-dimensional) corner. Assign elements 1:N for
            % each dimension in the original array.
            sizes = cell(1,numel(origMIndSize));
            for i = 1:numel(origMIndSize)
                sizes{i} = 1:origMIndSize(i);
            end
            newIndices = obj.MInd(sizes{:});
            obj.M(:,:,newIndices) = origM;
        end

        % Now that the size of obj is accurate and obj.M and obj.MInd are
        % initialized correctly, actually assign the RHS.
        indices = obj.MInd(varargin{:});
        sM3 = size(rhs.M,3);
        lInd = numel(indices);
        if lInd ~= sM3 && sM3 == 1
            % Do scalar expansion of right side if same matrix is going
            % into several indices.
            obj.M(:,:,indices) = repmat(rhs.M,1,1,lInd);
        else
            obj.M(:,:,indices) = rhs.M;
        end
    end

end
