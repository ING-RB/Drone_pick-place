function [ode, odeIsFuncHandle, odeTreatAsMFile] = packageAsFuncHandle(ode)
if isa(ode,'function_handle')
    odeIsFuncHandle = true;
    odeTreatAsMFile = false;
else
    odeTreatAsMFile = exist(ode) == 2; %#ok<EXIST>
    odeIsFuncHandle = false;
    if isa(ode,'char') || isa(ode,'string')
        ode = str2func(ode);
    end
end