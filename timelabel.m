function [rng,tmin,tmax] = timelabel(tm)
% TIMELABEL constructs a label for station button

    tmin = min(tm); tmax = max(tm);
    if (tmax - tmin) < 1; 
        form = 'mm/dd HHh'; 
    else
        form = 'mm/dd'; 
    end
    t1 = datestr(tmin,form);
    t2 = datestr(tmax,form);
    rng = [' (',t1,' - ',t2,')'];
