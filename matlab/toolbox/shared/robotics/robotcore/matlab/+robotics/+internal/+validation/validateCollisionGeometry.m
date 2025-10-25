function validateCollisionGeometry(geometry,varargin)
%validateCollisionGeometry Verifies collision geometry inputs
%
%   validateCollisionGeometry(GEOMETRY) verifies that the input is a single
%   valid collision geometry object.
%
%   validateCollisionGeometry(___, VARARGIN) accepts optional inputs,
%   VARARGIN, which are passed directly to validateattributes after the
%   "object", "classes", and "attributes" arguments. See validateattributes
%   for more information.
%
%   Example:
%
%       % Validate a single geometry object
%       import robotics.internal.validation.*
%       validateFcn = @validateCollisionGeometry;
%       validateFcn(collisionSphere(1));            % Scalar object
%
%       % Pass invalid object array
%       validateFcn([collisionSphere(1) collisionSphere(2)],'foo','geom');  % Throws error
%
%   See also validateattributes

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    validClasses = {'collisionBox','collisionCapsule','collisionCylinder',...
                    'collisionMesh','collisionSphere'};
    validateattributes(geometry,validClasses,{'scalar'}, varargin{:});
end
