classdef axesselector < matlab.mixin.SetGet & matlab.mixin.Copyable

    % controllib.chart.internal.widget.axesselector class
    %    axesselector properties:
    %       ColumnName
    %       ColumnSelection
    %       Name
    %       RowName
    %       RowSelection
    %       Visible
    %       Size
    %       Style
    %       Handles
    %       Listeners
    %
    %    ctrluis.axesselector methods:
    %       addlisteners -  Installs listeners.
    %       build -  Builds axes selector GUI.
    %       update -  Updates axes selector GUI.


    properties (SetObservable)
        ColumnName = [];
        ColumnSelection = [];
        Name = '';
        RowName = [];
        RowSelection = [];
        Visible = 'off';
        Size = [];
        Style = struct( 'OnColor', [ 0, 0, 0 ], 'OffColor', [ .8, .8, .8 ] );
        Handles = [];
        Listeners = [];
    end


    methods  % constructor block
        function this = axesselector(gridSize,varargin)
            %AXESSELECTOR  Constructor for @axesselector class.
            %
            %   H = AXESSELECTOR(SIZE)


            this.Size = gridSize;
            this.RowName = repmat({''},[gridSize(1) 1]);
            this.RowSelection = logical(ones(gridSize(1),1));
            this.ColumnName = repmat({''},[gridSize(2) 1]);
            this.ColumnSelection = logical(ones(gridSize(2),1));

            % User-specified properties (can be any prop EXCEPT Visible)
            this.set(varargin{:});

            % Construct GUI
            build(this)

            % Add other listeners
            addlisteners(this)
        end  % axesselector

    end  % constructor block

    methods
        function set.Name(this,value)
            % DataType = 'ustring'
            % no cell string checks yet'
            this.Name = value;
        end

        function set.Visible(this,value)
            % DataType = 'on/off'
            validatestring(value,{'on','off'},'','Visible');
            this.Visible = value;
        end

        function set.Listeners(this,value)
            % DataType = 'handle vector'
            validateattributes(value,{'handle'}, {'vector'},'','Listeners')
            this.Listeners = value;
        end

    end   % set and get functions

    methods  % public methods
        %----------------------------------------
        function addlisteners(this,L)
            %ADDLISTENERS  Installs listeners.
            if nargin==1
                % Targeted listeners
                prc = [this.findprop('RowName');this.findprop('ColumnName');...
                    this.findprop('RowSelection');this.findprop('ColumnSelection')];
                L = [event.proplistener(this,prc,'PostSet',@(~,~) update(this));...
                    event.proplistener(this,this.findprop('Name'),'PostSet',@(es,ed) LocalUpdateName(this,ed));...
                    event.proplistener(this,this.findprop('Visible'),'PostSet',@(es,ed) LocalSetVisible(this,ed));...
                    event.listener(this,'ObjectBeingDestroyed',@(es,ed) LocalCleanUp(this))];
            end
            % Add to list
            this.Listeners = [this.Listeners ; L];
        end

        function build(this)
            % Style variables
            UIColor = get(0,'DefaultUIControlBackground');
            StdUnit = 'pixels';

            % Set font size and weight
            if isunix
                FontSize = 10;
            else
                FontSize = 8;
            end
            FigWidth = 150+(this.Size(2)*20);
            FigHeight = 120+(this.Size(1)*20);
            FigPos = [20 20 FigWidth FigHeight];

            ChannelFig = uifigure('Units',StdUnit,...
                'WindowStyle','normal',...
                'Position',FigPos,...
                'NumberTitle','off',...
                'IntegerHandle','off',...
                'HandleVisibility','Callback',...
                'Name',this.Name,...
                'Color',UIColor,...
                'CloseRequestFcn',@(es,ed) LocalHide(this),...
                'Visible','off');

            % UI controls
            CloseButton = uicontrol(ChannelFig,...
                'Unit',StdUnit,...
                'Background',UIColor,...
                'Position',[FigWidth-75-60 10 60 20],...
                'Unit','normalized',...
                'Style','pushbutton',...
                'String',getString(message('Controllib:gui:strClose')),...
                'callback',@(es,ed) LocalHide(this));
            HelpButton = uicontrol(ChannelFig,...
                'Unit',StdUnit,...
                'Background',UIColor,...
                'Position',[FigWidth-70 10 60 20],...
                'Unit','normalized',...
                'Style','pushbutton',...
                'String',getString(message('Controllib:gui:strHelp')),...
                'Callback',@(es,ed) localHelp);

            % Axes
            ax = axes('Parent',ChannelFig,...
                'ButtonDownFcn',{@LocalSelectGroup this},...
                'XColor',[0 0 0],...
                'YColor',[0 0 0],...
                'Color',UIColor,...
                'Unit',StdUnit,...
                'Position',[10 40 FigPos(3)-20 FigPos(4)-50],...
                'Box','on',...
                'Ydir','reverse',...
                'Xlim',[0 this.Size(2)+1],...
                'Ylim',[0 this.Size(1)+1],...
                'Xtick',[],...
                'Ytick',[],...
                'Toolbar',[]);
            set(ax,'unit','norm');
            disableDefaultInteractivity(ax);

            % [ all ] Text
            AllText=text(0.5,0.5,sprintf('[ %s ]',getString(message('Controllib:gui:strAll'))), ...
                'Parent',ax, ...
                'Interpreter','none', ...
                'ButtonDownFcn',@(es,ed) LocalSelectAll(this), ...
                'Color',[0 0 0],...
                'FontSize',FontSize, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle',...
                'Tag','AllText');

            % Row labels
            RowLabels = zeros(this.Size(1),1);
            for ct=1:this.Size(1)
                RowLabels(ct) = text(0.5,ct+0.5,'', ...
                    'Parent',ax, ...
                    'Interpreter','none', ...
                    'ButtonDownFcn',@(es,ed) LocalSelectRow(this,ct), ...
                    'Color',[0 0 0],...
                    'FontSize',FontSize, ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle',...
                    'Tag',sprintf('Output%d',ct));
            end

            % Column labels
            ColumnLabels = zeros(this.Size(2),1);
            for ct=1:this.Size(2)
                ColumnLabels(ct) = text(ct+0.5,0.5,'', ...
                    'Parent',ax, ...
                    'Interpreter','none', ...
                    'ButtonDownFcn',@(es,ed) LocalSelectCol(this,ct), ...
                    'Color',[0 0 0],...
                    'FontSize',FontSize, ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle',...
                    'Tag',sprintf('Input%d',ct));
            end

            % Dots and labels
            Dots = zeros(this.Size);
            for jloop=1:this.Size(2)
                for iloop=1:this.Size(1)
                    Dots(iloop,jloop)=line(jloop+0.5,iloop+0.5, ...
                        'Parent',ax, ...
                        'Marker','o', ...
                        'MarkerEdgeColor','k', ...
                        'MarkerSize',7, ...
                        'LineStyle','none', ...
                        'ButtonDownFcn',@(es,ed) LocalSelectDot(this,iloop,jloop));
                end % for jloop
            end % for iloop

            % Store handles
            this.Handles = struct(...
                'Figure',ChannelFig,...
                'AllText',AllText,...
                'RowText',RowLabels,...
                'ColText',ColumnLabels,...
                'Dots',Dots);
        end

        function update(this,varargin)
            % RE: Behavior mimics two independent listboxes containing the row & column names
            H = this.Handles;

            % Dot color
            for j=1:this.Size(2)
                for i=1:this.Size(1)
                    if this.RowSelection(i) & this.ColumnSelection(j)
                        DotColor = this.Style.OnColor;
                    else
                        DotColor = this.Style.OffColor;
                    end
                    set(H.Dots(i,j),'Color',DotColor,'MarkerFaceColor',DotColor);
                end
            end

            % Text color
            set([H.AllText;H.RowText;H.ColText],'Color',[0 0 0])  % reset
            if all(this.RowSelection) & all(this.ColumnSelection)
                set(H.AllText,'Color',[1 0 0])
            end
            % Hightlight selected rows and columns in red
            set(H.ColText(this.ColumnSelection),'Color',[1 0 0])
            set(H.RowText(this.RowSelection),'Color',[1 0 0])

            % Row names
            RowLabels = this.RowName;
            if this.Size(1)>1
                for ct=1:this.Size(1)
                    if isempty(RowLabels{ct})
                        RowLabels{ct} = sprintf('r%d',ct);
                    end
                end
            end
            set(H.RowText,{'String'},RowLabels)

            % Column names
            ColumnLabels = this.ColumnName;
            if this.Size(2)>1
                for ct=1:this.Size(2)
                    if isempty(ColumnLabels{ct})
                        ColumnLabels{ct} = sprintf('c%d',ct);
                    end
                end
            end
            set(H.ColText,{'String'},ColumnLabels);

        end
    end
