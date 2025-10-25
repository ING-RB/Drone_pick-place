function outval = chermite(t,x,v,tt)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.CHERMITE  Piecewise cubic Hermite interpolation.
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   PP = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.CHERMITE(T,X,V) finds the
%   piecewise polynomial form of the cubic spline interpolant to the data
%   values, X, at the time instants, T, with instantaneous
%   time-derivatives, V, for use with the evaluator PPVAL and the spline
%   utility UNMKPP.
%
%   Note:  T, X, and V will be converted to column vectors before use.
%
%   XX = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.CHERMITE(T,X,V,TT) is the
%   same as XX = PPVAL(CHERMITE(T,V,X),TT), thus providing the interpolated
%   values, XX, at time instants TT.  For information regarding the size of
%   XX, see PPVAL.
%
%   MATLABSHARED.TRACKING.INTERNAL.SCENARIO.CHERMITE(T,X,V) without output
%   arguments produces a plot of the entire piecewise polynomial with
%   derivatives shown.
%
%   MATLABSHARED.TRACKING.INTERNAL.SCENARIO.CHERMITE(T,X,V,TT) without
%   output arguments produces a plot of the polynomial evaluated over TT
%   with derivatives shown.
%
%      % Example:
%      t = [1 2  3  5 7 9]';
%      x = [1 2  1  4 2 1]';
%      v = [1 2 -1  0.5 1 1]';
% 
%      matlabshared.tracking.internal.scenario.chermite(t,x,v);
%
%   See also SPLINE, PCHIP, PPVAL, UNMKPP.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

% force column vectors
t = t(:);
x = x(:);
v = v(:);

%  First derivatives
dt = diff(t);
delta = diff(x)./dt;

%  Piecewise polynomial coefficients
n = length(t);
c = (3*delta - 2*v(1:n-1) - v(2:n))./dt;
b = (v(1:n-1) - 2*delta + v(2:n))./dt.^2;

%  Make piecewise polynomial
pp = mkpp(t,[b c v(1:end-1) x(1:end-1)],1);

if nargout>0
    if nargin<4
        %  return piecewise polynomial
        outval = pp;
    else
        %  Evaluate interpolant
        outval = ppval(pp,tt);
    end
else
    if nargin<4
        tt = linspace(t(1),t(end),10001);
    end
    xx = ppval(pp, tt);
    e = 0.02*(t(end)-t(1));
    tv = [t'-e; t'+e; nan(size(t'))];
    v1 = [x'-v'.*e; x'+v'.*e; nan(size(t'))];

    plot(tt,xx,'-',tv(:),v1(:),'-',t,x,'o');
    title('Piecewise cubic fit to specified distance and velocity at given time');
    legend('best fit','derivatives','samples')
    ylabel('Distance')
    xlabel('Time (irregular sampled)')
end
