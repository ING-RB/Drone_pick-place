function EllipseData = computeEllipseData(this,theta)
%computeEllipseData  compute data to create ellipses

%   Author(s): Craig Buhr
%   Copyright 1986-2011 The MathWorks, Inc.

if nargin == 1
    theta = [0:.1:2*pi,0];
end

sd = 1;

theta = theta(:);
Circle = exp(1i*theta);

Data = this.Data;
[~,ny,nu] = size(this.Data.Response);

for yct = 1:ny
    for uct = 1:nu
        numFreq = size(Data.Frequency,1);
        for ct = 1:numFreq
            if isempty(Data.Cov)
                 EllipseData(yct,uct,ct).EllipseFreq = NaN;
            else
                CovMat = squeeze(Data.Cov(yct,uct,ct,:,:));
                EllipseData(yct,uct,ct).EllipseFreq =  ...
                    transformCircle(Data.Response(ct,yct,uct),CovMat,sd,Circle);
            end
            EllipseData(yct,uct,ct).EllipseCenter = Data.Response(ct,yct,uct);
        end
    end
end


function Circle = transformCircle(H,CovH,sd,Circle)
%transformCircle Transform circle to confidence region using Covariance and
% Standard Deviation.
%

if imag(H)==0
    rp=real(H+sd*sqrt(CovH(1,1))*[-1 1]);
    Circle = rp(:);
else
    if all(isfinite(CovH))
        [V,D]=eig(CovH);
        z1=real(Circle)'*sd*sqrt(max(0,D(1,1)));
        z2=imag(Circle)'*sd*sqrt(max(0,D(2,2)));
        X=V*[z1;z2];
        Circle = (X(1,:)'+real(H)) + 1i*(X(2,:)'+imag(H));
    else
        Circle = NaN(size(Circle));
    end
        
end