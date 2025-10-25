function figHandle = show(Mesh, varargin)
    if class(Mesh) ~= "cell"
        Mesh = {Mesh};
    end
    
    % Parse inputs
    p = inputParser;
    addParameter(p,'FeatureEdgeAngle',nan,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
    addParameter(p,'NormalLength',0,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
    addParameter(p,'Color',[0,0,0],@(x)validateattributes(x,{'numeric'},{'size',[1,3]}));
    addParameter(p,'SharpCorners',[]);
    addParameter(p,'ShowEdges',true,@islogical);
    parse(p,varargin{:});
    
    MeshLen = length(Mesh);
    
    TotalMatCount = 0;
    figHandle = struct();  % Store handles for visualization elements
    
    for nummesh = 1:MeshLen
        if class(Mesh{nummesh}) ~= ("polymesh")
            error('Invalid input: Expected polymesh object');
        end
        
        % Extract mesh vertices and triangles from the mesh
        P = Mesh{nummesh}.VertexPositions;
        T = Mesh{nummesh}.Faces;

        % Check if the mesh is empty
        if isempty(P) || isempty(T)
            fprintf('Input mesh is empty\n')
            return;
        end

        % Plot triangles with material
        Face = T(:,1:3);
        edgecolor = 'none';
        if isnan(p.Results.FeatureEdgeAngle) && p.Results.ShowEdges
            edgecolor = 'k';
        end
        
        materialColors = zeros(length(Mesh{nummesh}.Materials), 3);
        for i = 1:length(Mesh{nummesh}.Materials)
            materialProps = properties(Mesh{nummesh}.Materials(i));
            containsColor = contains(materialProps, 'color', 'IgnoreCase', true);
            if any(containsColor)
                % Use the first color property found
                colorPropName = materialProps{find(containsColor, 1)};
                col = Mesh{nummesh}.Materials(i).(colorPropName);
                if(length(col) == 3 || length(col) == 4)
                    materialColors(i,:) = Mesh{nummesh}.Materials(i).(colorPropName)(1:3);
                else
                    % Use default color logic if no color property is found
                    color = 0.5 * (1 + hsv(1000));
                    numcol = round(mod((TotalMatCount + i) * 0.6180339887, 1) * 1000 + 1);
                    materialColors(i,:) = color(numcol, :);
                end
            else
                % Use default color logic if no color property is found
                color = 0.5 * (1 + hsv(1000));
                numcol = round(mod((TotalMatCount + i) * 0.6180339887, 1) * 1000 + 1);
                materialColors(i,:) = color(numcol, :);
            end
        end
        % Retrieve material properties
        mat = Mesh{nummesh}.FaceMaterials;

        % Assign colors to each face based on the material index
        plotcolor = materialColors(mat, :);
        figHandle.MeshPatch = trisurf(Face, P(:,1), P(:,2), P(:,3), ...
            'EdgeColor', edgecolor, 'FaceVertexCData', plotcolor);
        hold on;
        
        % Plot normals
        if p.Results.NormalLength > 0
            TR = triangulation(Face, P);
            facenormals = TR.faceNormal;
            center = TR.incenter;
            hold on;
            figHandle.NormalsPatch = quiver3(center(:,1), center(:,2), center(:,3), ...
                facenormals(:,1), facenormals(:,2), facenormals(:,3), ...
                p.Results.NormalLength, 'Color', 'b');
        end

        % Plot feature edges
        if ~isnan(p.Results.FeatureEdgeAngle)
            TR = triangulation(Mesh{nummesh}.Faces, Mesh{nummesh}.VertexPositions);
            F = featureEdges(TR, p.Results.FeatureEdgeAngle)';
            x = P(:,1);
            y = P(:,2);
            z = P(:,3);
            
            % Preallocate arrays for the edges
            numEdges = length(F);
            edgeX = nan(3, numEdges);
            edgeY = nan(3, numEdges);
            edgeZ = nan(3, numEdges);
            
            % Fill the arrays
            edgeX(1:2, :) = x(F);
            edgeY(1:2, :) = y(F);
            edgeZ(1:2, :) = z(F);
            
            % Create NaNs to separate each edge
            edgeX(3, :) = NaN;
            edgeY(3, :) = NaN;
            edgeZ(3, :) = NaN;
            
            % Flatten arrays
            edgeX = edgeX(:);
            edgeY = edgeY(:);
            edgeZ = edgeZ(:);
            
            % Plot in a single call
            hold on;
            figHandle.FeatureEdgesPatch = plot3(edgeX, edgeY, edgeZ, 'k');
        end

        % Plot sharp corners
        for sc = 1:length(p.Results.SharpCorners)
            len = size(P, 1);
            if p.Results.SharpCorners(sc) + 1 > len
                error('Value of SharpCorners exceeds the number of vertices');
            end
            hold on;
            figHandle.SharpCorners = plot3(P(p.Results.SharpCorners(sc) + 1, 1), ...
                                           P(p.Results.SharpCorners(sc) + 1, 2), ...
                                           P(p.Results.SharpCorners(sc) + 1, 3), ...
                                           '.', 'Color', 'b', 'MarkerSize', 20);
        end
        
        % Label axis and set the aspect ratio
        xlabel('x-axis');
        ylabel('y-axis');
        zlabel('z-axis');
        set(gca, 'DataAspectRatio', [1 1 1]);

        mtlcount = length(Mesh{nummesh}.Materials);
        if all(p.Results.Color == 0)
            for i = 1:mtlcount
                j = (TotalMatCount + i);
                Color = materialColors(i,:);
                if j < 17
                    name = Mesh{nummesh}.Materials(i).Name;
                    name = strrep(name, '_', '\_');
                    if i == 1
                        name = "Default";
                    end
                    annotation('textbox', [.9 .9 - (0.05 * (j - 1)) .10 .05], ...
                        'FontSize', 8, 'FontWeight', 'bold', 'LineWidth', 1.0, ...
                        'String', name, 'Color', Color, 'EdgeColor', 'none', ...
                        'BackgroundColor', [0 0 0]);
                end
            end
        end
        TotalMatCount = TotalMatCount + mtlcount - 1;
    end
    hold off;
end
