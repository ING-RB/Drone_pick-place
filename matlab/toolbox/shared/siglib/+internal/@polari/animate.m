function animate(p,varargin)
%ANIMATE Replace current data with new data for animation.
%  animate(P,D) replaces all current data in polar plot P with new data
%  based on the real amplitude values in vector D, with angles uniformly
%  spaced from 0 to (N-1)/N*360 degrees, where N is the length of D.
%
%  This function provides fast update rates so repeated calls in a loop can
%  animate the display of data over time.  Each call to animate ensures
%  data is made immediately visible.
%
%  You MUST call animate(P,'end') after your animation loop has completed,
%  otherwise markers and readouts may remain disabled.
%
%  For a matrix D, columns of D are independent datasets. For N-D arrays,
%  dimensions 2 and greater are independent datasets.  For complex values,
%  magnitude and angle are derived from D.
%
%  animate(P,A1,M1,A2,M2, ...) specifies angle vectors A1, A2, ... in
%  degrees along with real data matrices M1, M2, ...  More information
%  about data <a href="matlab:help internal.polari/formats">formats</a> is available.
%
%  If object P wasn't retained when POLARPATTERN plot was created, it may
%  be obtained from the current figure using P = polarpattern('gco').
%
%  Note that the value of <a href="matlab:help internal.polari.NextPlot">NextPlot</a> gets changed to 'add' as a result of
%  calling this function.
%
%  For adding new data to a plot, or replacing existing plot data without
%  animation, see the <a href="matlab:help internal.polari.add">add</a> and <a href="matlab:help internal.polari.replace">replace</a> functions.
%
%  See also polarpattern, <a href="matlab:help internal.polari.formats">formats</a>, <a href="matlab:help internal.polari.add">add</a>, <a href="matlab:help internal.polari.replace">replace</a>.

if ~p.pUpdateCalled
    % First time animate called in a set of calls (i.e., before
    % resumeDataMarkers subsequently called).
    
    % Suspend markers when an animate call is made.  Cached so that
    % it is fast during subsequent animate calls.
    %   - removes data dot
    %   - alerts markers to animate their data values when they are
    %     next clicked or accessed
    suspendDataMarkers(p);
    
    plot(p,varargin{:});
else
    % Second or subsequent invocation of animate method
    if nargin==2 && strcmpi(varargin{1},'end')
        resumeDataMarkers(p);
    else
        plot_update(p,varargin{:});
    end
end
drawnow('expose'); % 'limitrate'
