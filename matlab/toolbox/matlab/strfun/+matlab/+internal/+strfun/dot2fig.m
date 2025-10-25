function dot2fig(graphText, title, nodeClickFcn)
    %DOT2FIG Plot dot graph in a Handle Graphics figure

%   Copyright 2013-2023 The MathWorks, Inc.
    
    if nargin < 3
        nodeClickFcn = [];
        if nargin < 2
            title = '';
        end
    end

    sanitize = @sanitizeQuotedString; %#ok<NASGU> Used in regexprep eval
    graphText = regexprep(graphText, '"((\\"|[^"])*?)"', '"${sanitize($1)}"');

    inFilename = [tempname '.dot'];
    
    [fid, msg] = fopen(inFilename,'w');
    
    if fid < 0
        error(message('MATLAB:internal:dot2fig:fopen', msg));
    end
    
    fprintf(fid, '%s', graphText);
    
    fclose(fid);
    
    outFilename = regexprep(inFilename,'.dot$','_out.dot');

    matlab.internal.strfun.callgraphviz('dot','-Tdot',inFilename,'-o',outFilename,'-v');
    
    graphText = fileread(outFilename);
    
    delete(outFilename)
    delete(inFilename)
    
    graphText = regexprep(graphText, '\\\r?\n', '');

    nodes = regexp(graphText, '^\s*(?<name>\w+)\s+\[(?<attributes>[^\]]*)\];\s*$', 'names', 'lineanchors');
    links = regexp(graphText, '^\s*(?<node1>\w+)\s*->\s*(?<node2>\w+)\s+\[(?<attributes>[^\]]*)\];\s*$', 'names', 'lineanchors');
    
    graph = regexp(graphText, '^\s*graph\s*\[bb="(?<pos>[\d,.]+)"(?<attributes>[^\]]*)\];\s*$', 'names', 'lineanchors');
    
    header = regexp(graphText, '^(?<type>\w+) (?<title>.*) {', 'dotexceptnewline', 'names');

    if isempty(header)
        figTitle = 'Dot Graph';
    else
        figTitle = header.title;
    end
    
    graphPos = str2num(graph(1).pos); %#ok<ST2NM>
    graphDim = graphPos(3:4);
    
    screenUnits = get(0, 'Units');
    set(0, 'Units', 'points');
    screenSizePoints = get(0, 'ScreenSize');
    set(0, 'Units', 'inches');
    screenSizeInches = get(0, 'ScreenSize');
    set(0, 'Units', screenUnits);

    pointsPerInch = screenSizePoints(3)/screenSizeInches(3);
    
    screenSize = get(0, 'ScreenSize');
    screenDim = screenSize(3:4);
        
    fig = figure('Name', figTitle);
    figDressingDiff = get(fig, 'OuterPosition')-get(fig, 'Position');
    figDressingDiff = figDressingDiff(3:4)-figDressingDiff(1:2);
    margin = 40;
    figDim = min(screenDim, graphDim+2*margin+figDressingDiff);
    set(fig, 'OuterPosition', [(screenDim-figDim)/2, figDim]);
    border = margin./graphDim;
    axLim = [-border; 1+border];
    ax = axes('Parent',fig, 'Units','normalized', 'Position', [0 0 1 1], 'XLim', axLim(:,1), 'YLim', axLim(:,2));
    set(ax,'XTick',[],'YTick',[],'Box','on');
    
    colorOrder = get(ax,'ColorOrder');
    
    defaultNode = nodes({nodes.name} == "node");
    if isempty(defaultNode)
        pv = struct;
    else
        pv = makePV(defaultNode.attributes);
    end
    nodeDefaults.curvature = getCurvature(pv, [1, 1]);
    
    if ~isempty(title)
        title = sanitizeQuotedString(title);
        titlePos = [.5, 1+margin/2/graphDim(2)];
        text(titlePos(1), titlePos(2), title, ...
            'FontSize', 10, ...
            'HorizontalAlignment','center', ...
            'EdgeColor', 'black', ...
            'Margin', 5, ...
            'Interpreter', 'none', ...
            'Parent', ax);
    end
    
    for subgraph = graph(2:end)
        graphPos = str2num(subgraph.pos); %#ok<ST2NM>
        graphPos(3:4) = graphPos(3:4) - graphPos(1:2);
        rectangle('Position',graphPos./[graphDim, graphDim], ...
            'Curvature', [.05 .05], ...
            'LineStyle', ':', ...
            'Parent', ax);
        buffer = 5;
        pv = makePV(subgraph.attributes);
        text((graphPos(1)+buffer)/graphDim(1), (graphPos(2)+graphPos(4)-buffer)/graphDim(2), compose(pv.label), ...
            'FontSize', 8, ...
            'VerticalAlignment','top', ...
            'Interpreter', 'none', ...
            'Parent', ax);
    end

    for link = links
        pv = makePV(link.attributes);
        if ~(isfield(pv, 'style') && strcmp(pv.style,'invis'))
            splineData = str2num(regexprep(pv.pos(3:end), '\s+', ';')); %#ok<ST2NM>
            if pv.pos(1) == 'e'
                splineData = circshift(splineData, [-1, 0]);
            else
                splineData = flipud(splineData);
            end
            color = getColor(pv, colorOrder, 'color', 'black');
            fontColor = getColor(pv, colorOrder, 'fontcolor', 'black');
            line(splineData(:,1)/graphDim(1), splineData(:,2)/graphDim(2), 'Color', color, 'Parent', ax);
            Xdiff = splineData(end-1,1)-splineData(end,1);
            Ydiff = splineData(end-1,2)-splineData(end,2);
            approachAngle = atan2(Ydiff,Xdiff);
            arrowAngle = .4;
            arrowLength = 12;
            arrowHeadAngle = approachAngle+[arrowAngle, -arrowAngle];
            xd = ([0 cos(arrowHeadAngle)]*arrowLength+splineData(end,1))/graphDim(1);
            yd = ([0 sin(arrowHeadAngle)]*arrowLength+splineData(end,2))/graphDim(2);
            patch(xd, yd, color, 'EdgeColor', color, 'Parent', ax);
            rectangle('Position', [(splineData(1,:)-2)./graphDim 4./graphDim], 'Curvature', [1 1], 'FaceColor', color, 'EdgeColor', color, 'Parent', ax);
            if isfield(pv, 'label')
                textPos = splineData(2,:)./graphDim;
                text(textPos(1), textPos(2), compose(pv.label), 'BackgroundColor', 'white', 'EdgeColor', color, 'Interpreter', 'none', 'FontSize', 8, 'Parent', ax, 'HorizontalAlignment', 'center','Color',fontColor);
            end
        end
    end
    
    for node = nodes
        pv = makePV(node.attributes);
        if isfield(pv, 'pos') && ~(isfield(pv, 'style') && strcmp(pv.style,'invis'))
            centerPos = str2num(pv.pos); %#ok<ST2NM>
            nodePos = centerPos ./ graphDim;
            if isfield(pv, 'label')
                label = pv.label;
            else
                label = node.name;
            end
            if isfield(pv, 'style') && pv.style == "bold"
                lineWidth = 2;
            else
                lineWidth = 0.5;
            end
            faceColor = getColor(pv, colorOrder, 'fillcolor', 'white');
            fontColor = getColor(pv, colorOrder, 'fontcolor', 'black');
            edgeColor = getColor(pv, colorOrder, 'color', 'black');
            curvature = getCurvature(pv, nodeDefaults.curvature);
            nodeSize = floor([str2double(pv.width), str2double(pv.height)]*pointsPerInch);
            rectangle('Position',[(centerPos-nodeSize./2)./graphDim nodeSize./graphDim], ...
                'Curvature', curvature, ...
                'FaceColor', faceColor, ...
                'EdgeColor', edgeColor, ...
                'LineWidth', lineWidth, ...
                'ButtonDownFcn', nodeClickFcn, ...
                'UserData', node.name, ...
                'Parent', ax);
            text(nodePos(1), nodePos(2), compose(label), ...
                'FontSize', 8, ...
                'Color', fontColor, ...
                'HorizontalAlignment','center', ...
                'Interpreter', 'none', ...
                'ButtonDownFcn', nodeClickFcn, ...
                'UserData', node.name, ...
                'Parent', ax);
        end
    end
