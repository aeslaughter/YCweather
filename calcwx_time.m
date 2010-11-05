function out = calcwx_time(d,varargin)
% CALCWX_TIME converts time data into MATLAB serial format
%__________________________________________________________________________
% SYNTAX: out = calcwx_time(d,varargin)
%
% INPUT: d = data structure containing time data (see read_dat.m)
%
%        varargin = can take on many forms, but must contain a list of
%        fields within "d" that contain the time data.  For example, for a
%        standard *.dat from Campbell Sci. dataloggers the time is given in
%        three columns: year (2007), day (165), and hour:min (1342). In
%        this varargin would be 'year', 'day', and 'hrmin'.  These would
%        need to be exactly name of the fields in "d" as assigned in
%        read_dat.m.  Additionally, the last input into varargin must be a
%        string that gives the code indicating the action to take on input,
%        see YCweather manual.
%__________________________________________________________________________

% 1 - Read the date code
    n = length(varargin);
    code = varargin{n};

% 2 - Read the dates from the structure, converting to strings
    for i = 1:n-1;  a{i} = d.(varargin{i}).data; end

% 3 - Convert time data to MATLAB form based on input code
switch code
    case 'CSI';     time = CSIconvert(a{1},a{2},a{3});
    case 'GNFAC';   time = GNFACconvert(a{1},a{2},a{3},a{4});
end

% 4 - Build output structure
    out.data = time;
    out.display = 0;

%--------------------------------------------------------------------------
function TIME = CSIconvert(YR,DAY,HRMIN)
% CSICONVERT calculates the MATLAB date/time from CSI datalogger format.
%__________________________________________________________________________
% USAGE: X = CSIconvert(YR,DAY,HRMIN)
% INPUT:
%   YR    = numeric array containing year, yyyy
%   DAY   = numeric array containing 3 digit day of year
%   HRMIN = numeric array containig numeric hours and minutes, HHMM
%
% OUTPUT:
%   TIME = numeric array with date/time in MATLAB format
%__________________________________________________________________________

HR = floor(HRMIN/100);
MN = HRMIN - HR*100;
TIME = datenum(YR,0,DAY,HR,MN,0);

%--------------------------------------------------------------------------
function TIME = GNFACconvert(YR,MONTH,DAY,HRMIN)
% CSICONVERT calculates the MATLAB date/time from CSI datalogger format.
%__________________________________________________________________________
% USAGE: XTIME = GNFACconvert(YR,DAY,HRMIN)
% INPUT:
%   YR    = numeric array containing year, yyyy
%   MONTH = numeric array containing month, mm
%   DAY   = numeric array containing 3 digit day of year
%   HRMIN = numeric array containig numeric hours and minutes, HHMM
%
% OUTPUT:
%   TIME = numeric array with date/time in MATLAB format
%__________________________________________________________________________

HR = floor(HRMIN/100);
MN = HRMIN - HR*100;
TIME = datenum(YR,MONTH,DAY,HR,MN,0);
