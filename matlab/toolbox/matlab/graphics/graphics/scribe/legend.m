function varargout = legend(varargin)
% LEGEND Create legend
% 
% LEGEND creates a legend with descriptive labels for each plotted data
% series. For the labels, the legend uses the text from the DisplayName
% properties of the data series. If the DisplayName property is empty, then
% the legend uses a label of the form 'dataN'. The legend automatically
% updates when you add or delete data series from the axes. This command
% creates a legend for the current axes or chart returned by gca. If the
% current axes is empty, then the legend is empty. If axes do not exist,
% then this command creates one.
%
% LEGEND(label1,...,labelN) sets the labels. Specify the labels as a list
% of character vectors, such as legend('Jan','Feb','Mar'). When you specify
% a label as an empty character vector or an empty string, the
% corresponding entry is omitted from the legend.
%
% LEGEND(labels) sets the labels using a cell array of character vectors or
% a character matrix, such as legend({'Jan','Feb','Mar'}). When you specify
% a label as an empty element in a cell array or string array, the
% corresponding entry is omitted from the legend.
%
% LEGEND(subset,__) only includes items in the legend for the data series
% listed in subset. Specify subset as a vector of graphics objects.
%
% LEGEND(target,__) uses the axes, polar axes, or chart specified by target
% instead of the current axes or chart. Specify the target as the first
% input argument. 
%
% LEGEND(__,'Location',lcn) sets the legend location. For example,
% 'Location','northeast' positions the legend in the upper right corner of
% the axes. Specify the location after other input arguments.
%
% LEGEND(__,'Orientation',ornt), where ornt is 'horizontal', displays the
% legend items side-by-side. The default for ornt is 'vertical', which
% stacks the items vertically. 
%
% LEGEND(__,Name,Value) sets legend properties using one or more name-value
% pair arguments. When setting properties, include the labels in a cell
% array, such as legend({'A','B'},'FontSize',12). If you do not want to
% specify labels, then include an empty cell array, such as
% legend({},'FontSize',12). Reissuing the legend command retains
% modifications that you previously specified.
%
% LEGEND(bkgd), where bkgd is 'boxoff', removes the legend background and
% outline. The default for bkgd is 'boxon', which displays the legend
% background and outline. 
%
% lgd = LEGEND(__) returns the Legend object. Use lgd to query and set
% properties of the legend after it is created. For a list of properties,
% see Legend. 
%
% LEGEND(vsbl) controls the visibility of the legend, where vsbl is 'hide',
% 'show', or 'toggle'. 
%
% LEGEND('off') deletes the legend.
%
%  
%     Examples:
%         x = 0:.2:12;
%         Y = [besselj(1,x); besselj(2,x); besselj(3,x)];
%         plot(x,Y);
%         legend('First','Second','Third','Location','NorthEastOutside')
%  
%         b = bar(rand(10,5),'stacked'); 
%         hold on
%         ln = plot(1:10,5*rand(10,1),'-o'); 
%         hold off
%         legend([b,ln],'Carrots','Peas','Peppers','Green Beans',...
%                   'Cucumbers','Eggplant')

%   Unsupported APIs for internal use:
%
%   LOC strings can be abbreviated NE, SO, etc or lower case.
%
%   LEGEND(LI,string1,string2,string3) creates a legend for legendinfo
%   objects LI with strings string1, etc.
%   LEGEND(LI,M) creates a legend for legendinfo objects LI where M is a
%   string matrix or cell array of strings corresponding to the legendinfo
%   objects.

%   Copyright 1984-2024 The MathWorks, Inc.

% Legend no longer supports more than one output argument
% Warn the user and ignore additional output arguments.

args = varargin;

% Continue warning that the v6 form will go away in the future.
if (nargin > 1 ...
        && istextscalar(args{1}) ...
        && ~istextscalar(args{2}) ...
        && strcmp(args{1},'v6'))
    warning(message('MATLAB:legend:DeprecatedV6Argument'));
