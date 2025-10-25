function T = binaryFunHelper(A,B,fun,unitsHelper,funName)
%

% BINARYFUNHELPER Helper function to apply elementwise binary arithmetic,
% logical and relational operators on tabular inputs.

%   Copyright 2022-2024 The MathWorks, Inc.

import matlab.internal.tabular.selectRows

if nargin < 5
    funName = func2str(fun);
end
try
if isa(A,'tabular') && isa(B,'tabular')
    [T,BRowOrder,BVarOrder] = getTemplateForBinaryMath(A,B,fun,unitsHelper);
    B.data = B.data(BVarOrder);
    for varIdx = 1:A.varDim.length
        try
            if isempty(BRowOrder)
                T.data{varIdx} = fun(A.data{varIdx}, B.data{varIdx});
            else % rows need reordering
                T.data{varIdx} = fun(A.data{varIdx}, selectRows(B.data{varIdx},BRowOrder));
            end
        catch ME
            varname_j = T.varDim.labels{varIdx};
            m = MException(message("MATLAB:table:math:VarFunFailed",funName,varname_j));
            m = m.addCause(ME);
            throw(m);
        end
        if size(T.data{varIdx},1) ~= T.rowDim.length
            error(message('MATLAB:table:math:FunWrongHeight',funName,T.varDim.labels{varIdx}));
        end
    end
else % array + tabular or tabular + array
    % Use the tabular input as the output template. Also keep track of whether
    % it was the first input or the second one. This information is used when
    % applying fun.
    if isa(B,'tabular')
        T = B;
        X = A;
        tabularFirst = false;
    else
        T = A;
        X = B;
        tabularFirst = true;
    end
    
    % Verify the size and type of the array operand.
    sz = size(X);
    if isobject(X) || ~(isnumeric(X) || islogical(X))
        % Only core numeric and logical arrays are allowed.
        error(message('MATLAB:table:math:InvalidObjectArray',class(T),class(X)));
    elseif ~ismatrix(X) % ND not supported
        error(message('MATLAB:table:math:NDArray'));
    elseif ~(sz(1) == 1 || sz(1) == T.rowDim.length) % Wrong height
        error(message('MATLAB:table:math:ArrayWrongHeight'));
    elseif ~(sz(2) == 1 || sz(2) == T.varDim.length) % Wrong width
        error(message('MATLAB:table:math:ArrayWrongWidth'));
    end

    colIdx = 1;
    colStride = ~iscolumn(X); % Implicit expansion
    for varIdx = 1:T.varDim.length
        try
            if tabularFirst
                T.data{varIdx} = fun(T.data{varIdx}, X(:,colIdx));
            else
                T.data{varIdx} = fun(X(:,colIdx), T.data{varIdx});
            end
        catch ME
            varname_j = T.varDim.labels{varIdx};
            m = MException(message("MATLAB:table:math:VarFunFailed",funName,varname_j));
            m = m.addCause(ME);
            throw(m);
        end
        if size(T.data{varIdx},1) ~= T.rowDim.length
            error(message('MATLAB:table:math:FunWrongHeight',funName,T.varDim.labels{varIdx}));
        end
        colIdx = colIdx + colStride;
    end

    % If the tabular input had VariableUnits, then call the unitHelper to
    % validate and determine the output units.
    if T.varDim.hasUnits
        % Create a dummy varDim for the array input with all undefined units.
        % This way we can reuse the tabular unit handlers.
        dummyVarDim.hasUnits = false;
        dummyVarDim.hasNonEmptyUnits = false(1,T.varDim.length);
        dummyVarDim.units = {};
        if tabularFirst
            T.varDim = T.varDim.setUnits(unitsHelper(T.varDim,dummyVarDim,fun));
        else
            T.varDim = T.varDim.setUnits(unitsHelper(dummyVarDim,T.varDim,fun));
        end
    end
       
end
% Check for any cross variable incompatibility that could have been introduced
% due to the type of the variables changing after the binary math operation.
% Currently, this is only required for eventtables and is a no-op for other
% tabular types.
T.validateAcrossVars(FunName=funName);
catch ME
    throwAsCaller(ME);
end

