classdef sTurning
    %#codegen

%   Copyright 2023 The MathWorks, Inc.

    methods(Static)
        function [t, total_len] = boundary_to_turn_rep(c)
            % Boundary2D is closed
            n = coder.internal.indexInt(c.getBoundarySize(1) - 1);
            t = coder.internal.polyshapeHelper.turnrep(n);

            theta1 = 0;
            total_len = 0;
            [X, Y] = c.getVtxArray;
            for i0 = 1:n
                % Look one vertex ahead of i0 to compute the leg.
                theta0 = theta1;
                i1 = i0 + 1;
                dx = X(i1) - X(i0);
                dy = Y(i1) - Y(i0);

                if abs(dx) < eps && abs(dy) < eps
                    theta1 = theta0;
                    t.legs(i0).theta = theta1;
                    t.legs(i0).len = 0;
                else
                    theta1 = bound_angle(atan2(dy, dx), theta0);
                    t.legs(i0).theta = theta1;
                    t.legs(i0).len = sqrt(dx * dx + dy * dy);
                    total_len = total_len + t.legs(i0).len;
                end

            end
            t.total_len = total_len;

            tl_inv = 1/total_len;
            len = 0;
            for i0 = 1:n
                t.legs(i0).s = len*tl_inv;
                len = len + t.legs(i0).len;
            end
        end

        % In one O(m + n) pass over the turning reps of the polygons
        % to be matched, this computes all the terms needed to incrementally
        % compute the metric.
        function [ht0,slope,alpha] = init_vals(f, g)

            % Disconts that bound current strip
            % First strip is between 0 and the earliest of first f and g disconts
            gi = ONE;
            fi = ONE;

            % accumulators as defined in reference
            ht0 = 0;
            alpha = 0.;
            % compute initial slope.
            if tr_s(g,ONE) < tr_s(f,ONE)
                slope = 0;
            else
                slope = (tr_theta(g, ZERO) - tr_theta(f, ZERO))^2;
                slope = -1*slope;
            end
            last_s = 0; % s at left edge of current strip

            % Count all the strips
            nm = f.n + g.n - 1;
            for i=1:nm

                % Compute height of current strip.
                dtheta = tr_theta(g, gi - 1) - tr_theta(f, fi - 1);

                % Determine flavor of discontinuity on right.
                if (tr_s(f, fi) <= tr_s(g, gi))
                    % It's f. Compute width of current strip,
                    % then bump area accumulators.
                    ds = tr_s(f, fi) - last_s;
                    alpha = alpha + (ds * dtheta);
                    ht0 = ht0 + (ds * dtheta * dtheta);

                    % Determine flavor of next strip.  We know it's ff
                    % or fg.  In latter case, bump accumulator.  Note
                    % we've skipped the first strip.  It's added as the
                    % "next" of the last strip.
                    if (tr_s(f, fi + 1) > tr_s(g, gi))
                        slope = slope + (tr_theta(f, fi) - tr_theta(g, gi - 1))^2;
                    end

                    % Go to next f discontinuity.
                    last_s = tr_s(f, fi);
                    fi = fi + ONE;
                else
                    % Else it's g ...
                    ds = tr_s(g, gi) - last_s;
                    alpha = alpha + (ds * dtheta);
                    ht0 = ht0 + (ds * dtheta * dtheta);

                    % and next strip is gg or gf, and again
                    % we're interested in the latter case.
                    if (tr_s(g, gi + 1) >= tr_s(f, fi))
                        slope = slope - (tr_theta(g, gi) - tr_theta(f, fi - 1))^2;
                    end
                    % Go to next g discontinuity.
                    last_s = tr_s(g, gi);
                    gi = gi + ONE;
                end
            end
        end

        function [ht0_rtn, slope_rtn, a] = reinit_vals(f, g, fi, gi)
            fr = coder.internal.polyshapeHelper.sTurning.rotate_turn_rep(f, fi);
            gr = coder.internal.polyshapeHelper.sTurning.rotate_turn_rep(g, gi);
            [ht0_rtn, slope_rtn, a] = coder.internal.polyshapeHelper.sTurning.init_vals(fr, gr);
        end
        % Compute number of events between successive reinits
        % that will not blow the asymptotic complexity bound.
        function nEvt = reinit_interval(f, g)
            tnEvt = min(f.n, g.n) * ilog2(g.n);
            nEvt = coder.internal.indexDivide(f.n*g.n, tnEvt) ;
        end

        % Fill in a turn rep with a rotated version of an
        % original.  Normalized arc lengths start at 0 in
        % the new representation.
        function r = rotate_turn_rep(t, to)
            n = t.n();
            r = coder.internal.polyshapeHelper.turnrep(n);
            r.total_len = t.total_len;
            total_len = t.total_len;
            ti = to;

            for ri = 1:n
                r.legs(ri).theta = tr_theta(t, ti);
                r.legs(ri).len = tr_len(t, ti);
                r.legs(ri).s = tr_s(t, ti);
                ti = ti + 1;
            end

            len = 0;
            for ri = 1:n
                r.legs(ri).s = len / total_len;
                len = len + r.legs(ri).len;
            end
        end
    end

    methods

        function sTurningobj = the_eventsInit(sTurningobj, nEvts)
            e = struct('t',0,'fi',ZERO,'gi',ZERO);
            sTurningobj.the_events = repmat(e, [1 nEvts]);
        end

        % Scan the turning reps to create the initial
        % events in the heap as described above.
        function sTurningobj = init_events(sTurningobj, f, g)
            sTurningobj.n_events = ZERO;
            sTurningobj = sTurningobj.the_eventsInit(max(f.n, g.n));

            % Cycle through all g discontinuities, including
            % the one at s = 1.  This takes care of s = 0.
            fi = ONE;
            for gi = ONE:g.n()
                % Look for the first f discontinuity to the
                % right of this g discontinuity.
                while (tr_s(f, fi) <= tr_s(g, gi))
                    fi = fi + ONE;
                end
                sTurningobj = sTurningobj.add_event(f, g, fi, gi);
            end

        end

        % Insert a new event in the heap.
        function sTurningobj = add_event(sTurningobj, f, g, fi, gi)
            t = tr_s(f, fi) - tr_s(g, gi);
            if (t > 1)
                return;
            end
            sTurningobj.n_events = sTurningobj.n_events + 1;
            j = sTurningobj.n_events;
            i = coder.internal.indexDivide(sTurningobj.n_events,TWO);
            while (i > 0 && sTurningobj.the_events(i).t > t)
                sTurningobj.the_events(j) = sTurningobj.the_events(i);
                j = i;
                i = coder.internal.indexDivide(i,TWO);
            end
            sTurningobj.the_events(j).t = t;
            sTurningobj.the_events(j).fi = fi;
            sTurningobj.the_events(j).gi = gi;
        end

        % Remove the event of min t from the heap and return it.
        function [sTurningobj, next] = next_event(sTurningobj)
            next = sTurningobj.the_events(1);     % remember event to return
            e = sTurningobj.the_events(sTurningobj.n_events); % new root (before adjust)

            sTurningobj.n_events = sTurningobj.n_events - 1;
            i = TWO;
            while (i <= sTurningobj.n_events)
                if (i < sTurningobj.n_events && sTurningobj.the_events(i).t > sTurningobj.the_events(i + ONE).t)
                    i = i + ONE;
                end
                if (e.t <= sTurningobj.the_events(i).t)
                    break;
                else
                    sTurningobj.the_events(coder.internal.indexDivide(i,TWO)) = sTurningobj.the_events(i);
                    i = i*TWO;
                end
            end
            sTurningobj.the_events(coder.internal.indexDivide(i,TWO)) = e;
        end

        % The heart of the algorithm:  Compute the minimum value of the
        % integral term of the metric by considering all critical events.
        % This also returns the theta* and event associated with the minimum.
        function [min_metric2, min_theta_star, min_e, hc0_err, slope_err] = h_t0min(sTurningobj, f, g, hc0, slope, alpha, d_update)

            e = struct('t',0,'fi',ZERO,'gi',ZERO); % current event
            % event of d^2_min thus far
            min_e = e; % implicit first event

            % At t = 0, theta_star is just alpha, and the min
            % metric2 seen so far is hc0 - min_theta_star^2.
            % Also, no error has been seen.

            min_theta_star = alpha; % theta*_min thus far
            min_metric2 = hc0 - (min_theta_star * min_theta_star); % d^2_min thus far
            last_t = 0; % t of last iteration
            hc0_err = 0; % error mags discovered on update
            slope_err = 0; % error mags discovered on update

            % Compute successive hc_i0's by incremental update
            % at critical events as described in the paper.

            while (sTurningobj.n_events > 0)
                [sTurningobj, e] = sTurningobj.next_event();

                hc0 = hc0 + (e.t - last_t) * slope;
                theta_star = alpha - (TWO_PI * e.t);
                metric2 = hc0 - (theta_star * theta_star);
                if (metric2 < min_metric2)
                    min_metric2 = metric2;
                    min_theta_star = theta_star;
                    min_e = e;
                end

                % Update slope, last t, and put next event for this g
                % discontinuity in the heap.
                tmp = 2 * (tr_theta(f, e.fi - 1) - tr_theta(f, e.fi)) * ...
                    (tr_theta(g, e.gi - 1) - tr_theta(g, e.gi));
                slope = slope + tmp;
                last_t = e.t;
                sTurningobj = sTurningobj.add_event(f, g, e.fi + 1, e.gi);

                % Re-establish hc0 and slope now and then
                % to reduce numerical error.  If d_update is 0, do nothing.
                % Note we don't update if an event is close, as this
                % causes numerical ambiguity. We force an update on last
                % event so there's always at least one.

                if (d_update && sTurningobj.n_events == 0)
                    [rihc0, rislope] = coder.internal.polyshapeHelper.sTurning.reinit_vals(f, g, e.fi, e.gi);
                    dhc0 = hc0 - rihc0;
                    dslope = slope - rislope;
                    if (abs(dhc0) > abs(hc0_err))
                        hc0_err = dhc0;
                    end
                    if (abs(dslope) > abs(slope_err))
                        slope_err = dslope;
                    end
                    hc0 = rihc0;
                    slope = rislope;
                end
            end
        end

    end
    
    properties
        the_events;
        n_events;
    end