end

%--------------------------------------------------------
% Begin building the legend
%--------------------------------------------------------
narg = nargin;

% HANDLE FINDLEGEND CASES FIRST
if narg==2 ...
        && istextscalar(args{1}) ...
        && strcmpi(args{1},'-find') ...
        && isscalar(args{2}) ...
        && isgraphics(args{2},'matlab.graphics.axis.AbstractAxes')

    varargout = setOutArgs(args{2}, nargout);
    return
end

% add flag to create compatible legend
version = 'off';
if nargout > 1
    warning(message('MATLAB:legend:DeprecationCompatibleLegend'));
    version = 'on';
end

arg = 1;

% GET AXES FROM INPUTS
ha = matlab.graphics.Graphics.empty;

% if the user passes in an axes that is not the current axes we want to be
% sure to restore the current axes before exiting.
old_currfig = get(0,'CurrentFigure');
if isscalar(old_currfig) && isgraphics(old_currfig)
    old_currax = get(old_currfig,'CurrentAxes');
    if isscalar(old_currax)
        ha = old_currax;
    end
end

if narg > 0  && ...
        ~isempty(args{1}) && ...
        isscalar(args{1}) && ...
        isgraphics(args{1},'matlab.graphics.mixin.LegendTarget')
    % legend(ax,...)
    % ha is an Axes at this point
    ha = handle(args{1});
    arg = arg + 1;
elseif narg > 0 && ...
        ~istextscalar(args{1}) && ...
        ~isempty(args{1}) && ...
         all(isgraphics(args{1}), 'all') % legend(children,strings,...)
    obj = args{1}(1);
    ha = ancestor(obj,'matlab.graphics.axis.AbstractAxes');
    if isempty(ha)
        if ~isempty(obj) % Provide a better error message if we can.
            error(message('MATLAB:legend:InvalidPeerHandle', getClassName(obj)));
        else
            error(message('MATLAB:legend:InvalidPeerParameter'));
        end
    end
else
    % if no axes has been identified thus far, create one using GCA.      
    if isempty(ha)
        if strcmp(version,'on')
            % Legacy behavior for compatible legend
            warning(message('MATLAB:legend:NoCurrentAxes'));
            varargout = setOutArgs(ha, nargout);
            return
        else
            % if ha is empty, use GCA, which will create an axes if necessary.
            ha = gca;
        end
    else
        % Chart subclass support
        % Invoke legend method with same number of outputs to defer output arg
        % error handling to the method.
        if isa(ha,'matlab.graphics.chart.Chart')
            try
                [varargout{1:nargout}] = legend(ha,args{:});
            catch e
                throw(e)
            end
            return
        end
    end
end

% cast double to MCOS handle
if ~isobject(ha)
    ha = handle(ha);
end

% PROCESS REMAINING INPUTS
if narg < arg % legend or legend(ax)
    if ~isempty(find_legend(ha)) || strcmp(version,'on')
        if nargout > 0
            varargout = setOutArgs(ha, nargout);
        end
        return;
    end
end

if narg >= arg && ...
   istextscalar(args{arg}) && ...
   all(ismember(char(lower(args{arg})),{'off','deletelegend',...
                                        'resizelegend',...
                                        'toggle','show','hide',...
                                        'boxon','boxoff'}))
    
    switch char(lower(args{arg}))
        case {'off', 'deletelegend'}
            delete_legend(find_legend(ha));
        case 'resizelegend'
            % pass
        case 'toggle'
            l = find_legend(ha);
            if isempty(l) || strcmpi(get(l, 'Visible'), 'off')
                tog = legend(ha, 'show');
                tog.VisibleMode = 'manual';
            else
                legend(ha, 'hide');
            end
        case 'show'
            l = find_legend(ha);
            if isempty(l)
                make_legend(ha, args(arg+1:end), version);
            else
                set(l, 'Visible', 'on','VisibleMode','auto');
            end
        case 'hide'
            set(legend(ha), 'Visible', 'off');
        case 'boxon'
            set(legend(ha), 'Box', 'on');
        case 'boxoff'
            set(legend(ha), 'Box', 'off');
        otherwise
            assert(false,'make sure there is a case for each item in the ismember check above')
    end