end

%% Local Functions

function LocalSetVisible(this,eventdata)
% Makes selector visible
if strcmp(this.Visible,'on')
    % Sync GUI with selector state
    update(this);
end
set(this.Handles.Figure,'Visible',this.Visible);

end  % LocalSetVisible

function LocalUpdateName(this,eventdata)
% Updates row, column, and figure name
set(this.Handles.Figure,'Name',this.Name)

end  % LocalUpdateName

function LocalCleanUp(this)
% Delete figure
if ishandle(this.Handles.Figure)
    delete(this.Handles.Figure)
end
end  % LocalCleanUp


function LocalHide(this)
this.Visible = 'off';
end  % LocalHide



function LocalSelectAll(this)
% Select all
AllSelect = ~(all(this.RowSelection) & all(this.ColumnSelection));
% REVISIT: simplify when this.prop(i) = rhs works
% this.RowSelection(:) = AllSelect;
rs = this.RowSelection; rs(:) = AllSelect; this.RowSelection = rs;
cs = this.ColumnSelection; cs(:) = AllSelect; this.ColumnSelection = cs;
end  % LocalSelectAll



function LocalSelectRow(this,i)
% Select given row. Clicking on a row toggles its visibility
% RE: Effective visibility of dots in the row depends on column visibility too
NoSelect = all(~this.RowSelection) & all(~this.ColumnSelection);
% REVISIT: simplify when this.prop(i) = rhs works
RowSel = this.RowSelection;
RowSel(i) = ~RowSel(i);
this.RowSelection = RowSel;
if NoSelect
    % Turn on all columns of nothing selected initially
    cs = this.ColumnSelection; cs(:) = true; this.ColumnSelection = cs;
