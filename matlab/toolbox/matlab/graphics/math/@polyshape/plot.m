function ph = plot(varargin)
% PLOT Plot a polyshape object
%
% PLOT(pshape) plots a polyshape object.
%
% h = PLOT(pshape) also returns a Polygon graphics object. Use the
% properties of this object to inspect and adjust the plotted graph.
%
% See also matlab.graphics.primitive.Polygon, polyshape, patch

% Copyright 2016-2023 The MathWorks, Inc.
%
[cax,args] = axescheck(varargin{:});
nameOffset = 1 + ~isempty(cax); % used in error messages

pshape = args{1};
validateattributes(pshape,{'polyshape'},{},nameOffset);
args = args(2:end); % discard AX and pshape
args = matlab.graphics.internal.convertStringToCharArgs(args);

nd = polyshape.checkArray(pshape);

axesParent =  isempty(cax) || isa(cax,'matlab.graphics.axis.AbstractAxes');
if axesParent
    cax = newplot(cax);
end

isFaceColorSet = any(cellfun(@(s) (ischar(s) || isstring(s)) && strncmpi(s, 'FaceColor', max(strlength(s), 1)), args(1:2:end)));

%plot the polyshape
hObj = gobjects(nd);
for i=1:numel(pshape)
    nextColor = [0,0,0];
    if axesParent
        [~,nextColor,~] = matlab.graphics.chart.internal.nextstyle(cax,~isFaceColorSet,false,true);
    end
    hObj(i) = matlab.graphics.primitive.Polygon('Shape',pshape(i),...
        'FaceColor_I',nextColor,'FaceAlpha',0.35,...
        'Parent',cax, args{:});
    hObj(i).assignSeriesIndex
end

if nargout > 0
    ph = hObj;
end

end