else % narg > 1
    % legend(<string>,...)
    % legend(<charMatrix>,...)
    % legend(<cellStr>,...)
    % legend(p,...)
    % legend(p,<string>,...)
    % legend(p,<charMatrix>,...)
    % legend(p,<cellStr>,...)
    % legend('Location',<value>)
    % legend('Orientation',<value>)
    % legend('AutoUdpate',<value>)
    make_legend(ha,args(arg:end),version);
end

% PROCESS OUTPUTS
if nargout>0
    varargout = setOutArgs(ha, nargout);
end

% before going, be sure to reset current figure and axes
if isscalar(old_currfig) && isgraphics(old_currfig) && ~strcmpi(get(old_currfig,'beingdeleted'),'on')
    set(0,'CurrentFigure',old_currfig);
    if isscalar(old_currax) && isgraphics(old_currax) && ~strcmpi(get(old_currax,'beingdeleted'),'on')
        set(old_currfig,'CurrentAxes',old_currax);
    end
end

%----------------------
% Helper functions
%----------------------

%----------------------------------------------------%
function make_legend(ha,argin,version_flag)

leg = find_legend(ha);

% Always create a new legend if the user has requested a compatible legned
% or if the existing legend is a compatible legend
if strcmp(version_flag,'on') || strcmp(get(leg,'version'),'on')
    delete(leg)
    leg = [];
end

new_legend = false;
if isempty(leg)
    new_legend = true;
    leg = matlab.graphics.illustration.Legend;
    leg.doPostSetup(version_flag);
    leg.Visible_I = 'off';
else
    % For existing legends, make sure the ALM is dirty as a result of this
    % legend call. We don't need to do this if the legend is in a layout
    if ~isa(leg.Parent, 'matlab.graphics.layout.Layout')
        hManager  = matlab.graphics.shape.internal.AxesLayoutManager.getManager(leg.Axes);
        doMarkDirty(hManager);
    end
end

try
    % process input args
    [propargs, ch, strings] = process_inputs(leg,ha,argin, new_legend);
catch ME
    throwAsCaller(ME);
end

if new_legend
    try
        fig = ancestor(ha,'figure');
        parent = get(ha,'Parent');

        if strcmp(get(ha,'color'),'none')
            leg.Color_I = get(fig,'Color');
        else
            leg.Color_I = get(ha,'Color');
        end
        leg.TextColor_I = get(parent,'DefaultTextColor');
        leg.EdgeColor_I = get(parent,'DefaultAxesXColor');

        % apply 3D default
        if ~lcl_is2D(getGraphicsAxes(leg,ha))
            leg.Location_I = 'northeastoutside';
        elseif isa(ha, 'matlab.graphics.axis.PolarAxes')
            leg.Location_I = 'eastoutside';
        end
        
        % set the peer axes
        leg.Axes = ha;
        
        % disable AutoUpdate for plotyy
        if matlab.graphics.illustration.internal.isplotyyaxes(ha)
            % Make sure the discovered plotyy children don't get
            % overwritten by the autoUpdateCallback during the update
            % triggered by setting AutoUpdate to 'off';
            % The callback can only see children of the primary axes.
            leg.PlotChildrenSpecified = leg.PlotChildren_I;
            leg.AutoUpdate = 'off';
        end
    catch
        leg.Axes = [];
        delete(leg);
        return
    end
end

% set DisplayNames
setDisplayNames(ch,strings);

% Set the VisibleMode to 'auto' so that on subsequent calls to legend()
% with input arguments we can turn the legend visibility back on if it's
% not explicitly set.
set(leg, 'VisibleMode', 'auto');

% set user-specified PV pairs
if ~isempty(propargs)
    set(leg,propargs{:});
