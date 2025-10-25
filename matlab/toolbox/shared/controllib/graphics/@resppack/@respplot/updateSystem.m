function updateSystem(this,System,Index)
% updateSystem Updates the system data in a response plot.
%
%  updateSystem(H,sys) updates the system used to compute the data for the
%  first response in the plot with handle H.
%
%  updateSystem(H,sys,n) updates the system used to compute the data 
%  for the nth response in the plot with handle H.
%  
%  For example:
%      sys = tf(1,[1,1]);
%      h = bodeplot(sys);
%      newsys = tf(5,[1,1]);
%      updateSystem(h,newsys)
%

%  Copyright 1986-2013 The MathWorks, Inc.

narginchk(2,3)

if nargin == 2
    Index = 1;
elseif (~isnumeric(Index) || ~isscalar(Index) || rem(Index,1)~= 0) || (Index<1) || (Index > numel(this.Responses))
    error(message('Controllib:plots:UpdateSystem1', numel(this.Responses)))
end

DataSrc = this.Response(Index).DataSrc;

if isempty(DataSrc)
    error(message('Controllib:plots:UpdateSystem5'))
end

if isa(System,'DynamicSystem')
    if isequal(iosize(System),iosize(DataSrc.Model)) && isequal(prod(size(System)),prod(size(DataSrc.Model)))
        DataSrc.Model = System;
    else
        s = size(DataSrc.Model);
        nd = ndims(DataSrc.Model);
        if nd > 2
            error(message('Controllib:plots:UpdateSystem4',prod(s(3:end)),s(1),s(2)))
        else
            error(message('Controllib:plots:UpdateSystem3',s(1),s(2)))
        end
    end
else
    error(message('Controllib:plots:UpdateSystem2'))
end
