function [out, varargout] = dotReference(G, indexOp)
%

%   Copyright 2014-2024 The MathWorks, Inc.

% Store for re-use, avoid looking up multiple times for performance
S1name = indexOp(1).Name;

if strcmp(S1name, 'Edges')
    if isscalar(indexOp)
        out = getEdgesTable(G);
        nargoutchk(0, 1);
    else
        changeIndex = false; % need to convert to subsref syntax to edit an index
        if indexOp(2).Type == matlab.indexing.IndexingOperationType.Dot
            % Short-circuit to EdgeProperties if appropriate.
            S2subs = indexOp(2).Name;
            edges = G.EdgeProperties;
            if strcmp(S2subs, 'Weight') && isnumeric(edges) && iscolumn(edges)
                % Use minimized (weights-only) edge properties
                if numel(indexOp) == 2
                    out = edges;
                    nargoutchk(0, 1);
                    return
                end
                indexOp = indexOp(3:end);
            elseif matches(S2subs, 'EndNodes')
                EndNodes = G.Underlying.Edges;
                [names, hasNodeNames] = getNodeNames(G);
                if hasNodeNames
                    EndNodes = reshape(names(EndNodes), [], 2);
                end
                if numel(indexOp) == 2
                    out = EndNodes;
                    nargoutchk(0, 1);
                    return
                end
                edges = EndNodes;
                indexOp = indexOp(3:end);
            elseif matches(S2subs, 'Properties')
                edges = getEdgesTable(G);
                indexOp = indexOp(2:end);
            else
                edges = getEdgePropertiesTable(G);
                indexOp = indexOp(2:end);
            end
        else
            % G.Edges(...) or G.Edges{...}
            useEdgeProp = false;
            if numel(indexOp(2).Indices) == 2 % other numbers here result in error from table indexing
                % Case G.Edges(firstInd, secondInd) = V or G.Edges{firstInd, secondInd} = V
                % Error if first variable (EndNodes) is impacted, otherwise
                % modify j so that it can be applied to G.EdgeProperties.
                secondInd = indexOp(2).Indices{2};
                if isnumeric(secondInd)
                    if ~any(secondInd == 1)
                        secondInd = secondInd - 1;
                        useEdgeProp = true;
                        changeIndex = true;
                    end
                elseif islogical(secondInd) && ~isempty(secondInd)
                    if ~secondInd(1)
                        secondInd(1) = [];
                        useEdgeProp = true;
                        changeIndex = true;
                    end
                elseif ischar(secondInd) || iscellstr(secondInd) || isstring(secondInd)
                    if ~isequal(secondInd, ':') && ~any(strcmp(secondInd, 'EndNodes'))
                        useEdgeProp = true;
                    end
                end
                % Not allowed to change indexOp, move to subs interface
                if changeIndex
                    indexOp = matlab.internal.indexing.convertIndexingOperationToSubstruct(indexOp);
                    indexOp(2).subs{2} = secondInd;
                end
            end
            if useEdgeProp
                edges = getEdgePropertiesTable(G);
            else
                edges = getEdgesTable(G);
            end
            indexOp = indexOp(2:end);
        end

        if nargout == 1
            if changeIndex
                out = subsref(edges, indexOp);
            else
                out = edges.(indexOp);
            end
        elseif nargout == 0
            % Need to pass through the information that there's 0 outputs.
            if changeIndex
                [args{1:nargout}] = subsref(edges, indexOp);
            else
                [args{1:nargout}] = edges.(indexOp);
            end
            if ~isempty(args)
                out = args{1};
                varargout = args(2:end); % Should be empty, but let's pass it along just in case.
            end
        else
            if changeIndex
                [out, varargout{1:nargout-1}] = subsref(edges, indexOp);
            else
                [out, varargout{1:nargout-1}] = edges.(indexOp);
            end
        end
    end
elseif strcmp(S1name, 'Nodes')
    if isscalar(indexOp)
        nargoutchk(0, 1);
        out = getNodePropertiesTable(G);
    else
        if indexOp(2).Type == matlab.indexing.IndexingOperationType.Dot && ...
                strcmp(indexOp(2).Name, 'Name')
            % Short-circuit to minimized NodeProperties if appropriate.
            nodeprop = G.NodeProperties;
            if iscell(nodeprop)
                if numel(indexOp) == 2
                    out = nodeprop;
                    nargoutchk(0, 1);
                else
                    indexOp = indexOp(3:end);
                    if nargout == 1
                        out = nodeprop.(indexOp);
                    elseif nargout == 0
                        % Need to pass through the information that there's 0 outputs.
                        [args{1:nargout}] = nodeprop.(indexOp);
                        if ~isempty(args)
                            out = args{1};
                            varargout = args(2:end); % Should be empty, but let's pass it along just in case.
                        end
                    else
                        [out, varargout{1:nargout-1}] = nodeprop.(indexOp);
                    end
                end
                return
            end
        end
        
        nodeprop = getNodePropertiesTable(G);
        indexOp = indexOp(2:end);

        if nargout == 1
            out = nodeprop.(indexOp);
        elseif nargout == 0
            % Need to pass through the information that there's 0 outputs.
            [args{1:nargout}] = nodeprop.(indexOp);
            if ~isempty(args)
                out = args{1};
                varargout = args(2:end); % Should be empty, but let's pass it along just in case.
            end
        else
            [out, varargout{1:nargout-1}] = nodeprop.(indexOp);
        end
    end
else
    mc = metaclass(G);
    if isempty( findobj(mc.PropertyList, '-depth',0,'Name', S1name) )
        error(message('MATLAB:noSuchMethodOrField', S1name, class(G)));
    else
        error(message('MATLAB:class:GetProhibited', S1name, class(G)));
    end
end