end

% If the user didn't explicitly set the Visible to 'off' the current call
% to legend, make sure to turn it back to 'on', otherwise honor it.
if strcmp(leg.VisibleMode, 'auto')
    set(leg,'Visible_I','on');
end

%----------------------------------------------------%
function tryAddingWarningAboutLabelAmbiguity(labelsInArray,fewerStringsThanPlots,prop)
% Display extra waning about label ambiguity to assit with potential
% incompatibilities after the 18b legend PV pair support enhancement
if ~labelsInArray && fewerStringsThanPlots
    s = warning('off','backtrace');
    warning(message('MATLAB:legend:CellArrayLabels',prop));
    warning(s); %CellArrayLabels
end

%----------------------------------------------------%
function delete_legend(leg)

if isscalar(leg) && isgraphics(leg) && ~strcmpi(get(leg,'beingdeleted'),'on')
    delete(leg);
end

%----------------------------------------------------%
function leg = find_legend(ha)

% Using the Legend property of ha, we will find the legend peered to
% the current axes.
if isempty(ha) || ~isgraphics(ha)
    leg = gobjects(0);
    return;
end

% get the graphics Axes so we can handle the plotyy case generally
leg = matlab.graphics.illustration.Legend.empty;
ha = getGraphicsAxes(leg,ha);

% If we have the submissive plotyy axes, get the real one
if isappdata(ha,'graphicsPlotyyPeer') && ...
        ~isempty(getappdata(ha,'graphicsPlotyyPeer')) && ...
        isvalid(getappdata(ha,'graphicsPlotyyPeer')) && ...
        strcmp(ha.Color,'none')
    ha = getappdata(ha,'graphicsPlotyyPeer');
end

leg = ha.Legend;

%-----------------------------------------------------%
function [leg,hobjs,outH,outM] = find_legend_info(ha)

leg = find_legend(ha);

if ~isempty(leg) && strcmp(leg.version,'on')
    drawnow;
    outH = leg.PlotChildren_I;
    outM = leg.String_I(:).';
    hobjs = [leg.ItemText(:); leg.ItemTokens(:)];
else
    outH = [];
    outM = [];
    hobjs = [];
end


%----------------------------------------------------%
function prop_names = get_legend_properties(leg)
% Return a list of all valid legend properties including deprecated, compatibility-only
% properties such as 'UIContextMenu'.
prop_names = properties(leg);
prop_names{end+1} = 'UIContextMenu';


%----------------------------------------------------%
function [propargs, ch, strings] = process_inputs(leg,ax,argin,new_legend)



propargs = {}; % user-specified PV pairs
ch = [];
strings = {};


% @TODO - we need to remove this or start deprecating it.  We have 4
% options:
% 	a) do nothing: explicitly ignore ?-DynamicLegend?, i.e. remove it from the input args and continue (16a behavior).  If we do this the 16b behavior will actually be compatible with 14a, but in spite of ?-DynamicLegend? and not because of it.
% 	b) same as a), but also WARN that this arg is not longer needed because ?AutoUpdate? ?on? is the new default behavior.
% 	c) completely ignore ?-DynamicLegend?, legend(?-DynamicLegend?) will produce one item with this string, but also WARN
% 	d) completely ignore ?-DynamicLegend?, and don?t even WARN since this was never documented syntax.
if ~isempty(argin) && istextscalar(argin{1}) && strcmpi(argin{1},'-DynamicLegend')
    argin(1) = [];
    if isempty(argin)
        return;
    end
end

