function obj = parseSpatialMatrixInput(varargin)
%This method is for internal use only. It may be removed in the future.

%parseSpatialMatrixInput Parses spatial matrix object inputs
%   OBJ = parseSpatialMatrixInput(VARARGIN) parses the arguments in
%   VARARGIN by finding the first spatial matrix object, e.g. object of
%   type "se3", and returning it in OBJ. The function also validates that
%   all other inputs in VARARGIN are of the same concrete type.
%   If any of the other inputs is of a different type, an error is thrown.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% First SpatialMatrixBase input defines the required format. Since this
% method is called on the object, at least one of the elements is of that type.
% In most cases, it will be varargin{1}, but it could be different, e.g.
% when calling cat(1,5,se3).

    n = numel(varargin);

    % Pre-allocate the type string, so Coder knows it has a
    % fixed-length of 3. The actual type, e.g. 'se3' will be
    % assigned in the next for loop.
    expectedType = blanks(3); %#ok<NASGU>

    % Find expected type
    obj = findFirstSpatialMatrix(varargin{:});
    expectedType = class(obj);

    for i = 1:n
        coder.internal.assert(isa(varargin{i}, expectedType), ...
                              "shared_spatialmath:matobj:AllTypeMismatch", expectedType, class(varargin{i}));
    end

end
