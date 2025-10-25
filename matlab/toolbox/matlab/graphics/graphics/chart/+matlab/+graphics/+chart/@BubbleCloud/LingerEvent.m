function LingerEvent(obj,eventdata)
%

%   Copyright 2020-2023 The MathWorks, Inc.

% Callback for all linger events

switch eventdata.EventName
    case 'EnterObject'
        % Highlight a bubble
        hitobj=eventdata.HitObject;
        ind=eventdata.NearestPoint;

        if ~isequal(hitobj,obj.Marker) || ...
                ~(ind>=1 && ind<=size(obj.Marker.VertexData,2))
        return
        end
        vd=obj.Marker.VertexData(:,ind);
        sz=obj.Marker.Size(:,ind);
        [faceclr,edgeclr]=getHighlightColors(obj.Marker,ind);
        set(obj.HighlightMarker,...
            'FaceColorData',faceclr,...
            'EdgeColorData',edgeclr,...
            'VertexData',vd,...
            'Size',sz,...
            'Visible',true);
        obj.SelectedMarkerIndex=ind;
    case 'ExitObject'
        % Unhighlight a bubble
        hitobj=eventdata.HitObject;
        if ~isequal(hitobj,obj.Marker) && ~isequal(hitobj,obj.HighlightMarker)
            obj.HighlightMarker.Visible='off';
            obj.Datatip.Visible='off';
            obj.SelectedMarkerIndex=nan;
        end
    case 'LingerOverObject'
        ind=eventdata.NearestPoint;

        % Place datatip
        dataind=obj.RadiusIndex(ind);
        labelFontColor = obj.Datatip.LabelFontColor; 
        textValueColor = obj.Datatip.PinnedValueFontColor;
        tipstr=obj.getDatatipString(dataind,labelFontColor,textValueColor);

        % If the center of the bubble is outside the axes,
        % don't show
        ip=eventdata.IntersectionPoint(1:2);
        xl=obj.Axes.XLim_I;
        yl=obj.Axes.YLim_I;
        inaxes=ip(1)>=xl(1) && ip(1)<=xl(2) && ip(2)>=yl(1) && ip(2)<=yl(2);

        if ~isempty(tipstr) && inaxes
            set(obj.Datatip,...
                'Position',eventdata.IntersectionPoint, ...
                'String',tipstr,...
                'Visible','on');
        end
    case 'LingerReset'
        % Remove datatip
        obj.Datatip.Visible='off';
end
end

function [mfc,mec]=getHighlightColors(marker,ind)
if strcmp(marker.EdgeColorBinding,'object')
    mec=marker.EdgeColorData;
elseif strcmp(marker.EdgeColorBinding,'discrete')
    mec=marker.EdgeColorData(:,ind);
else
    mec='none';
end
if strcmp(marker.FaceColorBinding,'object')
    mfc=marker.FaceColorData;
elseif strcmp(marker.FaceColorBinding,'discrete')
    mfc=marker.FaceColorData(:,ind);
else
    mfc='none';
end

if strcmp(mfc,'none')  && ~strcmp(mec,'none')
    % When there is no face, and there is an edge, make the face the same
    % color as the edge, with alpha .6
    mfc=[mec(1:3);153];
elseif strcmp(mfc,'none')  && strcmp(mec,'none')
    % Shouldn't be able to get a highlight on none/none, because there's
    % nothing to hit, mark as black just in case
    mec=uint8([0;0;0;255]);
    mfc=uint8([0;0;0;255]);
else
    % If there's a face color just darken it or lighten it depending on
    % alpha
    if mfc(4)>200
        % overlay will always be opaque, so desaturate and brighten dark
        % markers
        hsv=rgb2hsv(double(mfc(1:3)')/255);
        hsv(2)=max(hsv(2)-.4,0);
        hsv(3)=min(hsv(3)+.4,1);
        mfc(1:3)=uint8(hsv2rgb(hsv)*255);
    end
    mfc(4)=255;
end

end

% LocalWords:  desaturate