% Find PV Paris - assume any valid Legend property is the start of the P/V
% pair list
labelsInArray = false;
children = [];
if ~isempty(argin)
    fieldnames = lower(get_legend_properties(leg));
    for i=1:numel(argin)
        arg = argin{i};
        if istextscalarvector(arg) && ismember(lower(arg),fieldnames)
            propargs = argin(i:end);
            argin = argin(1:i-1);
            break
        end
    end

    if ~isempty(argin)
        % Process leading (non-PV pair) inputs and determine strings, children and options
        n = 1;
        nargs = numel(argin);
        
        while n <= nargs
            if istextscalar(argin{n})
                strings{end+1} = char(argin{n}); %#ok<AGROW> % single item string
            elseif isnumeric(argin{n}) && isvector(argin{n}) && numel(argin{n})==4 && ...
                    (n > 1 || ~all(isgraphics(argin{n})))
                % to use position vector either it must not be the first argument,
                % or if it is, then the values must not all be handles - in which
                % case the argument will be considered to be the plot children
                % This is an undocumented API for backwards compatibility with
                % Basic Fitting.
                position = argin{n};
                fig = ancestor(ax,'figure');
                position = hgconvertunits(fig,position,'points','normalized', fig);
                center = position(1:2)+position(3:4)/2;
                % .001 is a small number so that legend will resize to fit and centered
                position = [center-.001 0.001 0.001];
                propargs = [propargs, {'Position'}, {position}]; %#ok<AGROW>
                propargs = [propargs, {'Location'}, {'none'}]; %#ok<AGROW>
            elseif iscell(argin{n}) || isstring(argin{n})|| iscategorical(argin{n})
                labelsInArray = true; 
                if iscategorical(argin{n})
                    argin{n} = string(argin{n});
                end
                strings = cellstr(argin{n});
                % prepend any remaining elements of argin to propargs
                if n < nargs
                    propargs = [argin(n+1:end),propargs]; %#ok<AGROW>
                    break;
                end
            elseif n==1 && all(isgraphics(argin{n}),'all')
                % found handles to put in legend
                % make sure to return objects, not doubles
                children=handle(argin{n});
            elseif n == 1 && isa(argin{1},'matlab.graphics.Graphics') && ~all(isvalid(argin{1}))
                error(message('MATLAB:legend:InvalidGraphicsHandle'));
            else
                error(message('MATLAB:legend:UnknownParameter'));
            end
            n = n + 1;
        end
        strings = strings(:).';
    end
end


% Process plot children and legend labels
fewerStringsThanPlots = false;
internalPropArgs = {};
removeEntries = false;
if ~isempty(children) || ~isempty(strings) || new_legend
    % process children and strings if either:
    %   - children or strings are passed in
    %   - a new legend is being created
    % this call removes all items from an existing legend
    
    if ~isempty(children)
        % check that all children from user are Legendable
        validateLegendable(children);
        auto_children = false;
        ch = children;

        [~, ch_exclude] = matlab.graphics.illustration.internal.getLegendableChildren(ax,ch);
    else
        % if isempty(children), get children from axes
        auto_children = true;
        ch = matlab.graphics.illustration.internal.getLegendableChildren(ax);
        ch_exclude = [];
    end

    leg.LimitMaxLegendEntries = auto_children;

    % make sure we have column vectors
    ch = ch(:);
    ch_exclude = ch_exclude(:);

    % if str is empty, create strings
    if isempty(strings)
        if auto_children && length(ch) > 50
            % only automatically add first 50 to cut down on huge lists
            ch = ch(1:50);
            if ~leg.HasWarnedAboutMaxEntryCapping
                warning(message('MATLAB:legend:CappingMaxEntries'));
                leg.HasWarnedAboutMaxEntryCapping = true;
            end
        end
        % flag when the user specifies fewer label strings than there are
        % legendable children.  This may be used in make_legend to provide
        % extra warning information.
        if numel(strings) < numel(ch)
            fewerStringsThanPlots = true;
        end
    else
        % expand strings if possible
        % legend(p(1:2),['a';'b'])
        if (length(ch) ~= 1) && isscalar(strings) && (size(strings{1},1) > 1)
            strings = cellstr(strings{1});
        end

        % trim children or strings
        num_str = numel(strings);
        num_ch = numel(ch);
        % flag when the user specifies fewer label strings than there are
        % legendable children.  This may be used in make_legend to provide
        % extra warning information.
        if num_str < num_ch
            fewerStringsThanPlots = true;
        end
        if num_str ~= num_ch
            if ~auto_children || num_str > num_ch
                warning(message('MATLAB:legend:IgnoringExtraEntries'));
            end
            if num_str > num_ch
                % user passed in more labels than objects 
                strings = strings(1:num_ch);
            else
                % user passed in more objects than strings
                % add extra objects to the exclude list
                ch_exclude = [ch_exclude; ch(num_str+1:end)];
                ch = ch(1:num_str);
            end
        end
        
        % use empty strings provided by user to exclude corresponding
        % object from the legend.
        if auto_children
            indicesToExclude = false(1,numel(strings));
            
            % We only want to exclude the object from the legend if it's
            % empty char or string of length zero. Skip over multi-line
            % strings.
            for i = 1:numel(strings)
                indicesToExclude(i) = isequal(string(strings{i}),"");
            end

            ch_exclude = [ch_exclude; ch(indicesToExclude)];
            strings = strings(~indicesToExclude);
            ch = ch(~indicesToExclude);
        end

    end
    
    internalPropArgs = [internalPropArgs,{'PlotChildren_I'},{ch}];
    internalPropArgs = [internalPropArgs,{'PlotChildrenExcluded_I'},{ch_exclude}];
    internalPropArgs = [internalPropArgs,{'PlotChildrenSpecified'},{[]}];
    if ~auto_children
        internalPropArgs = [internalPropArgs,{'PlotChildrenSpecified'},{ch}];
    end
    
    removeEntries = true; 
