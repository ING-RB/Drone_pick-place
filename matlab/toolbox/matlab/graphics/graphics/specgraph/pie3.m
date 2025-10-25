function hh = pie3(varargin)
    %PIE3   3-D pie chart.
    %   PIE3(X) draws a 3-D pie plot of the data in the vector X.  The
    %   values in X are normalized via X/SUM(X) to determine the area of
    %   each slice of pie.  If SUM(X) <= 1.0, the values in X directly
    %   specify the area of the pie slices.  Only a partial pie will be
    %   drawn if SUM(X) < 1.
    %
    %   PIE3(X,EXPLODE) is used to specify slices that should be pulled out
    %   from the pie.  The vector EXPLODE must be the same size  as X.  The
    %   slices where EXPLODE is non-zero will be pulled out.
    %
    %   PIE3(...,LABELS) is used to label each pie slice with cell array or
    %   string array LABELS.  LABELS must be the same size as X and can 
    %   only contain strings.
    %
    %   PIE3(AX,...) plots into AX instead of GCA.
    %
    %   H = PIE3(...) returns a vector containing patch, surface, and text
    %   handles.
    %
    %   Example
    %      pie3([2 4 3 5],[0 1 1 0],{'North','South','East','West'})
    %
    %   See also PIE.
    
    %   Clay M. Thompson 3-3-94
    %   Copyright 1984-2023 The MathWorks, Inc.
    
    % Parse possible Axes input
    [cax,args,nargs] = axescheck(varargin{:});
    
    txtlabels={};
    
    if nargs==0
        error(message('MATLAB:pie3:NotEnoughInputs'))
    elseif nargs > 3
        error(message('MATLAB:pie3:TooManyArguments'))
    end

    [args{:}] = convertStringsToChars(args{:});
    
    x = args{1}(:); % Make sure it is a vector
    args = args(2:end);
    
    if ~isnumeric(x)
        error(message('MATLAB:pie:NonNumericData'));
    elseif ~all(isfinite(x))
        error(message('MATLAB:pie:NonFiniteData'));
    elseif  isinteger(x)
        % Cast numeric integer data to double to assure trig functions that
        % compute the pie shape will not error.
        x = double(x); 
    end
    negative = (x < 0);
    if all(negative)
        error(message('MATLAB:pie:NoNonNegatveData'));
    end
    if any(negative)
        warning(message('MATLAB:pie:NegativeData'));
        x(negative) = [];
    end
    
    if nargs==1
        % syntax: pie3(X)
        explode = zeros(size(x));
    elseif nargs==2 && (isnumeric(args{1}) || islogical(args{1}))
        % syntax: pie3(X,explode)
        explode = args{1};
        explode = explode(:); % Make sure it is a vector
        if any(negative)
            explode(negative) = [];
        end
    elseif nargs==2 && (iscell(args{1}) || ischar(args{1}))
        % syntax: pie3(x,labels)
        explode = zeros(size(x));
        txtlabels = cellstr(args{1});
        if any(negative)
            txtlabels(negative) = [];
        end
    elseif nargs==3 && (isnumeric(args{1}) || islogical(args{1})) && ...
            (iscell(args{2}) || ischar(args{2}))
        % syntax: pie3(x,explode,labels)
        explode = args{1};
        explode = explode(:); % Make sure it is a vector
        if any(negative)
            explode(negative) = [];
        end
        txtlabels = cellstr(args{2});
        if any(negative)
            txtlabels(negative) = [];
        end
    else
        error(message('MATLAB:pie3:TooManyArguments'));
    end
    
    if sum(x) > 1+sqrt(eps), x = x/sum(x); end
    
    if ~isempty(txtlabels) && length(x)~=length(txtlabels)
        error(message('MATLAB:pie3:StringLengthMismatch'));
    end
    if length(x) ~= length(explode)
        error(message('MATLAB:pie3:ExplodeLengthMismatch'));
    end
    
    cax = newplot(cax);
    next = lower(get(cax,'NextPlot'));
    hold_state = ishold(cax);
    
    theta0 = pi/2;
    maxpts = 100;
    zht = .35;
    
    h = gobjects(1,length(x)*4);
    for i=1:length(x)
        n = max(1,ceil(maxpts*x(i)));
        r = [0;ones(n+1,1);0];
        theta = theta0 + [0;x(i)*(0:n)'/n;0]*2*pi;
        [xtext,ytext] = pol2cart(theta0 + x(i)*pi,1.25);
        [xx,yy] = pol2cart(theta,r);
        if explode(i)
            [xexplode,yexplode] = pol2cart(theta0 + x(i)*pi,.1);
            xtext = xtext + xexplode;
            ytext = ytext + yexplode;
            xx = xx + xexplode;
            yy = yy + yexplode;
        end
        theta0 = max(theta);
        if ~isempty(txtlabels)
            lab = txtlabels{i};
        elseif x(i)<.01 && x(i)~=0
            lab = '< 1%';
        else
            lab = [int2str(round(x(i)*100)) '%'];
        end
        z = zht(ones(size(xx)));
        p1 = patch('XData',xx,'YData',yy,'Zdata',zeros(size(xx)),...
            'CData',i*ones(size(xx)),'FaceColor','Flat','parent',cax);
        s1 = surface([xx,xx],[yy,yy],[zeros(size(xx)),z], ...
            i*ones(size(xx,1),2),'parent',cax);
        p2 = patch('XData',xx,'YData',yy,'Zdata',z, ...
            'CData',i*ones(size(xx)),'FaceColor','Flat','parent',cax);
        h(4*i-[3 2 1]) = [p1, s1, p2];
        
        % Turn off the legend icons for the patches so that there is one
        % legend icon (for the surface) that corresponds to each pie slice.
        p1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        p2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        if ~isempty(txtlabels)
            s1.DisplayName = txtlabels{i};
        end
        
        % position text so that labels near the front don't overlap the patches
        z = zht(ones(size(xtext)));
        if ~hold_state
            % the values of .3 and .8 are dependent on view(3) below
            z((ytext < 0.3) & (xtext < 0.8)) = 0;
        end
        
        h(4*i) = text(xtext,ytext,z, lab, ...
            'HorizontalAlignment','center','Layer','front','Parent',cax);
    end
    
    if ~hold_state
        set(cax,'NextPlot',next);
        axis(cax,'off','image',[-1.2 1.2 -1.2 1.2])
        view(cax,3)
    end

    if nargout>0, hh = h; end

    % Add MetaDataSevice flag
    if ~isprop(cax, 'FDT_Accessor')
        prop = addprop(cax, 'FDT_Accessor');
        prop.Transient = true;
        prop.Hidden = true;
    end
    
    cax.FDT_Accessor = 'pie3chart';
    
    % Register handles with code generator
    if ~isempty(h)
        if ~isdeployed
            makemcode('RegisterHandle',h,'IgnoreHandle',h(1),'FunctionName','pie3');
        end
    end
    
    % Disable default interactions
    disableDefaultInteractivity(h(1).Parent);
    if matlab.graphics.interaction.interactionoptions.useInteractionOptions(h(1).Parent)
        h(1).Parent.InteractionOptions.DatatipsSupported = false;
        h(1).Parent.InteractionOptions.ZoomSupported = false;
        h(1).Parent.InteractionOptions.PanSupported = false;
        h(1).Parent.InteractionOptions.RotateSupported = false;
    end
    set(hggetbehavior(h(1).Parent, 'DataCursor'), 'Enable', false);
    set(hggetbehavior(h(1).Parent, 'Zoom'), 'Enable', false);
    set(hggetbehavior(h(1).Parent, 'Pan'), 'Enable', false);
    set(hggetbehavior(h(1).Parent, 'Rotate3d'), 'Enable', false);
    
    
    setInteractionHint(h(1).Parent, 'DataCursor', false);
    
end
