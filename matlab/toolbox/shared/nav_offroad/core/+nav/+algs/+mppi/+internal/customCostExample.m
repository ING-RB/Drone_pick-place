%   This function defines a template for creating a custom cost and
%   definition that can be used by controllerMPPI. 
%
%   For a concrete implementation of the same template, see the following
%   function for default cost:
%
%    >> edit nav.algs.mppi.defaultCost
%
%   Add your code for custom cost below. Then, save this file somewhere on
%   the MATLAB path. You can add a folder to the path using the ADDPATH
%   function.

%   Copyright 2024 The MathWorks, Inc.

function cost = customCostExample(trajectories, trajectoriesInputs, mppiObj) 

% Default behavior: Compute using the default cost functions
cost = nav.algs.mppi.defaultCost(trajectories, trajectoriesInputs, mppiObj);

%--------------------------------------------------------------
% Place your code here or replace the default function behavior
%--------------------------------------------------------------
