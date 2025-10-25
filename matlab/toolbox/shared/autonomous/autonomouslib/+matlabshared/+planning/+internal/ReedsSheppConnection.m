classdef (Hidden) ReedsSheppConnection < matlabshared.planning.internal.EnforceScalarHandle
%This class is for internal use only. It may be removed in the future.

%ReedsSheppConnection Internal ReedsShepp connection object
%   ReedsSheppConnection is an internal
%   class representing a ReedsShepp connection.
%
%   obj = matlabshared.planning.internal.ReedsSheppConnection creates a
%   ReedsShepp connection object.
%
%   obj = matlabshared.planning.internal.ReedsSheppConnection(Name, Value)
%   additionally specifies name-value pair arguments to set properties.
%
%   ReedsSheppConnection properties:
%   MinTurningRadius    - Minimum turning radius
%   DisabledPathTypes   - Disabled path types (hidden)
%   AllPathTypes        - All path types (hidden, read-only)
%
%   ReedsSheppConnection methods:
%   connectInternal     - Connect start and goal poses using Reeds-Shepp connection
%
%   See also matlabshared.planning.internal.DubinsConnection.

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

        %ForwardCostInternal
        %   Forward cost, penalize the cost to travel in forward direction.
        %   Default: 1
        ForwardCostInternal = 1

        %ReverseCostInternal
        %   Reverse cost, penalize the to travel in reverse direction.
        %   Default: 1
        ReverseCostInternal = 1
    end

    properties (Constant)
        %AllPathTypes
        %   All possible path types of Reeds-Shepp curve.
        AllPathTypes = strtrim(matlabshared.planning.internal.ReedsSheppConnection.AllPathTypesInternal)
    end

    properties (Access = private, Constant)
        %AllPathTypesInternal Homogeneous cell array will all element of
        %same size (done for codegen)
        AllPathTypesInternal = {
            'LpSpLp    ', 'LnSnLn    ', 'RpSpRp    ', 'RnSnRn    ', 'LpSpRp    ', 'LnSnRn    ',...
            'RpSpLp    ', 'RnSnLn    ', 'LpRnLp    ', 'LnRpLn    ', 'RpLnRp    ', 'RnLpRn    ',...
            'LpRpLn    ', 'LnRnLp    ', 'RpLpRn    ', 'RnLnRp    ', 'LpRpLnRn  ', 'LnRnLpRp  ',...
            'RpLpRnLn  ', 'RnLnRpLp  ', 'LpRnLnRp  ', 'LnRpLpRn  ', 'RpLnRnLp  ',...
            'RnLpRpLn  ', 'LpRnSnLn  ', 'LnRpSpLp  ', 'RpLnSnRn  ', 'RnLpSpRp  ',...
            'LpRnSnRn  ', 'LnRpSpRp  ', 'RpLnSnLn  ', 'RnLpSpLp  ', 'LpSpRpLn  ',...
            'LnSnRnLp  ', 'RpSpLpRn  ', 'RnSnLnRp  ', 'RnSnRnLp  ', 'RpSpRpLn  ',...
            'LnSnLnRp  ', 'LpSpLpRn  ', 'LpRnSnLnRp', 'LnRpSpLpRn', 'RpLnSnRnLp',...
            'RnLpSpRpLn'}
    end

    methods
        %------------------------------------------------------------------
        function this = ReedsSheppConnection(varargin)

            [minTurningRadius, disabledPathTypes, forwardCost, reverseCost] = ...
                parseInputs(varargin{:});

            % Input validation is part of the property setters
            this.MinTurningRadius           = minTurningRadius;
            this.DisabledPathTypesInternal  = disabledPathTypes;
            this.ForwardCostInternal        = forwardCost;
            this.ReverseCostInternal        = reverseCost;
        end

        %------------------------------------------------------------------
        function set.MinTurningRadius(this, radius)

            validateattributes(radius, {'single', 'double'}, ...
                               {'real', 'nonsparse', 'positive', 'finite', 'scalar'},...
                               '', 'MinTurningRadius');

            this.MinTurningRadius = double(radius);
        end

        %------------------------------------------------------------------
        function set.ForwardCostInternal(this, forwardCost)

            validateattributes(forwardCost, {'single', 'double'}, ...
                               {'real', 'nonsparse', 'finite', 'scalar', '>=', 1}, ...
                               '', 'ForwardCost');

            this.ForwardCostInternal = double(forwardCost);
        end

        %------------------------------------------------------------------
        function set.ReverseCostInternal(this, reverseCost)

            validateattributes(reverseCost, {'single', 'double'}, ...
                               {'real', 'nonsparse', 'finite', 'scalar', '>=', 1}, ...
                               '', 'ReverseCost');

            this.ReverseCostInternal = double(reverseCost);
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
                    validatestring(disabledTypes{n}, ...
                                   this.AllPathTypes, '', 'DisabledPathTypes');
                end
            end

            % For code generation, ensure that the
            % DisabledPathTypesInternal property is variable-size (users
            % can set the property after construction)

            % At most, the property can contain 44 elements (all possible
            % path types after removing non-unique elements)
            maxNumTypes = numel(this.AllPathTypes);
            maxLenPathType = strlength(this.AllPathTypesInternal{1});
            disabledTypesVarLen = repmat({blanks(maxLenPathType)}, [1 maxNumTypes]); %#ok<NASGU>
            disabledTypesVarLen = disabledTypes;

            % Remove duplicates and assign to property.
            % This will also do partial and case-insensitive matching of
            % user inputs.
            this.DisabledPathTypesInternal = ...
                matlabshared.planning.internal.validation.uniquePathTypes(...
                    disabledTypesVarLen, this.AllPathTypes);
        end
    end

    methods (Access = {?matlabshared.planning.internal.ReedsSheppPathSegment, ...
                       ?matlab.unittest.TestCase, ?matlabshared.planning.internal.ReedsSheppConnection})
        %------------------------------------------------------------------
        function [motionLengths, motionTypes, motionCosts, motionDirections] = ...
                connectInternal(this, startPose, goalPose, varargin)
            %connectInternal Connect a start and goal using Reeds-Shepp
            %   connection.

            pathSegments = ...
                matlabshared.planning.internal.validation.connectInternalInputValidation(...
                    startPose, goalPose, varargin{:});

            nStartPoses = size(startPose, 1);
            nGoalPoses = size(goalPose, 1);

            rho             = this.MinTurningRadius;
            disabledTypes   = this.DisabledPathTypesInternal;
            forwardCost     = this.ForwardCostInternal;
            reverseCost     = this.ReverseCostInternal;

            [cost, tempMotionLengths, tempMotionTypes] = ...
                matlabshared.planning.internal.ReedsSheppBuiltins.autonomousReedsSheppSegments(...
                    startPose, goalPose, rho, ...
                    forwardCost, reverseCost, pathSegments, disabledTypes);

            nRows = 1;
            %enabledIdx is array of indices for enabled paths  if
            %pathsegments type is "all" otherwise it will store 1 for "optimal"
            %pathsegments.
            enabledIdx = 1;
            if strcmp(pathSegments, 'all')
                nRows = numel(this.AllPathTypes);

                % Because of codegen, convert the strings into some hash
                % value
                hAllPathTypes = zeros(1, nRows);
                for idAll = 1:nRows
                    hAllPathTypes(idAll) = ...
                        matlabshared.planning.internal.getHashValueForCharVec(this.AllPathTypesInternal{idAll});
                end

                hdisabledTypes = zeros(1, size(disabledTypes, 2));
                if ~isempty(disabledTypes)
                    for idDis = 1:numel(disabledTypes)
                        hdisabledTypes(idDis) = ...
                            matlabshared.planning.internal.getHashValueForCharVec(this.DisabledPathTypesInternal{idDis});
                    end
                end

                [~, enabledIdx] = setdiff(hAllPathTypes, hdisabledTypes, 'stable');
                enabledIdx = sort(enabledIdx);
            end

            nCols = max([nStartPoses, nGoalPoses]);

            % Extract the path cost
            motionCosts                 = nan(nRows, nCols);
            infeasiblePathIDX           = (cost == inf);
            cost(infeasiblePathIDX)     = nan;
            motionCosts(enabledIdx, :)  = cost;

            % Extract motion lengths
            motionDirections                        = ones(5, nRows, nCols);
            motionDirections(:, enabledIdx, :)      = sign(tempMotionLengths);
            motionDirections(motionDirections == 0) = 1;
            motionDirections(:, infeasiblePathIDX)  = 1;

            % Extract motion lengths
            motionLengths                           = nan(5, nRows, nCols);
            motionLengths(:, enabledIdx, :)         = abs(tempMotionLengths);
            motionLengths(:, infeasiblePathIDX)     = nan;

            % Reeds-Shepp motion types
            motionTypesReedsShepp = 'LRSN';

            % Extract motion types
            motionTypes = cell(5,nRows,nCols);
                        
            for idx = 1:5           % 5 is length of Reeds-Shepp motion type.
                for idz = 1:nCols
                    enabledPathInd = 1;
                    for idy = 1:nRows
                        if any(idy == enabledIdx)
                            motionTypes{idx, idy, idz} = ...
                                motionTypesReedsShepp(tempMotionTypes(idx, enabledPathInd, idz) + 1); % Added 1 in tempMotionTypes(idx, enabledPathInd, idz)
                            %because in c++ code for motion types
                            %mappings are 'L' to 0, 'R' to 1, 'S' to 2 and
                            %'N' to 3 but in MATLAB motion type mappings
                            %are 'L' to 1, 'R' to 2, 'S' to 3 and 'N' to 4 
                            %(see variable "motionTypesReedsShepp"). And this 
                            %happens because in MATLAB, indexing starts from 1 instead of 0.
                            enabledPathInd = enabledPathInd + 1;
                        else
                            motionTypes{idx, idy, idz} = blanks(0);
                        end
                    end
                end
            end
        end
    end
    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        %Marking properties as 'soft Nontunable' indicates to Coder that 
        % the property should be made compile-time Constant if possible
            result = {'DisabledPathTypesInternal'};
        end
    end
end

%--------------------------------------------------------------------------
function [minTurningRadius, disabledPathTypes, forwardCost, reverseCost] = ...
        parseInputs(varargin)

    parser = matlabshared.autonomous.core.internal.NameValueParser(...
        {'MinTurningRadius', 'DisabledPathTypes', 'ForwardCost', 'ReverseCost'}, ...
        {1, {}, 1, 1});

    parse(parser, varargin{:});

    minTurningRadius    = parameterValue(parser, 'MinTurningRadius');
    disabledPathTypes   = parameterValue(parser, 'DisabledPathTypes');
    forwardCost         = parameterValue(parser, 'ForwardCost');
    reverseCost         = parameterValue(parser, 'ReverseCost');
end
