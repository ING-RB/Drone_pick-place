function varargout = psIntersect(subject, lineseg, tolval)
% PSINTERSECT Find the intersection of a polyshape and a line
% 
% [inside, outside, vinid, voutid] = PSINTERSECT(pshape, lineseg) returns 
% the line segments that are inside and outside of a polyshape. lineseg is 
% a 2-column matrix whose first column defines the x-coordinates of the input 
% line segments and the second column defines the y-coordinates. lineseg 
% must have atleast two rows.  inside returns the coordinates of the lineseg that are
% inside the polyshape. outside returns the coordinates of the lineseg that
% are outside the polyshape. vinid and voutid both returns the vertex IDs of the 
% edges of the polyshape that are intersected by lineseg. vinid returns the
% vertex IDs of the edges of the polyshape where the intersected lineseg is 
% inside the polyshape. voutid returns the vertex IDs of the edges of the 
% polyshape where the intersected lineseg is outside the polyshape.
%
% [inside, outside, vinid, voutid] = PSINTERSECT(pshape, lineseg, tolval) with a 
% specified tolerance returns the line segments that are inside and outside 
% of a polyshape. Two points are determined to be within a tolerance of
% tolval if abs(u-v) <= max(tolval, tolval*abs(subject.perimeter)).
%
% Copyright 2022-2023 The MathWorks, Inc.

    arguments
        subject (1,1) {mustBeA(subject,'polyshape')}
        lineseg (2,2) double {mustBeNumeric,mustBeFinite,mustBeReal}
        tolval(1,1) double {mustBePositive,mustBeFinite,mustBeReal} = 1e-8
    end

    [in,out]=intersect(subject,lineseg);

    % check for edge case when the lineseg passes through a single vertex.
    % The solution is to have two points representing the single vertex such
    % that the start and end points are the same.
    idx = find(all(isnan(out),2))';
    for ii=idx
        if isequal(out(ii-1,:),out(ii+1,:))
            if ~isempty(in)
               in = [in; nan(1,2)];
            end
            in = [in; out(ii-1,:); out(ii-1,:)];
        end
    end

    % Tolerance is set based on the pattern in other polyshape functions.
    tolerance = max(tolval, tolval*abs(subject.perimeter));
    varargout{1} = in;
    varargout{2} = out;
    % for the "inside" vertices
    if (nargout > 2)
        varargout{3}=double.empty(0,2);
        output = double.empty(0,2);
        inps = size(in,1);
        sz = size(subject.Vertices,1);
        for ii=1:inps
            if (~anynan(ii))
                [k_in,dist_in]=dsearchn(subject.Vertices,in(ii,:));
                if (dist_in <= tolerance)
                    output = [output; k_in k_in];
                end
            
                for ij=1:sz
                    idx_begin=ij;
                    idx_end = ij+1;
                    if (idx_end > sz)
                        idx_end = mod(idx_end,sz);
                    end
                    output = matlab.internal.math.checkCollinear(output,...
                        subject,in(ii,:),idx_begin,idx_end,tolerance);
                end
            end
        end
    
        varargout{3} = output;
    end

    % for the "outside" vertices
    if (nargout > 3)
        varargout{4}=double.empty(0,2);
        output2 = double.empty(0,2);
        [k_out,dist_out]=dsearchn(subject.Vertices,out);
        for ii=1:size(k_out,1)
            if (dist_out(ii)<= tolerance)
                output2 = [output2; k_out(ii) k_out(ii)];
            end
        end
        for jj=1:size(out,1)
            sz = size(subject.Vertices,1);
            for ii=1:sz
                idx_begin=ii;
                idx_end = ii+1;
                if (idx_end > sz)
                    idx_end = mod(idx_end,sz);
                end
                % check whether the point is collinear with the polygon
                % edge
                output2 = matlab.internal.math.checkCollinear(output2,...
                    subject,out(jj,:),idx_begin,idx_end,tolerance);
            end

        end
        varargout{4} = output2;
    end

end