end

%%%%% Error checking before setting any state on legend

% validate and process user-specified PV pairs
if ~isempty(propargs)
    % create local vars to support handling of special Location values
    % farther down.
    locations = {};
    locationAbbrevs = {};
    
    for i = 1: length(propargs)
        try
            pstr = string(propargs{i});
            if any(strcmpi(string(pstr),'location'))
                % Get location strings long and short form. The short form is the
                % long form without any of the lower case characters.
                % hard code the enumeration values until we can query the datatype directly
                locations = ["North","South","East","West","NorthEast","SouthEast",...
                    "NorthWest","SouthWest","NorthOutside","SouthOutside","EastOutside",...
                    "WestOutside","NorthEastOutside","SouthEastOutside","NorthWestOutside",...
                    "SouthWestOutside","Best","BestOutside","none"];
                locationAbbrevs = cell(1,length(locations));
                for k=1:length(locations)
                    str = locations{k};
                    locationAbbrevs{k} = str(str>='A' & str<='Z');
                end
            end
        catch
        end
    end


    % check that every p is a property
    % check for special Location values
    numPropArgs = numel(propargs);
    for i=1:2:numPropArgs
        if ~any(strcmpi(fieldnames,propargs{i}))
            tryAddingWarningAboutLabelAmbiguity(labelsInArray,fewerStringsThanPlots,propargs{1});
            keywords = {'off','deletelegend','resizelegend','toggle',...
                    'show','hide','boxon','boxoff'};
            if any(strcmpi(keywords ,propargs{i}))
                errorMessage = 'MATLAB:legend:InvalidKeywordInput';
            else
                errorMessage = 'MATLAB:legend:UnknownProperty';
            end

            try
                m = message(errorMessage, ['''' propargs{ i } '''']);
            catch 
                m = message(errorMessage, '');
            end
            throw(MException(m));
        end

        % Look for (...,'Location',POS) or (...,'Location',LOCATION_ABBREV)
        if strcmpi(propargs{i},'location')
            if i < numPropArgs
                if isnumeric(propargs{i+1}) && length(propargs{i+1})==4
                    % found 'Location', POS
                    position = propargs{i+1};
                    propargs{i+1} = 'none'; %#ok<AGROW>
                    propargs = [propargs, {'Position'},{position}]; %#ok<AGROW>
                elseif istextscalar(propargs{i+1})
                    abbrevsCmp = strcmpi(propargs{i+1}, locationAbbrevs);
                    if any(abbrevsCmp)
                        % found 'Location', ABBREV
                        propargs{i+1} = locations{abbrevsCmp}; %#ok<AGROW>
                    end
                end
            end
        end
    end
end






lcl_propargs = propargs;
if ~isempty(lcl_propargs)
    % first handle odd number of PV pairs
    if mod(numel(lcl_propargs),2) == 1
        tryAddingWarningAboutLabelAmbiguity(labelsInArray,fewerStringsThanPlots,lcl_propargs{1});
        throw(MException(message('MATLAB:legend:NameValueMismatch')));
    end
    % now try setting the pv pairs.  If the first pv pair errors try to add
    % a helpful warning since it may be because they meany the property to
    % be interpreted as a label.
    tmp_leg = matlab.graphics.illustration.Legend;
    try
        set(tmp_leg,lcl_propargs{1:2});
        lcl_propargs(1:2) = [];
    catch ME
        delete(tmp_leg);
        tryAddingWarningAboutLabelAmbiguity(labelsInArray,fewerStringsThanPlots,lcl_propargs{1});
        throw(ME);
    end
    % set remaining pv pairs, if any
    if ~isempty(lcl_propargs)
        try
            set(tmp_leg,lcl_propargs{:});      
        catch ME
            delete(tmp_leg);
            throw(ME);
        end
    end
    delete(tmp_leg);
end

% update legend state
if ~isempty(internalPropArgs)
    set(leg,internalPropArgs{:});
end
if removeEntries
    removeAllEntries(leg);   
end

%----------------------------------------------------------------%
function setDisplayNames(ch,strings)

if ~isempty(ch)
    if ~isempty(strings)
        for k=1:length(ch)
            displayNameStr = deblank(strings{k});
            % If the strings provided are a CHAR matrix, then we must split
            % them up using \n characters into a single char. g964785
            if ~isempty(displayNameStr) && ~isvector(displayNameStr)
                tempDisplayStr = deblank(displayNameStr(1,:));
                for l = 2:size(displayNameStr,1)
                   tempDisplayStr = sprintf('%s\n%s', tempDisplayStr, deblank(displayNameStr(l,:)));
                end
                displayNameStr = tempDisplayStr;
            end
            % Use 'set' instead of dot notation so that
            % default/factory/remove are treated as special keywords.
            set(ch(k),'DisplayName', displayNameStr);
        end
    end
end

%----------------------------------------------------------------%
function validateLegendable(children)

% Objects input by user must be Legendable
if ~isempty(children)
    allLegendable = true;
    for i=1:numel(children)
        % isa operates on the class of the hetarray, not the individual
        % elements of the array.  So it cannot be used to check an array of
        % graphics objects against a mixin.
        if ~isa(children(i),'matlab.graphics.mixin.Legendable')
            allLegendable = false;
            break
        end
    end
    if ~allLegendable
        % @TODO - message catalog
        error(message('MATLAB:legend:ObjectsNotLegendable'));
    end
end

%----------------------------------------------------------------%
function className = getClassName(obj)
% getClassName returns the class name with the package name omitted

className = class(obj);
idx = strfind(className,'.');
if ~isempty(idx)
    className = className(idx(end)+1:end);
end 

%----------------------------------------------------------------%
function argout = setOutArgs(arg, n)
[argout{1:n}] = find_legend_info(arg);

%----------------------------------------------------------------%
function tf = istextscalar(text)
tf = ischar(text) || (isstring(text) && isscalar(text));
  
%----------------------------------------------------------------%
function tf = istextscalarvector(text)
tf = (ischar(text) && size(text,1)==1) || (isstring(text) && isscalar(text));
 
%----------------------------------------------------------------%
function result = lcl_is2D(ax)
camUp = ax.Camera.UpVector;
result = isequal(ax.View,[0,90]) && isequal(abs(camUp),[0 1 0]); 

