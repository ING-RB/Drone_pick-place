function ltitipmenus(tiphandle,varargin)
%LTITIPMENUS Add UIContextMenu items to datatip
%
%  h.addmenu('alignment','fontsize','movable','delete') adds any of the standard menus
%  are added to the h.UIContextMenu handle according to the users selection.
%
%

%  Author(s): John Glass
%  Revised:
%  Copyright 1986-2014 The MathWorks, Inc.

if nargin > 1
    for i= 2:nargin
        switch lower(varargin{i-1})
            case 'fontsize'
                %---FontSize
                CM1 = uimenu(tiphandle.UIContextMenu, ...
                    'Label', getString(message('Controllib:plots:strFontSize')),...
                    'Tag','FontSize');
                uimenu(CM1,'Label','6', 'Tag','6', 'Callback',{@LocalSelectMenu,'fontsize'},...
                    'UserData',struct('DataTip',tiphandle,'FontSize',6));
                uimenu(CM1,'Label','8', 'Tag','8', 'Callback',{@LocalSelectMenu,'fontsize'},...
                    'UserData',struct('DataTip',tiphandle,'FontSize',8));
                uimenu(CM1,'Label','10','Tag','10','Callback',{@LocalSelectMenu,'fontsize'},...
                    'UserData',struct('DataTip',tiphandle,'FontSize',10));
                uimenu(CM1,'Label','12','Tag','12','Callback',{@LocalSelectMenu,'fontsize'},...
                    'UserData',struct('DataTip',tiphandle,'FontSize',12));
                uimenu(CM1,'Label','14','Tag','14','Callback',{@LocalSelectMenu,'fontsize'},...
                    'UserData',struct('DataTip',tiphandle,'FontSize',14));
                uimenu(CM1,'Label','16','Tag','16','Callback',{@LocalSelectMenu,'fontsize'},...
                    'UserData',struct('DataTip',tiphandle,'FontSize',16));
                CH = get(CM1,'Children');
                set(findobj(CH,'flat','Tag',num2str(get(tiphandle,'FontSize'))),'Checked','on');

            case 'alignment'
                %---Alignment
                CM1 = uimenu(tiphandle.UIContextMenu, ...
                    'Label',getString(message('Controllib:plots:strAlignment')),...
                    'Tag','Alignment');
                uimenu(CM1, ...
                    'Label',getString(message('Controllib:plots:strTopRight')),  ...
                    'Callback',{@LocalSelectMenu,'alignment'},...
                    'UserData',struct('DataTip',tiphandle,'H','left','V','bottom'));
                uimenu(CM1, ...
                    'Label',getString(message('Controllib:plots:strTopLeft')), ...
                    'Callback',{@LocalSelectMenu,'alignment'},...
                    'UserData',struct('DataTip',tiphandle,'H','right','V','bottom'));
                uimenu(CM1, ...
                    'Label',getString(message('Controllib:plots:strBottomRight')), ...
                    'Callback',{@LocalSelectMenu,'alignment'},'Sep','on',...
                    'UserData',struct('DataTip',tiphandle,'H','left','V','top'));
                uimenu(CM1, ...
                    'Label',getString(message('Controllib:plots:strBottomLeft')), ...
                    'Callback',{@LocalSelectMenu,'alignment'},...
                    'UserData',struct('DataTip',tiphandle,'H','right','V','top'));

                CH = get(CM1,'Children');

                % REVISIT needed to get property correctly
                % drawnow

                switch tiphandle.Orientation
                    case {'top-right','topright'}
                        set(findobj(CH,'flat','Position',1),'Checked','on');
                    case {'top-left','topleft'}
                        set(findobj(CH,'flat','Position',2),'Checked','on');
                    case {'bottom-right','bottomright'}
                        set(findobj(CH,'flat','Position',3),'Checked','on');
                    case {'bottom-left','bottomleft'}
                        set(findobj(CH,'flat','Position',4),'Checked','on');
                end
                
                %---Add a listener to the alignment property to set the menu
                %   item checkbox properly
                addlistener(tiphandle,'Orientation','PostSet',@(es,ed ) LocalUpdateAlignment(es,ed,tiphandle));


            case 'movable'
                %---Movable
                CM1 = uimenu(tiphandle.UIContextMenu,...
                    'Label',getString(message('Controllib:plots:strMovable')),...
                    'Callback',{@LocalSelectMenu,'movable'},...
                    'UserData',struct('DataTip',tiphandle));
                if     strcmpi(tiphandle.Draggable,'on')
                    set(CM1,'Checked','on');
                else
                    set(CM1,'Checked','off');
                end

            case 'delete'
                %---Delete Menu
                uimenu(tiphandle.UIContextMenu, ...
                    'Label',getString(message('Controllib:plots:strDelete')), ...
                    'Callback',{@LocalSelectMenu,'delete'},...
                    'UserData',struct('DataTip',tiphandle));

            case 'interpolation'

                %---Interpolation
                CM1 = uimenu(tiphandle.UIContextMenu, ...
                    'Label',getString(message('Controllib:plots:strInterpolation')), ...
                    'Tag','Interpolation');
                uimenu(CM1, ...
                    'Label',getString(message('Controllib:plots:strNearest')), ...
                    'Callback',{@LocalSelectMenu,'interpolation'},...
                    'UserData',struct('DataTip',tiphandle,'Interpolate','off'));
                uimenu(CM1, ...
                    'Label',getString(message('Controllib:plots:strLinear')), ...
                    'Callback',{@LocalSelectMenu,'interpolation'},...
                    'UserData',struct('DataTip',tiphandle,'Interpolate','on'));
                CH = get(CM1,'Children');
                InterpOn = strcmpi(tiphandle.Cursor.Interpolate,'on');
                if InterpOn
                    set(findobj(CH,'flat','Position',2),'Checked','on');
                else
                    set(findobj(CH,'flat','Position',1),'Checked','on');
                end

            otherwise
                disp([varargin{i-1},' is not a valid menu selection'])
        end
    end
