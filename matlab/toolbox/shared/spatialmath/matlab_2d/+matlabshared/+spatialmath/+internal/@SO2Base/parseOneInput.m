function [M,MInd] = parseOneInput(arg)
%This method is for internal use only. It may be removed in the future.

%PARSEONEINPUT Parse the so2 constructor with one input argument
%   Possible call syntax parsed here
%   - so2([])
%   - so2(RM)
%   - so2(SO2OBJ)

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isa(arg, "float") && coder.internal.isConstFalse(isequal(size(arg), [0 0]))
        % so2(RM) - constructor with 2x2xN matrix
        robotics.internal.validation.validateRotationMatrix2D(arg, "so2", "RM");
        [M,MInd] = matlabshared.spatialmath.internal.SOBase.rawDataFromRotm(arg);

    elseif isa(arg, "float") && coder.internal.isConstTrue(isequal(size(arg), [0 0]))
        % so2([])
        % This handles the explicit case of [] or known
        % (codegen constant) 0x0.
        M = zeros(2,2,0,"like",arg);
        MInd = zeros(size(arg),"like",arg);

    elseif isa(arg, "matlabshared.spatialmath.internal.SO2Base")
        % so2(SO2obj) - copy constructor
        M = arg.M;
        MInd = arg.MInd;

    else
        % Use errorIf to ensure compile-time error
        coder.internal.errorIf(true, "shared_spatialmath:so2:InvalidFirstArg");
    end

end
