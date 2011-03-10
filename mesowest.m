function X = mesowest(stn,name,tm,sea)
% MESOWEST gather data from MesoWest website.

% 1 - INTILIZE PARAMETERS FOR GATHERING THE DATA
    % 1.1 - Setup numbers of hours desired and counters
    n = (tm(2) - tm(1))*24; % Number of hours
    K = ceil(n/24); % Total number of days
    k = 1; % Counter

    % 1.2 - Intialize variables and establish waitbar
    cur_time = tm(2); % Current time
    T = []; % Time array
    data = []; % Data array
    hbar = waitbar(0,['Updating ',name,' (',stn,...
        ') data , please wait...']);

    
% 2 - LOOP THROUGH THE DESIRED DAYS
for i = n:-24:0;
    % 2.1 - Set the number of hours desired for this day
    if i > 24; 
        hours = 24;
    else
        hours = i;
    end
    
    % 2.2 - Collect the data and parameters
    [t,d,parm{k}] = gatherwebdata(cur_time,hours,stn);
    if isnan(t); X = []; close(hbar); return; end
    parm_size = length(parm{k});
    
    % 2.3 - Adjust for array mismatchs (some files have data that is only
    % displayed on a daily basis, so in some cases when a partial day is
    % downloaded this daily data will not be present, this accounts for
    % that issue)
    sz_d = size(d,2);       % Size of the data just downloaded
    sz_data = size(data,2); % Size of the complete data set being built
    
    if i ~= n && sz_d > sz_data; % Case when new is bigger than total
        padsize = [0, sz_d - sz_data];
        data = padarray(data, padsize , NaN, 'post');
        
    elseif i ~= n && sz_d < sz_data; % Case when total is bigger than new
        padsize =  [0, sz_data - sz_d];
        data = padarray(d, padsize, NaN, 'post');
        
    elseif ~isempty(d); % Otherwise they are the same, but ignore empty
        T = [T;t];
        data = [data;d];
    end
    
    % 2.4 - Update the time and counter
    cur_time = cur_time - hours/24;
    k = k + 1;
    
    % 2.5 - Update the waitbar
    waitbar(k/K,hbar);
end
close(hbar);

% 3 - CONVERT TO DATA STRUCTURE
    [~,loc] = max(parm_size);
    parm = parm{loc};

    info = load('mesowest.mwu','-mat');
    for i = 1:length(parm);
        if isfield(info,parm{i}) && ~strcmpi('QFLG',parm{i});
            var.(parm{i}).data = data(:,i);
            var.(parm{i}).label = info.(parm{i}).description;
            var.(parm{i}).unit = info.(parm{i}).metric;
        end
    end

% 4 - RE-BUILD DATA STRUCTURE FOR OUTPUT
    X.Time = T;    
    X.display = name;
    X.variables = var;
    X.group = 'Mesowest';
    X.subfolder = stn;
    X.season = sea;
    X.arraryID = NaN;
    X.datfile = '';
    X.TCprofile = 'none';

%--------------------------------------------------------------------------
function [T,data,parm] = gatherwebdata(tm,hours,stn)

% 1 - SET THE KNOWN URL INPUTS
    unit = '1'; % 0=english; 1=metric
    time = 'LOCAL';
    
% 2 - COMPUTE THE NECESSARY URL INPUTS
    [Y, M, D, H, MN, S] = datevec(tm);
    day1 = num2str(D,'%02i');
    month1 = num2str(M,'%02i');
    year1 = num2str(Y,'%02i');
    hour1 = num2str(H,'%02i');
    if hours < 0
        mes = ['An error occured computing the desired time range from',...
            ' MesoWest, using the past 24 hours.'];
        warning(mes);
        hours = 24;
    end
    hours = num2str(ceil(hours),'%g');
 
% 3 - ESTABLISH THE URL    
    url = ['http://mesowest.utah.edu/cgi-bin/droman/',...
        'meso_download_mesowest.cgi?product=&stn=',stn,'&unit=',unit,...
        '&time=',time,'&day1=',day1,'&month1=',month1,'&year1=',year1,...
        '&hour1=',hour1,'&hours=',hours,'&output=csv'];
    
% 4 - READ THE URL    
    try
        s = urlread(url);
    catch
        warning('URL:failed',['Could not read url: ',url]); 
        T = []; data = []; parm = {}; name = '';
        return;
    end
    
% 5 - CHECK FOR ERRORS
    % 5.1 - Seprate the data by line
        C = textscan(s,'%s','delimiter','\n'); C = C{1};
    
    % 5.2 - Locate the title 
        test_str = ['<TITLE>',stn,'</TITLE>'];
        k = strcmpi(test_str,C);
        
    % 5.3 - Return if station doesn't match
    if all(k == 0)
        mes = [stn,' caused an error during read!']; 
        X = []; warning(mes); return;
    end
    
% 6 - EXTRACT THE WEATHER DATA    
    [T,data,parm] = extractdata(C,stn);

%--------------------------------------------------------------------------
function [tm,data,parm] = extractdata(C,stn)
% EXTRACTDATA

% 1 - DETERMINE STATION NAME
    itm = C{9};
%     strt = strfind(itm,stn) + length(stn);
%     for i = strt:length(itm);
%         if ~isnan(str2double(itm(i))); stp = i-1; break; end
%     end
%     name = lower(strtrim(itm(strt:stp)));
%     name(1) = upper(name(1));
    
% 2 - REMOVE THE PARAMETER LABELS  
    parm_idx = strmatch('PARM',C);
    parm = textscan(C{parm_idx},'%s','delimiter',',=');
    if isempty(parm); 
        tm = NaN; data = NaN;
        return;
    end
        
    parm = parm{1}(2:end);

% 3 - REMOVE THE WEATHER DATA   
    data_idx = [strmatch('<PRE>',C),strmatch('</PRE>',C)];
    data = C(data_idx(1)+3:data_idx(2)-1); 
    
% 4 - CONVERT TO CELL ARRAY STRINGS   
    k = 1;
    for i = 1:length(data)
        if ~isempty(data{i});
            D = textscan(data{i},'%s','delimiter',',');
            raw(k,1:length(D{1})) = D{1};
            k = k + 1;
        end
    end

% 5 - CONVERT THE DATA TO A NUMERIC ARRAY   
    data = str2double(raw);   

% 6 - COMPUTE THE TIME IN MATLAB FORMAT
    MON = data(:,1); DAY = data(:,2); YEAR = data(:,3);
    HR = data(:,4); MIN = data(:,5);
    tm = datenum(YEAR,MON,DAY,HR,MIN,0);
    
    