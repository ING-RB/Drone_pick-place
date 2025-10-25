%% General-Purpose Experiment
% Modify this function to define your own experiments. For more
% information, see <matlab:helpview('matlab','exp-mgr-create-experiment') 
% Configure General-Purpose Experiment>.
%% Input
%% 
% * |params| $$-$$ A structure with fields from the Experiment Manager parameter 
% table. In the experiment function, access the parameter values by using dot
% notation.
%% Output
%% 
% * The experiment function can return multiple outputs. The names of the
% output variables appear as column headers in the top of the results
% table. Each output value must be a numeric, logical, or string scalar and
% appears in the trial row of  the results table. 
%% Example
%%
% 
%   function [speed,info] = Experiment1Function1(params) 
%   distance = params.distance; 
%   time = params.time; 
%   speed = distance / time; 
%   if speed > 100 
%      info = "Fast";
%   else
%      info = "Slow";
%   end 
%   end
%
%% 
% 
%% Experiment Function
%
function [output1,output2] = {functionName}(params)
output1 = 0;
output2 = 0;
end
