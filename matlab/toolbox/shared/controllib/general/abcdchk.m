function [msg,a,b,c,d] = abcdchk(A,B,C,D)
%ABCDCHK Checks dimensional consistency of A,B,C,D matrices.
%   ERROR(ABCDCHK(A,B,C,D)) checks that the dimensions of A,B,C,D
%   are consistent for a linear, time-invariant system model.
%   An error occurs if the nonzero dimensions are not consistent.
%
%   [MSG,A,B,C,D] = ABCDCHK(A,B,C,D) also alters the dimensions
%   any 0-by-0 empty matrices to make them consistent with the others.

%   Copyright 1984-2019 The MathWorks, Inc.
%#codegen

narginchk(0,4);
if nargin < 4, D = []; end
if nargin < 3, C = []; end
if nargin < 2, B = []; end
if nargin < 1, A = []; end

[ma,na] = size(A);
[mb,nb] = size(B);
[mc,nc] = size(C);
[md,nd] = size(D);
a = A; b = B; c = C; d = D;
if mc==0 && nc==0 && (md==0 || na==0)
    mc = md; nc = na; c = zeros(mc,nc,'like',C);
end
if mb==0 && nb==0 && (ma==0 || nd==0)
    mb = ma; nb = nd; b = zeros(mb,nb,'like',B);
end
if md==0 && nd==0 && (mc==0 || nb==0)
    md = mc; nd = nb; d = zeros(md,nd,'like',D);
end
if ma==0 && na==0 && (mb==0 || nc==0)
    ma = mb; na = nc; a = zeros(ma,na,'like',A);
end

msg.message = '';
msg.identifier = '';
msg = msg(zeros(0,1));
if coder.target('MATLAB')
    if ma~=na && nargin>=1
        msg = makeMsg('Controllib:general:AMustBeSquare');
    elseif ma~=mb && nargin>=2
        msg = makeMsg('Controllib:general:AAndBNumRowsMismatch');
    elseif na~=nc && nargin>=3
        msg = makeMsg('Controllib:general:AAndCNumColumnsMismatch');
    elseif md~=mc && nargin>=4
        msg = makeMsg('Controllib:general:CAndDNumRowsMismatch');
    elseif nd~=nb && nargin>=4
        msg = makeMsg('Controllib:general:BAndDNumColumnsMismatch');
    end
else
    coder.internal.errorIf(nargin >= 1  && ma ~= na,'Controllib:general:AMustBeSquare');
    coder.internal.errorIf(nargin >= 2  && ma ~= mb,'Controllib:general:AAndBNumRowsMismatch');
    coder.internal.errorIf(nargin >= 3  && na ~= nc,'Controllib:general:AAndCNumColumnsMismatch');
    coder.internal.errorIf(nargin >= 4  && md ~= mc,'Controllib:general:CAndDNumRowsMismatch');
    coder.internal.errorIf(nargin >= 4  && nd ~= nb,'Controllib:general:BAndDNumColumnsMismatch');
end

%---------------------------------------------
function msg = makeMsg(ID)
    msg.identifier = ID;
    msg.message    = getString(message(ID));

% LocalWords:  Controllib AMust AAnd BNum CNum CAnd DNum BAnd
