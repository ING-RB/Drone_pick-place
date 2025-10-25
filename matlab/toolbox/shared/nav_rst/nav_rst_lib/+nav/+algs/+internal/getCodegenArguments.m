function args = getCodegenArguments(fcnName)
%This function is for internal use only. It may be removed in the future.

%GETCODEGENARGUMENTS Get code generation arguments for a given function
%   ARGS = getCodegenArguments(FCNNAME) returns a cell array with size and
%   type information for inputs to a function FCNNAME. The output ARGS is
%   used as a value of the codegen name-value pair 'args'.
%   This function is invoked by the create_* functions that build
%   customer-facing MEX files for internal functionality.

%   Copyright 2014-2021 The MathWorks, Inc.

    switch fcnName
      case 'aStar'
        args = {...
            coder.typeof(0,[1 1]),...
            coder.typeof(0,[1 1]), ...
            coder.typeof(0,[2 Inf], [0 1]), ...
            coder.typeof(0,[Inf Inf], [1 1])};
      case 'calculateRanges'
        args = {...
            coder.typeof(0, [1 3], [0 0]), ...          % robot pose
            coder.typeof(0, [Inf 1], [1 0]), ...        % angles
            coder.typeof(0, [1 1], [0 0]), ...          % maxRange
            coder.typeof(true, [Inf Inf], [1 1]), ...   % grid
            coder.typeof(0, [1 2], [0 0]), ...          % gridSize
            coder.typeof(0, [1 1], [0 0]), ...          % resolution
            coder.typeof(0, [1 2], [0 0]), ...          % gridLocationInWorld
               };
      case 'inflate_int16'
        args = {coder.typeof(int16(1),[Inf Inf]) coder.typeof(true,[Inf Inf])};
      case 'inflate_logical'
        args = {coder.typeof(true,[Inf Inf]) coder.typeof(true,[Inf Inf])};
      case 'intLogoddsToProb'
        args = {coder.typeof(single(0),[65536 1])...
                coder.typeof(int16(0),[1 65536])...
                coder.typeof(int16(0),[Inf Inf])};
      case 'motionModelUpdate'
        args = {coder.typeof(0, [Inf 3]) coder.typeof(0, [1 3]) ...
                coder.typeof(0, [1 3]) coder.typeof(0, [1 4])};
      case 'raycast'
        args = {coder.typeof(0,[1 2]) coder.typeof(0,[inf 2],[1 0]) ...
                coder.typeof(true,[Inf Inf]) coder.typeof(0,[1 1]) ...
                coder.typeof(0,[1 2])};
      case 'raycastCells'
        args = {coder.typeof(0,[1 2]) coder.typeof(0,[inf 2],[1 0]) ...
                coder.typeof(0,[1 1]) coder.typeof(0,[1 1]) coder.typeof(0,[1 1]) ...
                coder.typeof(0,[1 2]) coder.typeof(true,[inf 1],[1 0])};
      case 'buildNDT'
        args = {...
            coder.typeof(0, [Inf 2], [1 0]), ...                % laserScan
            coder.typeof(0, 1, 0), ...                          % binSize
               };
      case 'objectiveNDT'
        args = {...
            coder.typeof(0, [Inf 2], [1 0]), ...          % laserScan
            coder.typeof(0, [1 3], [0 0]), ...            % laserTrans
            coder.typeof(0, [4 Inf], [0 1]), ...          % xbins
            coder.typeof(0, [4 Inf], [0 1]), ...          % ybins
            coder.typeof(0, [2 Inf 4], [0 1 0]), ...      % p
            coder.typeof(0, [2 2 Inf 4], [0 0 1 0]), ...  % sigma
            coder.typeof(0, [2 2 Inf 4], [0 0 1 0]), ...  % sigmaInv
               };
      case 'matchScans'
        args = {...
            nav.algs.internal.getCodegenType('lidarScan'), ... % referenceScan
            nav.algs.internal.getCodegenType('lidarScan'), ... % currentScan
            coder.typeof(0, [3,1], [0, 0]), ...                     % initialPose
            coder.typeof(0, 1, 0), ...          % cellSize
            coder.typeof(0, 1, 0), ...          % maxIterations
            coder.typeof(0, 1, 0), ...          % scoreTolerance
               };
      case 'matchScansGrid'
        args = {...
            nav.algs.internal.getCodegenType('lidarScan'), ... % currentScan
            nav.algs.internal.getCodegenType('lidarScan'), ... % referenceScan
            coder.typeof(0, 1, 0), ...                              % initialPoseAvailable
            coder.typeof(0, [3,1], [0, 0]), ...                     % initialPose
            coder.typeof(0, 1, 0), ...          % maxRange
            coder.typeof(0, 1, 0), ...          % resolution
            coder.typeof(0, [1 2], [0 0]), ...                      % linSearchRange
            coder.typeof(0, 1, 0), ...                              % angSearchRange
            coder.typeof(0, 1, 0), ...          % maxLevel
            coder.typeof(true, 1, 0), ...       % computeCovariance
               };
      case 'matchScansGridSubmap'
        args = {...
            nav.algs.internal.getCodegenType('lidarScan'), ... % currentScan
            nav.algs.internal.getCodegenType('nav.algs.internal.Submap'), ...   % referenceSubmap
            coder.typeof(0, 1, 0), ...                              % initialPoseAvailable
            coder.typeof(0, [3,1], [0, 0]), ...                     % initialPose
            coder.typeof(0, [1 2], [0 0]), ...                      % linSearchRange
            coder.typeof(0, 1, 0), ...                              % angSearchRange
               };
      case 'createSubmap'
        scanType = nav.algs.internal.getCodegenType('lidarScan');
        args = {...
            coder.typeof({scanType}, [1, inf], [0, 1]), ...         % scans
            coder.typeof(0, [1, inf], [0, 1]), ...                  % scanIndices
            coder.typeof(0, [inf 3], [1 0]), ...                    % poses
            coder.typeof(0, 1, 0), ...                              % anchorIndex
            coder.typeof(0, 1, 0), ...                              % resolution
            coder.typeof(0, 1, 0), ...                              % maxRange
            coder.typeof(0, 1, 0), ...                              % maxLevel
               };
      otherwise
        assert(false, ['Switch option ' fcnName ' not recognized.']);
    end
end
