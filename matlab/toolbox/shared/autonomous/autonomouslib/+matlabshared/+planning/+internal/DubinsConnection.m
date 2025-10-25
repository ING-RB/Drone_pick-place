classdef (Hidden) DubinsConnection < matlabshared.planning.internal.EnforceScalarHandle
%This class is for internal use only. It may be removed in the future.

%DubinsConnection Internal Dubins connection object
%   matlabshared.planning.internal.DubinsConnection is an internal class
%   representing a Dubins connection.
%
%   obj = matlabshared.planning.internal.DubinsConnection creates a Dubins
%   connection object.
%
%   obj = matlabshared.planning.internal.DubinsConnection(Name, Value) additionally
%   specifies name-value pair arguments to set properties.
%
%   matlabshared.planning.internal.Dubins properties:
%   MinTurningRadius    - Minimum turning radius
%   DisabledPathTypes   - Disabled path types (hidden)
%   AllPathTypes        - All path types (hidden, read-only)
%
%   matlabshared.planning.internal.DubinsConnection methods:
%   connectInternal     - Connect start and goal poses using Dubins connection
%
%   See also matlabshared.planning.internal.ReedsSheppConnection.

% Copyright 2018-2019 The MathWorks, Inc.

%#codegen

    properties
        %MinTurningRadius
        %   Minimum turning radius, specified in world units. This
        %   corresponds to the turning radius of the circle at maximum
        %   steer.
        MinTurningRadius = 1
    end

    properties (Access = protected)
        %DisabledPathTypesInternal
        %   Internal representation of disabled path types
        DisabledPathTypesInternal
    end

    properties (Constant)
        %AllPathTypes
        %   All possible path types of Dubins curve.
        AllPathTypes = {'LSL' 'LSR' 'RSL' 'RSR' 'RLR' 'LRL'};
    end

    methods
        %------------------------------------------------------------------
        function this = DubinsConnection(varargin)

            [minTurningRadius, disabledPathTypes] = parseInputs(varargin{:});

            % Input validation is part of the property setters
            this.MinTurningRadius           = minTurningRadius;
            this.DisabledPathTypesInternal  = disabledPathTypes;
        end

        %------------------------------------------------------------------
        function set.MinTurningRadius(this, radius)

            validateattributes(radius, {'single', 'double'}, ...
                               {'real', 'nonsparse', 'positive', 'finite', 'scalar'},...
                               '', 'MinTurningRadius');

            this.MinTurningRadius = double(radius);
        end

        %------------------------------------------------------------------
        function set.DisabledPathTypesInternal(this, disabledTypes)

            if isempty(disabledTypes)
                validateattributes(disabledTypes, {'cell', 'string'},{});
            else

                % Ensure that string input is always a cellstr
                if isstring(disabledTypes)
                    disabledTypes = cellstr(disabledTypes);
                end

                % Keep the string validation for an informative error message
                validateattributes(disabledTypes, {'cell', 'string'}, {'vector'});

                % Confirm that all cell array inputs are strings
                coder.internal.errorIf(~iscellstr(disabledTypes), ...
                                       'shared_autonomous:validation:CellArrayStringError', 'DisabledPathTypes');

                for n = 1 : numel(disabledTypes)
                    validatestring(disabledTypes{n}, this.AllPathTypes, ...
                                   '', 'DisabledPathTypes');

                    % Convert to uppercase
                    disabledTypes{n} = upper(disabledTypes{n});
                end
            end

            % For code generation, ensure that the
            % DisabledPathTypesInternal property is variable-size (users
            % can set the property after construction)

            % At most, the property can contain 6 elements (all possible
            % path types after removing non-unique elements)
            maxNumTypes = numel(this.AllPathTypes);
            maxLenPathType = strlength(this.AllPathTypes{1});
            disabledTypesVarLen = repmat({blanks(maxLenPathType)}, [1 maxNumTypes]); %#ok<NASGU>
            disabledTypesVarLen = disabledTypes;
            coder.varsize('disabledTypesVarLen',[1 maxNumTypes],[1 1]);

            % Remove duplicates and assign to property.
            % This will also do partial and case-insensitive matching of
            % user inputs.
            this.DisabledPathTypesInternal = ...
                matlabshared.planning.internal.validation.uniquePathTypes(...
                    disabledTypesVarLen, this.AllPathTypes);
        end
    end

    methods (Access = {?matlabshared.planning.internal.DubinsPathSegment,...
                       ?matlab.unittest.TestCase, ?matlabshared.planning.internal.DubinsConnection, ?uavDubinsConnection})
        %------------------------------------------------------------------
        function [motionLengths, motionTypes, cost] = ...
                connectInternal(this, startPose, goalPose, varargin)
            %connectInternal Connect a start and goal using Dubins connection

            pathSegments = ...
                matlabshared.planning.internal.validation.connectInternalInputValidation(...
                    startPose, goalPose, varargin{:});

            nStartPoses = size(startPose, 1);
            nGoalPoses = size(goalPose, 1);

            rho             = this.MinTurningRadius;
            disabledTypes   = this.DisabledPathTypesInternal;

            [cost, motionLengths, tempMotionTypes] = ...
                matlabshared.planning.internal.DubinsBuiltins.autonomousDubinsSegments(...
                    startPose, goalPose, rho, pathSegments, disabledTypes);

            nRows = 1;
            enabledIdx = 1;
            if strcmp(pathSegments, 'all')
                nRows = numel(this.AllPathTypes);

                % Because of codegen, convert the strings into some hash
                % value
                hAllPathTypes = zeros(1, size(this.AllPathTypes, 2));
                for idAll = 1:numel(this.AllPathTypes)
                    hAllPathTypes(idAll) = ...
                        matlabshared.planning.internal.getHashValueForCharVec(this.AllPathTypes{idAll});
                end

                hdisabledTypes = zeros(1, size(disabledTypes, 2));
                if ~isempty(disabledTypes)
                    for idDis = 1:numel(disabledTypes)
                        hdisabledTypes(idDis) = ...
                            matlabshared.planning.internal.getHashValueForCharVec(disabledTypes{idDis});
                    end
                end

                [~, enabledIdx] = setdiff(hAllPathTypes, hdisabledTypes, 'stable');
                enabledIdx = sort(enabledIdx);
            end

            nCols = max([nStartPoses, nGoalPoses]);

            % Dubins motion types
            motionTypesDubins = 'LRS';

            % Extract motion types
            motionTypes = cell(3,nRows,nCols);

            for idx = 1:3
                for idy = 1:nRows
                    for idz = 1:nCols
                        if any(idy == enabledIdx)
                            motionTypes{idx, idy, idz} = motionTypesDubins(tempMotionTypes(idx, idy, idz) + 1);
                        else
                            motionTypes{idx, idy, idz} = blanks(0);
                        end
                    end
                end
            end

        end
    end
end

%--------------------------------------------------------------------------
function [minTurningRadius, disabledPathTypes]= parseInputs(varargin)

    parser = matlabshared.autonomous.core.internal.NameValueParser(...
        {'MinTurningRadius', 'DisabledPathTypes'}, {1, {}});

    parse(parser, varargin{:});

    minTurningRadius    = parameterValue(parser, 'MinTurningRadius');
    disabledPathTypes   = parameterValue(parser, 'DisabledPathTypes');

end
