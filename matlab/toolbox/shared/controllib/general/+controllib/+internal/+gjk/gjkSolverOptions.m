function options = gjkSolverOptions(type0)
% GJKSOLVEROPTIONS  Creates a default set of options for checkCollision
% algorithm.
%
%   OPTIONS = GJKSOLVEROPTIONS() creates a structure, options, containing
%   default values for options used in GJKSOLVEROPTIONS.
%
% Output argument "options" is a structure with the following fields:
%
%                  MaxIter: Maximum number of iterations to run. Value must
%                           be positive integer and less than 36.
%
%                  Display: Display terminal parameters. Display parameter
%                           is either 'none', 'iter', or 'final'.
%
%                   AbsTol: Tolerance used to verify if geometries are in
%                           contact. Value must be a positive scalar.
%                           Degault value is 1e-6
%
%                   RelTol: Tolerance used to to mitigate aboslute
%                           rounding error. Value must be a positive
%                           scalar. Default value is 1.0e-12.
%
%      ShowShapesCatersian: Plot the two shapes on Cartesian coordinate
%                           system . Default value is false.
%
%   ShowConfigurationSpace: Plot the two shapes on Configuration Space.
%                           Default value is false.
%
% see also: controllib.internal.gjk.Base2d.checkCollision and
% controllib.internal.gjk.Base3d.checkCollision

%#codegen
narginchk(0,1);
if nargin==0
    type0 = 'double';
end

% initialize with correct data type
ONE = ones(1,1,type0);
options = struct('MaxIterations', int32(36),  ...
                 'AbsTol', cast(1e-14,type0), ... eps(ONE)*(1e2), ...
                 'RelTol', cast(1e-12,type0), ... ONE*1e-6, ...
                 'ShowShapesCatersian', false,...
                 'ShowConfigurationSpace', false, ...
                 'Display', 'none');