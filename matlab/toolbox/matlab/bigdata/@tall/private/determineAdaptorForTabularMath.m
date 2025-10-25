function [outAdaptor, ta, tb] = determineAdaptorForTabularMath(adaptorFcn,methodName,ta,tb)
% Helper to work out the output adaptors for tabular maths. This may
% need to recurse back into itself. At least one of TA, TB must be a table
% or timetable. ADAPTORFCN is the operation-specific function for
% determining output type of a single table variable.

% Copyright 2022-2023 The MathWorks, Inc.

% Deal with the unary case
if nargin<4
    assert(istabular(ta), "determineAdaptorForTabularMath called without a table!")
    outAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(ta);
    n = width(outAdaptor);
    for ii=1:n
        varA = iGetVar(ta, ii);
        outVarAdap = iCallAdaptorFcn(adaptorFcn, methodName, varA);
        outAdaptor = outAdaptor.setVariableAdaptor(ii, copyTallSize(outVarAdap, outAdaptor));
    end
    return;
end

% Now the binary case. Here we need to cope with either or both inputs
% being tables.
if istabular(ta)
    outAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(ta);
    n = width(outAdaptor);
    if istabular(tb)
        % For two tables the variables must exactly match
        bAdap = matlab.bigdata.internal.adaptors.getAdaptor(tb);
        if ~isequal(getVariableNames(bAdap), getVariableNames(outAdaptor))
            error(message('MATLAB:table:math:DifferentVars'));
        end

        % Now, ensure that we have all the tabular properties we expected.
        defaultType = "double";
        defaultSize = [1 1];
        aSample = buildSample(outAdaptor, defaultType, defaultSize);
        bSample = buildSample(bAdap, defaultType, defaultSize);
        fcn = str2func(methodName);
        outProto = fcn(aSample, bSample);
        outAdaptor = copyTallSize(matlab.bigdata.internal.adaptors.getAdaptor(outProto), outAdaptor);

        % Go through corresponding variables from the two tables
        % performing the addition.
        for ii=1:n
            varA = iGetVar(ta, ii);
            varB = iGetVar(tb, ii);
            outVarAdap = iCallAdaptorFcn(adaptorFcn, methodName, varA, varB);
            outAdaptor = outAdaptor.setVariableAdaptor(ii, copyTallSize(outVarAdap, outAdaptor));
        end

    else
        % Table + array
        % Go through variables combining with the non-tabular array.
        for ii=1:n
            varA = iGetVar(ta, ii);
            outVarAdap = iCallAdaptorFcn(adaptorFcn, methodName, varA, tb);
            outAdaptor = outAdaptor.setVariableAdaptor(ii, copyTallSize(outVarAdap, outAdaptor));
        end

    end
else
    % Array + table
    outAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(tb);
    n = width(outAdaptor);
    % Go through variables combining with the non-tabular array.
    for ii=1:n
        varB = iGetVar(tb, ii);
        outVarAdap = iCallAdaptorFcn(adaptorFcn, methodName, ta, varB);
        outAdaptor = outAdaptor.setVariableAdaptor(ii, copyTallSize(outVarAdap, outAdaptor));
    end

end

end

function v = iGetVar(tt, idx)
% Helper to extract one variable from a tall (time)table
v = subsref(tt, substruct('{}', {':', idx}));
end

function outVarAdapt = iCallAdaptorFcn(adaptorFcn, methodName, varargin)
try
    outVarAdapt = adaptorFcn(varargin{:});
catch causeErr
    baseError = MException("MATLAB:bigdata:array:TabularMathInvalidType", ...
        message("MATLAB:bigdata:array:TabularMathInvalidType", methodName));

    % Create BigDataException to remove internal stack
    causeErr = matlab.bigdata.BigDataException.build(causeErr);
    err = addCause(baseError, causeErr);
    throwAsCaller(err);
end
end