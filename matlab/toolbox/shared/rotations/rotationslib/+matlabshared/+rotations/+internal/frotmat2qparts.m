function [a,b,c,d] = frotmat2qparts(Rarr)
%FROTMAT2QPARTS - quaternion parts from a frame rotation (body fixed) matrix
%   This function is for internal use only. It may be removed in the future.

%   Copyright 2017 The MathWorks, Inc.
%

%#codegen


dt = class(Rarr);
num = size(Rarr,3);
a = zeros(num,1, dt);
b = zeros(num,1, dt);
c = zeros(num,1, dt);
d = zeros(num,1, dt);

    for ii=1:num
        R = Rarr(:,:,ii);
        [a(ii), b(ii), c(ii), d(ii)] = solveR2Q(R);
    end

end

function [a,b,c,d] = solveR2Q(R)
% The formula here can be found in "An Introduction to the Mathematics
% and Methods of Astrodynamics" by Richard H Battin. The formula is
% originally attributed to Stanley Shepperd's "Quaternion from Rotation
% Matrix" in Journal of Guidance and Control, 1978.

%Note the formulas in the Battin are for point rotation. This is a frame
%rotation conversion. The matrix element differences do not match those in
%Kuipers which is also frame rotation. Hence differences  are inverted
%which corresponds to transposing the matrix i.e. converting to a frame
%rotation.

    tr = trace(R);

    dd = [tr; diag(R)];
    psquared = 1+2.*dd - trace(R);
    [pmax,idx] = max(psquared);

    switch (idx)
        case 1
            %angle is not near 180.
            pa = sqrt(pmax);
            a = 0.5*pa;
            invpa = 0.5./pa;
            b = invpa.*(R(2,3) - R(3,2));
            c = invpa.*(R(3,1) - R(1,3));
            d = invpa.*(R(1,2) - R(2,1));
        
        case 2
            %b is biggest
            pb = sqrt(pmax); 
            b = 0.5*pb;
            invpb = 0.5./pb;

            a = invpb.*(R(2,3) - R(3,2));
            c = invpb.*(R(1,2) + R(2,1));
            d = invpb.*(R(3,1) + R(1,3));
        case 3
            %c is biggest
            pc = sqrt(pmax); 
            c = 0.5*pc;
            invpc = 0.5./pc;

            a = invpc.*(R(3,1) - R(1,3));
            b = invpc.*(R(1,2) + R(2,1));
            d = invpc.*(R(2,3) + R(3,2));
        otherwise %4
            %d is biggest
            pd = sqrt(pmax); 
            d = 0.5*pd;
            invpd = 0.5./pd;
            a = invpd.*(R(1,2) - R(2,1));
            b = invpd.*(R(3,1) + R(1,3));
            c = invpd.*(R(2,3) + R(3,2));
    end

    %Make first part of the quaternion positive
    if a < 0
        a = -a;
        b = -b;
        c = -c;
        d = -d;
    end
end
