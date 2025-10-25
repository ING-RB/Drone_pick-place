function hh = pie(varargin)
%PIE    Pie chart.
%   PIE(X) draws a pie chart using the data in X. Each slice of the pie
%   chart represents an element in X.
%
%      If sum(X)<= 1, then the values in X directly specify the areas of the
%      pie slices. PIE draws only a partial pie if sum(X) < 1.
%
%      If sum(X) > 1, then PIE normalizes the values by X/sum(X) to
%      determine the area of each slice of the pie.
%      
%      If X is of data type categorical, the slices correspond to categories.
%      The area of each slice is the number of elements in the category 
%      divided by the number of elements in X. 
%
%   PIE(X,explode) offsets slices from the pie. explode is a vector or
%   matrix of zeros and nonzeros that correspond to X. The PIE function
%   offsets slices for the nonzero elements only in explode. If X is of
%   data type categorical, then explode can be a vector of zeros and
%   nonzeros corresponding to categories, or a cell array of the names of
%   categories to offset.
%
%   PIE(X,labels) specifies text labels for the slices. X must be numeric.
%   Labels can be specified as an array, in which case the number of labels
%	must equal the number of elements in X, or as a valid format string
%	which will be applied to percentage values for each slice in the pie.
%
%   PIE(X,EXPLODE,LABELS) offsets slices and specifies text labels for
%   them. X can be numeric or categorical. The number of labels must equal 
%	the number of elements in X or be a valid format string.
%
%   PIE(ax,...) plots into the axes specified by ax instead of into the
%   current axes (gca). The option ax can precede any of the input argument
%   combinations in the previous syntaxes.
%
%   p = PIE(...) returns a vector of patch and text graphics objects. The
%   input can be any of the input argument combinations in the previous
%   syntaxes.
%
%   Examples
%   --------
%   Create a pie chart from a numeric array with labels:
%      pie([2 4 3 5],{'North','South','East','West'})
%
%   Create a pie chart from a numeric array with label, and offset slices
%   'North' and 'South' using a logical vector:
%      pie([2 4 3 5],[true true false false],{'North','South','East','West'})
%
%   Create a pie chart from a categorical array, and offset categories 
%   'North' and 'South' using category names:
%      X = categorical({'North','South','North','East','South','West'});
%      pie(X, {'North','South'});
%
%   See also PIE3.

%   Clay M. Thompson 3-3-94
%   Copyright 1984-2023 The MathWorks, Inc.

% Parse possible Axes input
[cax, args, nargs] = axescheck(varargin{:});
if nargs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif nargs > 3
    error(message('MATLAB:narginchk:tooManyInputs'));
end

[args{:}] = convertStringsToChars(args{:});

% Parse PIE inputs
[sliceCounts, explode, labels, displayNames] = parseArgs(args, nargs);

% Construct PIE and set display name for default legend labels
h = makePie(cax, sliceCounts, explode, labels);
if ~isequal(displayNames, {})
    set(h(isgraphics(h,'patch')), {'DisplayName'}, displayNames);
end

% Register handles with MATLAB code generator
if ~isempty(h)
    if ~isdeployed
        makemcode('RegisterHandle',h,'IgnoreHandle',h(1),'FunctionName','pie'); 
    end 
end

% Make it so that users are unable to enable Pan, Zoom, and DataTips
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

% Disable default interactions
disableDefaultInteractivity(h(1).Parent)

setInteractionHint(h(1).Parent, 'DataCursor', false);

% Return handle if requested
if nargout>0, hh = h; end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%% HELPER PARSEARGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [sliceCounts, explode, labels, displayNames] = parseArgs(args, numArgs)
    inData = args{1}(:); % Make sure it is a vector
    isCategoricalData = isa(inData, 'categorical');
    
    explode = {};
    supplied.explode = false;
    
    labels  = {};    
    supplied.labels  = false;
    
    switch numArgs
        case 1 % pie(x)
            % Nothing to do
        case 2 % pie(x,explode) | pie(x,labels) x cannot be categorical
            if isCategoricalData
                explode = args{2};
                supplied.explode = true;
            else
                if iscell(args{2}) || ischar(args{2})
                    labels = args{2};
                    supplied.labels = true;
                else
                    explode = args{2};
                    supplied.explode = true;
                end
            end
        case 3 % pie(x, explode labels)
            explode = args{2};
            supplied.explode = true;
            
            labels  = args{3};
            supplied.labels  = true;
    end 
    
    try
        [sliceCounts, ignoreIdx] = validateData(inData);
        explode = validateExplode(explode, supplied.explode, ignoreIdx, sliceCounts, inData);
        [labels, displayNames] = validateLabels(labels, supplied.labels, ignoreIdx, sliceCounts, inData);
    catch ME
        throwAsCaller(ME);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% HELPER VALIDATEDATA %%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data, negativeIdx] = validateData(data)
