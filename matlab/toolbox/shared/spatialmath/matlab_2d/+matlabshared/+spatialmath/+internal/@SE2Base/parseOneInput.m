function [M,MInd] = parseOneInput(arg)
%This method is for internal use only. It may be removed in the future.

%PARSEONEINPUT Parse the se2 constructor with one input argument
%   Possible call syntax parsed here
%   - se2([])
%   - se2(RM)
%   - se2(SO2OBJ)
%   - se2(SE2OBJ)

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    d = matlabshared.spatialmath.internal.SE2Base.Dim;

    if isa(arg, "float") && coder.internal.isConstFalse(isequal(size(arg), [0 0]))
        if size(arg,1) == d
            % se2(TF) - constructor with 3x3xN matrix
            robotics.internal.validation.validateHomogeneousTransform2D(arg, "se2", "TF");
            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(arg);
        else
            % se2(R) - constructor with 2x2xN rotation matrix
            robotics.internal.validation.validateRotationMatrix2D(arg, "se2", "R");
            tf = robotics.internal.rotm2tform(arg);
            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(tf);
        end

    elseif isa(arg, "float") && coder.internal.isConstTrue(isequal(size(arg), [0 0]))
        % se2([])
        % This handles the explicit case of [] or known
        % (codegen constant) 0x0.
        M = zeros(d,d,0,"like",arg);
        MInd = zeros(size(arg),"like",arg);


    elseif isa(arg, "so2")
        % se2(SO2obj) - constructor with so2 object
        % Directly convert the underlying data. No extra
        % validation is needed.

        tf = robotics.internal.rotm2tform(arg.rotm);
        [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(tf, size(arg));

    elseif isa(arg, "matlabshared.spatialmath.internal.SE2Base")
        % se2(SE2obj) - copy constructor
        M = arg.M;
        MInd = arg.MInd;

    else
        % Use errorIf to ensure compile-time error
        coder.internal.errorIf(true, "shared_spatialmath:se2:InvalidFirstArg");
    end

end
