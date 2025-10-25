function multiaxes
% POLARPATTERN may be used in multiple axes within a figure. This can
% be useful for comparing multiple data sets.
%
% For example, multiple top-view polar axes may be displayed as
% follows, assuming ang and mag are matrices with size 100x3x3,
% with 100 angle and magnitude datapoints per trace.
%
%   figure
%   for i = 1:3
%     for j = 1:3
%        subplot(3,3,3*i+j);
%        polari(ang(:,i,j),mag(:,i,j));
%     end
%   end
%
% See also polarpattern, <a href="matlab:help internal.polari.TitleTop">TitleTop</a>.

help internal.polari/multiaxes
