function [rS,rT] = addLoopShapeBound(this,S,T,Focus)
%addLoopShapeBound  Adds bounds for TuningGoal.LoopShape view.
%
%  S and T are ZPK models, FOCUS is 1x2, and WC is the vectors of all
%  0dB crossover frequencies for S and T. Both FOCUS and WC are expressed 
%  in rad/s.

%   Copyright 1986-2016 The MathWorks, Inc.
ni = nargin;
if ni<4
   Focus = [0,Inf];
end

% Bound of S (minimum loop gain)
src = resppack.SigmaBoundSource(S,Focus);
rS = this.addresponse(src,'resppack.SBoundView');
rS.Name = 'S bound';
rS.DataFcn =  {@getBoundData src rS};
rS.draw

% Bound of T (maximum loop gain)
src = resppack.SigmaBoundSource(T,Focus);
rT = this.addresponse(src,'resppack.TBoundView');
rT.Name = 'T bound';
rT.DataFcn =  {@getBoundData src rT};
rT.draw