end

%%%%%%%%%%%%%%%%%%%
% LocalUpdateAlignment %
%%%%%%%%%%%%%%%%%%%
function LocalUpdateAlignment(~,~,tiphandle)

MenuChildren = get(tiphandle.UIContextMenu,'Children');
CH1 = findobj(MenuChildren,'Tag','Alignment');

if ~isempty(CH1)
    CH = get(CH1,'Children');

    set(CH(:),'Checked','off');
    switch tiphandle.Orientation
        case {'top-right','topright'}
            set(findobj(CH,'flat','Position',1),'Checked','on');
        case {'top-left','topleft'}
            set(findobj(CH,'flat','Position',2),'Checked','on');
        case {'bottom-right','bottomright'}
            set(findobj(CH,'flat','Position',3),'Checked','on');
        case {'bottom-left','bottomleft'}
            set(findobj(CH,'flat','Position',4),'Checked','on');
    end
end

%%%%%%%%%%%%%%%%%%%
% LocalSelectMenu %
%%%%%%%%%%%%%%%%%%%

function LocalSelectMenu(eventSrc,~,action)

Menu = eventSrc;
mud = get(Menu,'UserData');
h  = mud.DataTip;

switch lower(action)

    case 'fontsize'
        set(h,'FontSize',mud.FontSize);
        %---Set current menu selection "checked"
        set(get(get(Menu,'Parent'),'Children'),'Checked','off');
        set(Menu,'Checked','on');
    case 'alignment'
        %---Set current menu selection "checked"
        set(get(get(Menu,'Parent'),'Children'),'Checked','off');
        set(Menu,'Checked','on');

        if strcmpi(mud.V,'top') && strcmpi(mud.H,'right')
            NewOrientation = 'bottom-left';
        elseif strcmpi(mud.V,'top') && strcmpi(mud.H,'left')
            NewOrientation = 'bottom-right';
        elseif strcmpi(mud.V,'bottom') && strcmpi(mud.H,'right')
            NewOrientation = 'top-left';
        elseif strcmpi(mud.V,'bottom') && strcmpi(mud.H,'left')
            NewOrientation = 'top-right';
        end
        h.Orientation = strrep(NewOrientation,'-','');
        
        
    case 'movable'
        if strcmpi(get(Menu,'Checked'),'on')
            h.Draggable = 'off';
            set(Menu,'Checked','off')
        else
            h.Draggable = 'on';
            set(Menu,'Checked','on')
        end

    case 'delete'
        delete(h);
        return

    case 'interpolation'
        h.Cursor.Interpolate = mud.Interpolate;
        %---Set current menu selection "checked"
        set(get(get(Menu,'Parent'),'Children'),'Checked','off');
        set(Menu,'Checked','on');
        
end
