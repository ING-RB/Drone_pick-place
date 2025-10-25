function validateCollisionGeometries(geometry,expectedSize,varargin)
%validateCollisionGeometries Verifies collision geometry inputs
%
%   validateCollisionGeometries(GEOMETRY, EXPECTEDSIZE) accepts GEOMETRY as a
%   cell-array of collision geometry objects, and EXPECTEDSIZE, a 1-by-2+
%   vector specifying the expected size of each dimension in GEOMETRY. For
%   cell-array inputs, the validator will ensure that each elements is a
%   scalar geometry object.
%
%   validateCollisionGeometries(___, VARARGIN) accepts optional inputs,
%   VARARGIN, which are passed directly to validateattributes after the
%   "object", "classes", and "attributes" arguments. See validateattributes
%   for more information.
%
%   Example:
%
%       % Validate a single geometry object
%       import robotics.internal.validation.*
%       validateFcn = @validateCollisionGeometries;
%       validateFcn({collisionSphere(1)},[1 1]);    % 1-element cell-array
%
%       % Validate multiple geometry
%       geom = {collisionBox(1,1,1) collisionBox(2,2,2)};
%       validateFcn(geom,[1 2]);                    % Fixed cell-array
%       validateFcn(geom,[1 nan]);                  % Varsize cell-array
%
%       % Pass optional function/argument names
%       validateFcn(geom,[1 2],'foo','geom');
%
%       % Pass invalid object array
%       validateFcn([geom{:}],[1 2],'foo','geom');  % Throws error
%
%   See also validateattributes

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    narginchk(2,inf);
    validateattributes(geometry,{'cell'},{'size',expectedSize},varargin{:});
    for i = 1:numel(geometry)
        robotics.internal.validation.validateCollisionGeometry(geometry{i},varargin{:});
    end
end
