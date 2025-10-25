%% Solve System of Ordinary Differential Equations
% This experiment function template solves the following system of ordinary differential 
% equations and sweeps over values of the parameters $\alpha$ and $\beta$.
%
%
% $$\frac{dx_1}{dt} = x_1 (1 - \alpha x_2) \\ \frac{dx_2}{dt} = x_2(-1  + \beta x_1) $$
%
%
% Modify this function to define your own experiments. For more information, 
% see <matlab:helpview('matlab','exp-mgr-create-experiment') Configure General-Purpose 
% Experiment>.
%% Input
%% 
% * |params| $$-$$ A structure with fields from the Experiment Manager parameter table. Access the 
% parameter values specified in the Parameters table in the Experiment Manager app by using |params.field|, 
% where |field| is the parameter name. Access the initial values returned by the Initialization Function, 
% which is run by the Experiment Manager app before executing the experiment function, by using |params.InitializationFunctionOutput|.
%% Output
%% 
% * |x1End| and |x2End| are the values of |x1| and |x2| variables at the
% end time. The names of the output variables appear as column headers in the results table when you run your experiment.
% 
%% Experiment Function
%
function [x1End,x2End] = {functionName}(params)
xInitial = params.InitializationFunctionOutput;
%%
% This experiment sweeps over one or more values for the |endTime| parameter. If you add the 
% suggested |endTime| parameter to the Parameters table in the Experiment Manager app, access 
% the  parameter values using |params.endTime|. Otherwise, this function assigns the parameter 
% a scalar value.
if ~isfield(params, 'endTime')
    params.endTime = 30;
end
tRange = [0 params.endTime];
%%
% Create a function |dxdt| to compute the derivatives of |x1| and |x2|.
dxdt = @(t,x) diag([1 - params.Alpha*x(2), -1 + params.Beta*x(1)])*x;
%%
% Solve the system of differential equations using the |ode45| function on the time interval |tRange| with initial values |xInitial|. 
[t,x] = ode45(dxdt,tRange,xInitial);
%%
% Display |x1| and |x2| over time.
figure("Name", "x1 and x2 Over Time")
plot(t,x,"-o")
title("x1 and x2 Over Time")
xlabel("Time")
ylabel("Value")
legend("x1","x2")
%%
% Return the end values of |x1| and |x2|.
x1End = x(end, 1);
x2End = x(end, 2);
end
