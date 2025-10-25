function EllipseData = computeEllipseData(this,theta)
%computeEllipseData  compute data to create ellipses

%   Author(s): Craig Buhr
%   Copyright 1986-2012 The MathWorks, Inc.

if nargin == 1
    theta = [0:.1:2*pi,0];
end

theta = theta(:);
Circle = exp(1i*theta);

SD = 1;

Data = this.Data;
[ny,nu] = size(this.Data.Poles);
for yct = 1:ny
    for uct = 1:nu
        numPoles = size(Data.Poles{yct,uct},1);
        if isequal(numPoles,0);
            EllipsePoleData(yct,uct).EllipseData = [];
        else
            for ct = 1:numPoles
                if isempty(Data.CovPoles)
                    EllipsePoleData(yct,uct,ct).EllipseData = NaN;
                else
                    CovMat = squeeze(Data.CovPoles{yct,uct}(:,:,ct));
                    EllipsePoleData(yct,uct,ct).EllipseData = ...
                        transformCircle(Data.Poles{yct,uct}(ct),CovMat,SD,Circle);
                end
            end
        end
        numZeros = size(Data.Zeros{yct,uct},1);
        if isequal(numZeros,0);
            EllipseZeroData(yct,uct).EllipseData = [];
        else
            for ct = 1:numZeros
                if isempty(Data.CovZeros)
                    EllipseZeroData(yct,uct,ct).EllipseData = NaN;
                else
                    CovMat = squeeze(Data.CovZeros{yct,uct}(:,:,ct));
                    EllipseZeroData(yct,uct,ct).EllipseData = ...
                        transformCircle(Data.Zeros{yct,uct}(ct),CovMat,SD,Circle);
                end
            end
        end

            
    end
end

EllipseData = ...
    struct('EllipsePoleData',EllipsePoleData,...
    'EllipseZeroData',EllipseZeroData);

end

function Circle = transformCircle(H,CovH,sd,Circle)
%transformCircle Transform circle to confidence region using Covariance and
% Standard Deviation.
%

if imag(H)==0
    rp=real(H+sd*sqrt(CovH(1,1))*[-1 1]);
    Circle = rp(:);
else
    [V,D]=eig(CovH); 
    z1=real(Circle)'*sd*sqrt(D(1,1));
    z2=imag(Circle)'*sd*sqrt(D(2,2)); 
    X=V*[z1;z2];
    Circle = (X(1,:)'+real(H)) + 1i*(X(2,:)'+imag(H));
end
end

