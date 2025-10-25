function codegenType = getCodegenType(className)
%This function is for internal use only. It may be removed in the future.

%GETCODEGENTYPE Get code generation type description for classes
%   CODEGENTYPE = getCodegenType(CLASSNAME) returns a coder.ClassType
%   object corresponding to objects of class CLASSNAME.

%   Copyright 2017-2023 The MathWorks, Inc.

    switch(className)
      case 'lidarScan'
        codegenType = coder.newtype('lidarScan');

        % Define variable-sized non-dependent properties
        codegenType.Properties.InternalRanges = coder.typeof(0, [inf, 1], [1, 0]);
        codegenType.Properties.InternalAngles = coder.typeof(0, [inf, 1], [1, 0]);
        codegenType.Properties.ContainsOnlyFiniteData = coder.typeof(true);

        % Ranges, Angles, Cartesian, and Count properties are all
        % dependent, so we don't need to specify them
        case 'lidarScanSingle'
        codegenType = coder.newtype('lidarScan');

        % Define variable-sized non-dependent properties
        codegenType.Properties.InternalRanges = coder.typeof(single(0), [inf, 1], [1, 0]);
        codegenType.Properties.InternalAngles = coder.typeof(single(0), [inf, 1], [1, 0]);
        codegenType.Properties.ContainsOnlyFiniteData = coder.typeof(true);

      case 'nav.algs.internal.Submap'
        codegenType = coder.newtype('nav.algs.internal.Submap');
        matType = coder.typeof(0, [inf, inf], [1, 1]);
        multiResMatType = coder.typeof(0, [inf, inf, 8], [1, 1, 1]);
        codegenType.Properties.DetailedGridMatrix = matType;
        codegenType.Properties.MultiResGridMatrices = multiResMatType; % no more than 8 levels
        codegenType.Properties.MaxRange = coder.typeof(0, 1, 0);
        codegenType.Properties.Resolution = coder.typeof(0, 1, 0);
        codegenType.Properties.MaxLevel = coder.typeof(0, 1, 0);
        codegenType.Properties.Center = coder.typeof(0, [1, 2], [0, 0]);
        codegenType.Properties.AnchorScanIndex = coder.typeof(0, 1, 0);
    end

end
