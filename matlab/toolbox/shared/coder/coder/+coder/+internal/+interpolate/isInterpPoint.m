function b = isInterpPoint(qp, nd, xmin, xmax)
    % Returns true if point is inside ND bounding box

    %#codegen
    coder.inline('always');
    coder.internal.prefer_const(nd);
    b = true;
    for i = 1:nd
        b = b && (qp(i)>=xmin(i) && qp(i)<=xmax(i));
    end
end