isDataCategorical = isa(data,'categorical');
if isDataCategorical
    if isempty(data) || all(isundefined(data))
        throwAsCaller(MException(message('MATLAB:pie:InvalidData')));
    else
        data = countcats(data);
    end
elseif isnumeric(data) && isinteger(data)
    % Cast numeric integer data to double to assure trig functions that
    % compute the pie shape will not error.
    data = double(data);
end

if ~isnumeric(data)
    throwAsCaller(MException(message('MATLAB:pie:NonNumericData')));
elseif ~all(isfinite(data))
    throwAsCaller(MException(message('MATLAB:pie:NonFiniteData')));
end
negativeIdx = (data < 0);
if all(negativeIdx)
    throwAsCaller(MException(message('MATLAB:pie:NoNonNegatveData')));
end
if any(negativeIdx)
    data(negativeIdx) = [];
    
    if ~isDataCategorical
        warnState = warning('off','backtrace');
        restoreWarnState = onCleanup(@()warning(warnState));
        warning(message('MATLAB:pie:NegativeData'));
    end
end
dataSum = sum(data);
if dataSum > 1+sqrt(eps), data = data/dataSum; end
end

%%%%%%%%%%%%%%%%%%%%%%%%% HELPER VALIDATEEXPLODE %%%%%%%%%%%%%%%%%%%%%%%%%%
function explode = validateExplode(explode, supplied, ignoreIdx, sliceCounts, inData)

if supplied
    % If explode is specified as a list of category names (supported only by
    % categorical pie), convert into a logical vector.
    if iscategorical(inData) && matlab.internal.datatypes.isCharStrings(explode)
        if ~all(iscategory(inData,explode)) 
            throwAsCaller(MException(message('MATLAB:pie:InvalidExplodeName')));
        end
        explode = ismember(categories(inData), explode);
    end

    % Categorical pie has a special error message for invalid data type.
    if iscategorical(inData) && ~(islogical(explode) || (isnumeric(explode) && all(isfinite(explode))))
        throwAsCaller(MException(message('MATLAB:pie:InvalidExplodeType')));
    end

    % Numeric pie requires logical or numeric explode values
    if  isnumeric(inData) && ~(islogical(explode) || isnumeric(explode))
        throwAsCaller(MException(message('MATLAB:pie:InvalidExplodeTypeNumeric')))
    end
    
    % Make sure it is a logical vector.
    explode = logical(explode(:));
    
    % Make sure it is the right size.
    if isempty(explode)
        explode = false(size(ignoreIdx));
    elseif numel(ignoreIdx) ~= numel(explode)
        if iscategorical(inData)
            throwAsCaller(MException(message('MATLAB:pie:InvalidExplodeLogical')));
        else
            throwAsCaller(MException(message('MATLAB:pie:ExplodeLengthMismatch')));
        end
    end
    
    % Remove unoccupied slices.
    explode(ignoreIdx) = [];