end
end  % LocalSelectRow



function LocalSelectCol(this,j)
% Select given column. Clicking on a column toggles its visibility
NoSelect = all(~this.RowSelection) & all(~this.ColumnSelection);
% REVISIT: simplify when this.prop(i) = rhs works
ColSel = this.ColumnSelection;
ColSel(j) = ~ColSel(j);
this.ColumnSelection = ColSel;
if NoSelect
    % Turn on all rows of nothing selected initially
    rs = this.RowSelection; rs(:) = true; this.RowSelection = rs;
end
end  % LocalSelectCol



function LocalSelectDot(this,i,j)
% Select single (row,col) pair
RowSel = zeros(this.Size(1),1);
RowSel(i) = 1;
ColSel = zeros(this.Size(2),1);
ColSel(j) = 1;
this.RowSelection = logical(RowSel);
this.ColumnSelection = logical(ColSel);
end  % LocalSelectDot



function LocalSelectGroup(eventsrc,eventdata,this)
% Selects group of I/Os
ax = eventsrc;
H = this.Handles;

%---Get figure current point data
FigUnits=get(H.Figure,'Unit');
set(H.Figure,'unit','norm');
axpos=get(ax,'Position');
P=get(H.Figure,'CurrentPoint'); % initializes rbbox

% Draw the rubberband box
figure(H.Figure)
rect = rbbox;
rect(1)=max([0,(rect(1)-axpos(1))]);
rect(2)=max([0,(rect(2)-axpos(2))]);
rect(1:2)=max(0,rect(1:2)./axpos(3:4));
rect(3:4)=min(1,rect(3:4)./axpos(3:4));

% Get the current rectangle
XV=[rect(1);rect(1)+rect(3);rect(1)+rect(3);rect(1);rect(1)];
YV=[rect(2);rect(2);rect(2)+rect(4);rect(2)+rect(4);rect(2)];

% Dot positions in [0 1]
Xdots = get(H.Dots,{'Xdata'});
Xdots = cat(1,Xdots{:})/(1+this.Size(2));
Ydots = get(H.Dots,{'Ydata'});
Ydots = 1-cat(1,Ydots{:})/(1+this.Size(1));

% Selected dots
indots = inpolygon(Xdots,Ydots,XV,YV);
indots = reshape(indots,this.Size);
if any(indots(:))
    this.RowSelection = any(indots,2);
    this.ColumnSelection = any(indots,1);
end

% Return figure back to original units
set(H.Figure,'Unit',FigUnits);
end  % LocalSelectGroup

function localHelp()
% RE: This dialog serves both CST and IDENT
% Precedence: CST DOC, IDENT DOC
if isempty(ver('control')) || ~license('test','Control_Toolbox')
    identguihelp('response_ioselector');
else
    ctrlguihelp('response_ioselector');
end
end  % localHelp
