function replace(p,varargin)
%REPLACE Remove current data and add new data to the plot.
%  replace(P,D) removes all current data and adds new data to polar plot P
%  based on real amplitude values in vector D, with angles uniformly spaced
%  from 0 to (N-1)/N*360 degrees, where N is the length of D.  The lowest
%  (nearest -inf) amplitude is plotted at the origin and the highest
%  (nearest +inf) is at maximum radius.
%
%  For a matrix D, columns of D are independent datasets. For N-D arrays,
%  dimensions 2 and greater are independent datasets.  For complex values,
%  magnitude and angle are derived from D.
%
%  replace(P,A1,M1,A2,M2, ...) specifies angle vectors A1, A2, ... in
%  degrees along with real data matrices M1, M2, ...  More information
%  about data <a href="matlab:help internal.polari/formats">formats</a> is available.
%
%  If object P wasn't retained when POLARPATTERN plot was created, it may
%  be obtained from the current figure using P = polarpattern('gco').
%
%  Note that the value of <a href="matlab:help internal.polari.NextPlot">NextPlot</a> gets changed to 'add' as a result of
%  calling this function.
%
%  For repeated updates to a plot intended for animation, see the
%  <a href="matlab:help internal.polari.animate">animate</a> function.
%
%  See also polarpattern, <a href="matlab:help internal.polari.formats">formats</a>, <a href="matlab:help internal.polari.add">add</a>, <a href="matlab:help internal.polari.animate">animate</a>.

p.NextPlot = 'replace';
plot(p,varargin{:});
