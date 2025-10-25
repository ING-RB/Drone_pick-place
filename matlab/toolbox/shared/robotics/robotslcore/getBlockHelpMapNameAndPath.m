function [varargout] = getBlockHelpMapNameAndPath(block_type)
%getBlockHelpMapNameAndPath  Returns the mapName and the relative path to the maps file for this block_type

% Copyright 2017-2020 The MathWorks, Inc.

varargout = cell(1, nargout);
[varargout{:}] = robotics.slcore.internal.block.getHelpMapNameAndPath(block_type, ...
    {  
    'robotics.slcore.internal.block.CoordinateTransformationConversion'    'rstCoordTransConvBlock' ;
    'robotics.slcore.internal.block.ReadData'                              'rstReadData'            ;
    'robotics.slcore.internal.block.PolyTrajSys'                           'rstPolynomialTrajectory';
    'robotics.slcore.internal.block.RotTrajSys'                            'rstRotationTrajectory'  ;
    'robotics.slcore.internal.block.TransformTrajSys'                      'rstTransformTrajectory' ;
    'robotics.slcore.internal.block.TrapVelTrajSys'                        'rstTrapezoidalVelocity' ;
    }, ...
    { % These blocks are shared between RST, NAV, ROS, and UAV (RST has priority; the ordering matters
    'robotics';
    'nav';
    'ros';
    'uav';
    } ...
    );
