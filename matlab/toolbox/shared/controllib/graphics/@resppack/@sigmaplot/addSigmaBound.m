function r = addSigmaBound(this,Sys,BoundType,Focus)
%addSigmaBound  Adds a upper or lower bound to the plot
%
%  Sys is an DynamicSystem object
%  BoundType is 'upper' or 'lower. 
%  Focus is a two element vector [wmin, wmax] expressed in rad/s

%   Copyright 1986-2013 The MathWorks, Inc.
if nargin<4
   Focus = [0,Inf];
end

src = resppack.SigmaBoundSource(Sys,Focus);

r = this.addresponse(src,'resppack.SigmaBoundView');
set(r.View,'BoundType',BoundType)
r.DataFcn =  {@getBoundData src r};
r.draw