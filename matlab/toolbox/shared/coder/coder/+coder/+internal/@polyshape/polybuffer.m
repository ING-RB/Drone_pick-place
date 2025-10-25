function PG = polybuffer(pshape, bufferDis, varargin)
%MATLAB Code Generation Library Function
% POLYBUFFER Place a buffer around a polyshape

% Copyright 2016-2024 The MathWorks, Inc.

%#codegen

narginchk(2, inf);
coder.internal.polyshape.checkArray(pshape);

d = coder.internal.polyshape.checkScalarValue(bufferDis, 'MATLAB:polyshape:bufferDistanceError');

ninputs = numel(varargin);
coder.internal.assert(mod(ninputs, 2)==0, 'MATLAB:polyshape:nameValuePairError');

jointType = 'r';
miterLimit = 3;

jointTypeList = {'square', 'miter', 'round'};
foundML = false;
foundJT = 0;
for k=1:2:ninputs

    coder.internal.assert(coder.internal.isCharOrScalarString(varargin{k}), ...
                          'MATLAB:polyshape:bufferParameter');

    % Optional args must be const for codegen
    coder.internal.assert(coder.internal.isConst(varargin{k}), ...
                          'Coder:toolbox:OptionInputsMustBeConstant', 'polyshape');

    cmpLength = max(length(varargin{k}), 1);
    i = k+1;
    if (strncmpi(varargin{k}, 'JointType', cmpLength))
        foundJT = 0;
        if coder.internal.isCharOrScalarString(varargin{i})
            cmpLength = max(length(varargin{i}), 1);
            for j=1:numel(jointTypeList)
                if (strncmpi(varargin{i}, jointTypeList{j}, cmpLength))
                    foundJT = j;
                    if j == 1
                        jointType = 's';
                    elseif j == 2
                        jointType = 'm';
                    end
                    break;
                end
            end
        end
        coder.internal.assert(foundJT~=0, 'MATLAB:polyshape:bufferJointError');
    elseif (strncmpi(varargin{k}, 'MiterLimit', cmpLength))
        miterLimit = coder.internal.polyshape.checkScalarValue(varargin{i}, 'MATLAB:polyshape:bufferMiterValue');
        foundML = true;
        %check MiterLimit
        coder.internal.errorIf(miterLimit < 2, 'MATLAB:polyshape:bufferMiterValue');
    else
        coder.internal.errorIf(true, 'MATLAB:polyshape:bufferParameter');
    end

end

%check consistency for MiterLimit
coder.internal.errorIf(foundML && (foundJT ~= 2), 'MATLAB:polyshape:bufferMiterType');

if abs(d) <= eps*10
    PG = pshape;
    return
end

if pshape.isEmptyShape()
    PG = coder.internal.polyshape;
    return
end
PG = extractPropsAndCallBufferAPI(pshape, d, jointType, miterLimit);