else
    % No explode input provided.
    explode = false(numel(sliceCounts),1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%% HELPER VALIDATELABEL %%%%%%%%%%%%%%%%%%%%%%%%%%%
function [labels, displayNames] = validateLabels(labels, supplied, ignoreIdx, sliceCounts, inData)

useFormat=false;
if ischar(labels) || (isscalar(labels) &&  iscellstr(labels)) %#ok<ISCLSTR> 
    labels=cellstr(labels);
    try  %#ok<TRYNC>
        % hgcastvalue to confirm that this is a valid formatting operator
        hgcastvalue('matlab.graphics.datatype.PrintfFormat',labels{1});
        useFormat=true;
        supplied=false;
    end
end

if supplied
    if iscategorical(inData)
        if ~( iscellstr(labels) && all(cellfun(@(x)size(x,1),labels)==1) ) || ...
                numel(ignoreIdx) ~= numel(labels) 
            throwAsCaller(MException(message('MATLAB:pie:InvalidLabel')));
        end
        displayNames = categories(inData);
    else
        if ~iscellstr(labels) 
            throwAsCaller(MException(message('MATLAB:pie:InvalidLabels')));
        elseif numel(ignoreIdx) ~= numel(labels)
            throwAsCaller(MException(message('MATLAB:pie:StringLengthMismatch')));
        end
        displayNames = labels(:);
    end
    labels(ignoreIdx) = [];
    displayNames(ignoreIdx) = [];
else
    if iscategorical(inData)
        catNames = categories(inData);
        catNames(ignoreIdx) = [];
        if useFormat
            fmt=[' ' labels{1}];
        else
            fmt=' (%.0f%%)';
        end
        percentageStrings = compose(fmt,100*sliceCounts./sum(sliceCounts));
        labels = strcat(catNames(:), percentageStrings(:));
        
        displayNames = catNames;
    else
        if useFormat
            fmt=labels{1};
        else
            fmt='%.0f%%';
        end
        
        for i=1:length(sliceCounts)
            if sliceCounts(i)<.01 && sliceCounts(i)~=0
                labels{i} = '< 1%';
            else
                labels{i} = sprintf(fmt,sliceCounts(i)*100);
            end
        end
        displayNames = {};
    end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HELPER MAKEPIE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = makePie(cax, x, explode, labels)
% Make patches
cax = newplot(cax);
next = lower(get(cax,'NextPlot'));
hold_state = ishold(cax);

% Add MetaDataSevice flag
if ~isprop(cax, 'FDT_Accessor')
    prop = addprop(cax, 'FDT_Accessor');
    prop.Transient = true;
    prop.Hidden = true;
end

cax.FDT_Accessor = 'piechart';

theta0 = pi/2;
maxpts = 100;

% Labels along the top of the pie chart (from angle 67.5 to 112.5 degrees)
% and bottom of the chart (247.5 to 292.5 degrees) are center-aligned. To
% make sure they do not overlap the pie, extend the radius enough that they
% will not overlap. Calculation: 1/cos(22.5) ~= 1.08.
labelRadius = 1.1;
explodeRadius = 0.1;

h = [];
for i=1:length(x)
    n = max(1,ceil(maxpts*x(i)));
    r = [0;ones(n+1,1);0];
    theta = theta0 + [0;x(i)*(0:n)'/n;0]*2*pi;
    centerTheta = theta0 + x(i)*pi;
    [xtext,ytext] = pol2cart(centerTheta,labelRadius);
    [halign,valign] = getAlignmentFromAngle(centerTheta);
    [xx,yy] = pol2cart(theta,r);
    if explode(i)
        [xexplode,yexplode] = pol2cart(theta0 + x(i)*pi,explodeRadius);
        xtext = xtext + xexplode;
        ytext = ytext + yexplode;
        xx = xx + xexplode;
        yy = yy + yexplode;
    end
    theta0 = max(theta);
    h = [h,...
        patch('XData',xx,'YData',yy,'CData',i*ones(size(xx)), ...
            'FaceColor','Flat','parent',cax), ...
        text(xtext,ytext,labels{i},...
            'HorizontalAlignment',halign,'VerticalAlignment',valign,...
            'Parent',cax,'Layer','front')]; %#ok<AGROW>
end

if ~hold_state
    view(cax,2); set(cax,'NextPlot',next);
    axis(cax,'equal','off',[-1.2 1.2 -1.2 1.2])
end
end

function [halign, valign] = getAlignmentFromAngle(angle)
% Determine the text label alignment based on the angle around the circle.

% Convert the angle to degrees
angle = (180/pi)*angle;

% Round the angles to the nearest 45 degrees
angle = mod(round(angle/45)*45,360);

% Determine the horizontal alignment
if angle == 90 || angle == 270
    halign = 'center';
elseif angle > 90 && angle < 270
    halign = 'right';
else
    halign = 'left';
end

% Determine the vertical alignment
if angle == 0 || angle == 180
    valign = 'middle';
elseif angle > 180 && angle < 360
    valign = 'top';
else
    valign = 'bottom';
end

end