end
%--------------------------------------------------------------------------

% Local function used in sTurning class.

% bound input angle 'a' within [base-PI, base+PI).
function a = bound_angle(theta, base)
neg_PI = -pi - 1.0e-6;
a = theta;
while (a - base < neg_PI)
    a = a + TWO_PI;
end
while (a - base >= pi)
    a = a - TWO_PI;
end
end

% Compute floor(log_base2(x)) for an indexInt
function L = ilog2(x)
L = coder.internal.indexInt(-1);
while (x ~= 0)
    x = eml_rshift(x,ONE);
    L = L + ONE;
end
end

function ttheta = tr_theta(tr, i)
coder.inline('always');
nt = tr.n();
if i < nt
    ttheta = tr.legs(i+ONE).theta;
else
    ttheta = tr.legs(tr.mod(i)).theta + (indexDivideAndCastToDouble(i,nt) * TWO_PI);
end
end

function tlen = tr_len(tr, i)
coder.inline('always');
tlen = tr.legs(tr.mod(i)).len;
end

function ts = tr_s(tr, i)
coder.inline('always');
nt = tr.n();
if i < nt
    ts = tr.legs(i+ONE).s;
else
    ts = tr.legs(tr.mod(i)).s + indexDivideAndCastToDouble(i,nt);
end
end

function m = ZERO
coder.inline('always');
m = coder.internal.indexInt(0);
end

function m = ONE
coder.inline('always');
m = coder.internal.indexInt(1);
end

function m = TWO
coder.inline('always');
m = coder.internal.indexInt(2);
end

function m = TWO_PI
coder.inline('always');
m = 2*pi;
end

function md = indexDivideAndCastToDouble(a,b)
coder.inline('always')
m = coder.internal.indexDivide(a,b);
md = double(m);
end
