function [numc,denc,msg] = tfchk(num,den)
%TFCHK  Check for proper transfer function.
%   [NUMc,DENc] = TFCHK(NUM,DEN) returns equivalent transfer function
%   numerator and denominator where LENGTH(NUMc) = LENGTH(DENc) if
%   the transfer function NUM,DEN are proper.  Prints an error message
%   if not.
%   A third output returns the error message instead if erroring
%   to the command line.

%   Clay M. Thompson 6-26-90
%   Copyright 1984-2003 The MathWorks, Inc.

no = nargout;
[nn,mn] = size(num);
[nd,md] = size(den);

% Make sure DEN is a row vector, NUM is assumed to be in rows.
if nd > 1,
    msg = makeMsg('Controllib:general:denominatorNotRowVector');
elseif (mn > md),
    msg = makeMsg('Controllib:general:improperTransferFunction');
else
    msg.message = '';
    msg.identifier = '';
    msg = msg(zeros(0,1));
end

if (no < 3)
    error(msg);
end

% Make NUM and DEN lengths equal.
numc = [zeros(nn,md-mn),num];
denc = den;

%---------------------------------------------
function msg = makeMsg(ID)
msg = struct('message',ctrlMsgUtils.message(ID),'identifier',ID);
