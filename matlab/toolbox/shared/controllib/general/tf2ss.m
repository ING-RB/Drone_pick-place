function [a,b,c,d] = tf2ss(num,den)
%TF2SS  Transfer function to state-space conversion.
%   [A,B,C,D] = TF2SS(NUM,DEN)  calculates the state-space
%   representation:
%       .
%       x = Ax + Bu
%       y = Cx + Du
%
%   of the system:
%               NUM(s)
%       H(s) = --------
%               DEN(s)
%
%   from a single input.  Vector DEN must contain the coefficients of
%   the denominator in descending powers of s.  Matrix NUM must
%   contain the numerator coefficients with as many rows as there are
%   outputs y.  The A,B,C,D matrices are returned in controller
%   canonical form.  This calculation also works for discrete systems.
%
%   For discrete-time transfer functions, it is highly recommended to
%   make the length of the numerator and denominator equal to ensure
%   correct results.  You can do this using the function EQTFLENGTH in
%   the Signal Processing Toolbox.  However, this function only handles
%   single-input single-output systems.
%
%   See also TF2ZP, SS2TF, ZP2SS, ZP2TF.

%   J.N. Little 3-24-85
%   Copyright 1984-2019 The MathWorks, Inc.
%   Latest revision 4-29-89 JNL, 7-29-96 PG
%#codegen

narginchk(2,2);
if(coder.target('MATLAB'))
    [a,b,c,d] = tf2ssImpl(num,den);
else
    if coder.internal.isConst(num) && coder.internal.isConst(den) && coder.internal.isCompiled
        [a,b,c,d] = coder.const(@feval,'tf2ss',num,den);
    else
        [a,b,c,d] = tf2ssImpl(num,den);
    end
end
end

function [a,b,c,d] = tf2ssImpl(num,den)
% Cast to enforce precision rules
if isa(num,'single') || isa(den,'single')
    nums = single(num);
    dens = single(den);
else
    nums = num;
    dens = den;
end
%Null system - Both numerator and denominator are empty
if isempty(nums) && isempty(dens)
    a = zeros(0,'like',nums);
    b = zeros(0,'like',nums);
    c = zeros(0,'like',nums);
    d = zeros(0,'like',nums);
else
    coder.internal.assert(ismatrix(nums) && ismatrix(dens),'Controllib:general:incorrectDimension');
    coder.internal.errorIf(min(size(dens)) > 1,'Controllib:general:NeedRowDenom');
    denRow = dens(:).';
    % Index of first non zero element of denominator
    startIndexDen = find(denRow,1);
    % Denominator should not be zero or empty
    if isempty(startIndexDen)
        coder.internal.error('Controllib:general:invalidRange');
    end
    % Strip denominator of leading zeros
    denStrip = denRow(startIndexDen(1):end);
    [mnum,nnum] = size(nums);
    nden = size(denStrip,2);
    % Check for proper numerator
    if (nnum > nden)
        if any(nums(:,1:(nnum - nden)) ~= 0,'all')
            coder.internal.error('Controllib:general:DenomInvalidOrder');
        end
        % Try to strip leading zeros to make proper
        numStrip = nums(:,(nnum-nden+1):nnum);
    else
        % Pad numerator with leading zeroes, to make it have same number of
        % Columns as the denominator
        numStrip = [zeros(mnum,nden-nnum) nums];
    end
    
    % Normalize numerator and denominator such that first element of
    % Denominator is one
    numNormalized = numStrip./denStrip(1);
    denNormalized = denStrip./denStrip(1);
    if mnum == 0
        d = zeros(0,'like',numNormalized);
        c = zeros(0,'like',numNormalized);
    else
        d = numNormalized(:,1);
        c = numNormalized(:,2:nden) - numNormalized(:,1) * denNormalized(2:nden);
    end
    
    if nden == 1
        a = zeros(0,'like',numNormalized);
        b = zeros(0,'like',numNormalized);
        c = zeros(0,'like',numNormalized);
    else
        a = [-denNormalized(2:nden);eye(nden-2,nden-1)];
        b = eye(nden-1,1,'like',numNormalized);
    end
end

end

% LocalWords:  Cx JNL denom Controllib
