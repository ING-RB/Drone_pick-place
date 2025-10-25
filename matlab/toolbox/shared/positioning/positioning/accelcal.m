function [A,b] = accelcal(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
% 

%   Copyright 2023 The MathWorks, Inc.      

%#codegen


% Determine the signature
    switch (nargin)
        case 1
            % Easy mode. Figure out gravity
            dm = valMeasurement(arg1, "data", 1); 
            g = findg(dm);
            vm = fusion.internal.findIdealAccelValues(dm,g);
        case 3
            % Easy mode. Gravity is defined
            dm = valMeasurement(arg1, "data", 1);
            valGravStr(arg2, 2);
            g = valGravValue(arg3);
            vm = fusion.internal.findIdealAccelValues(dm,g);
        case 6
            % Explicit mode
            xup = valMeasurement(arg1, "xup", 1);
            xdown = valMeasurement(arg2, "xdown", 2);
            yup = valMeasurement(arg3, "yup", 3);
            ydown = valMeasurement(arg4, "ydown", 4);
            zup = valMeasurement(arg5, "zup", 5);
            zdown = valMeasurement(arg6, "zdown", 6);
            [dm, vm] = matricesFromAxes(xup,xdown,yup,ydown,zup,zdown);
        case 8
            % Explicit. Gravity defined.
            xup = valMeasurement(arg1, "xup", 1);
            xdown = valMeasurement(arg2, "xdown", 2);
            yup = valMeasurement(arg3, "yup", 3);
            ydown = valMeasurement(arg4, "ydown", 4);
            zup = valMeasurement(arg5, "zup", 5);
            zdown = valMeasurement(arg6, "zdown", 6);
            valGravStr(arg7, 7);
            g = valGravValue(arg8);
            [dm, vm] = matricesFromAxes(xup,xdown,yup,ydown,zup,zdown,g);
        otherwise
            coder.internal.error("shared_positioning:accelcal:Signature", "help accelcal");
    end
    
% dm is the data. dmext is the data with a 4th column of 1s.
% The next 3 lines are the codegen supported way of doing this.
dmext = zeros(size(dm,1), 4, 'like', dm); 
dmext(:,1:3) = dm;
dmext(:,4) = 1;
% Solve the system of equations:
x = dmext\vm; 
A = x(1:3,:); 
b = x(4,:); 

end

% Validation functions

function ax = valMeasurement(arg, name, idx)
%VALMEASUREMENT data validation. Ensures measurements are N-by-3.
%   ARG - data to validate
%   NAME - name of argument to show in an error
%   IDX - index of argument to show in error.

    % cell of chars for codegen purposes
    validateattributes(arg, {'double', 'single'}, {'2d', 'ncols', 3, ...
    'finite', 'nonnan', 'real'}, 'accelcal', name, idx);
    ax = arg;
end

function valGravStr(arg, idx)
    coder.internal.assert( strcmpi(arg, "Gravity"), ...
        "shared_positioning:accelcal:GravityStr", idx, "Gravity");
end

function gval = valGravValue(arg)
    coder.internal.assert(isnumeric(arg) && isscalar(arg) && ...
        isfinite(arg) && isreal(arg), "shared_positioning:accelcal:GravityValue");
    gval = arg;
end

% In explicit mode, convert separate axes into data and ideal matrix
function [dm, vm] = matricesFromAxes(xup,xdown,yup,ydown,zup,zdown,g)
    dm = [xup;xdown;yup;ydown;zup;zdown];
    if nargin < 7
        g = findg(dm);
    end
    % Up is -gravity
    % Down is +gravity
    v1 = repmat(cast([-g 0 0], "like", xup), size(xup,1),1);
    v2 = repmat(cast([g 0 0], "like", xup),  size(xdown,1),1);
    v3 = repmat(cast([0 -g 0], "like", xup), size(yup,1),1);
    v4 = repmat(cast([0 g 0], "like", xup),  size(ydown,1),1);
    v5 = repmat(cast([0 0 -g], "like", xup), size(zup,1),1);
    v6 = repmat(cast([0 0 g], "like", xup),  size(zdown,1),1);
    vm = [v1;v2;v3;v4;v5;v6];
end

function g = findg(data)
    m = mean(vecnorm(data,2,2));
    o = ones(1,1, "like", data);
    gmpss = fusion.internal.UnitConversions.geeToMetersPerSecondSquared(o);
    if m > gmpss / cast(2, 'like', data)  % probably in m/s^2
        g = gmpss;
    else
        g = o;  % problem in Gs
    end
end