end

function sanitized = sanitizeQuotedString(unsanitized)
    escapes = ["\a", "\b", "\t", "\n", "\v", "\f", "\r"];
    sanitized = replace(unsanitized, compose(escapes), "\" + escapes);
    sanitized = regexprep(sanitized, '[\0-\x1F]', '\\\\${dec2base($0,8,3)}');
end

function color = getColor(pv, colorOrder, field, default)
    color = default;
    if isfield(pv, field)
        colorspec = pv.(field);
        index = str2double(colorspec);
        if ~isnan(index)
            index = mod(index-1, size(colorOrder,1))+1;
            color = colorOrder(index,:);
        elseif strlength(colorspec) == 7 && startsWith(colorspec, '#')
            r = hex2dec(colorspec(2:3));
            g = hex2dec(colorspec(4:5));
            b = hex2dec(colorspec(6:7));
            color = [r,g,b]/255;
        else
            color = colorspec;
        end
    end
end

function curvature = getCurvature(pv, default)
    curvature = default;
    if isfield(pv, 'shape')
        switch pv.shape
        case 'box'
            curvature = [0 0];
        end
    end
end

function pv = makePV(attributeList)
    pv = regexp(attributeList, '(?<param>\w+)=(?<lq>")?(?<value>(?(lq)(\\"|[^"])*|[\w.]+))(?(lq)")', 'names');
    pv = {pv.param; pv.value};
    pv = struct(pv{:});
end
