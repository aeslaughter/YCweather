function callback_plotTCdata(hObject,eventdata)
% CALLBACK_PLOTTCDATA plots thermocouple data with depth
%__________________________________________________________________________
% USAGE: callback_plotTCdata(hObject,eventdata)
%
% INPUT: hObject - handle of object associated with Program Control
%        eventdata - not used, MATLAB required
%__________________________________________________________________________

try
% 1 - PREPARE DATA
    % 1.1 - Determine the selected stations
        use = getselected(hObject);
        if isempty(use); disp('No station selected'); end

    % 1.2 - Get GUI information
        GUI = guidata(hObject);  t = GUI.time;
        h = guihandles(hObject);

% 2 - PLOT THERMOCOUPLE DATA
    for i = 1:length(use);

    % 2.1 - Extract TC data from the selected station
        data  = get(h.(use{i}),'UserData');
        [TC,depth,time] = seperateTCdata(data);
        if isempty(TC); break; end

    % 2.2 - Build a plot of available data
        for ii = 1:length(TC);      
            plotTC(TC{ii},depth{ii},time{ii},t,h,ii,data);
        end
 end

catch
    mes = ['Error generating thermocouple profile ',...
            '(callback_plotTDdata.m), see errorlog.txt.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% SUBFUNCTION: plotTC
function plotTC(TC,depth,time,t,h,num,user)

% 1 - Seperate data between date/times
    idx = time >= t(1) & time <= t(2);
    TC = TC(:,idx);
    time = time(idx);

    if isempty(time);
        mes = ['No data exists for ',user.group,': ',...
                user.display,' between the selected date/times.'];
        warndlg(mes,'WARNING!'); return;
    end

% 2 - Seperate data at intervals and build a matching depth matrix
    [TC,LGND] = interval(TC,time,h.interval);
    for ii = 1:size(TC,2); Y(:,ii) = depth; end;        

% 3 - Warn user if a large plot will be created
    if length(TC) > 20;
        mes = ['The resulting plot would contain ',...
            num2str(length(TC)),' lines, would you like to continue?'];
        q = questdlg(mes,'WARNING!','Continue','Cancel','Cancel');
        if ~strcmpi(q,'Continue'); return; end
    end

% 4 - Set depth limits
    expose = get(h.surface,'Value');

% 5 - Remove un-reasonable data
    idx = TC < -50 | TC > 20;
    TC(idx) = NaN;
    Y(idx)  = NaN;
    
% 6 - Plot the data
    head = [user.group,': ',user.display,' (',num2str(num),')'];  
    XYscatter(TC,Y,'Legend',LGND,'Ydir','reverse',...
        'ylabel','Depth (cm)','xlabel','Temperature (C)','name',head);
 
% 7 - Add surface line
    if expose > 1;
        x = xlim;
        y = [Y(expose,1),Y(expose,1)];
        line(x,y,'LineStyle','-','Color','k','LineWidth',1.5);
    end


%--------------------------------------------------------------------------
% SUBFUNCTION: seperateTCdata
function [TC,depth,time] = seperateTCdata(data)
% SEPERATETCDATA extracts thermocouple data from available variables

% 1 - Initilize output data
    tag = textscan(data.TCprofile,'%s','delimiter',','); tag = tag{1}; 
    if strcmpi('none',tag); return; end

% 2 - Seperate thermocouple data base on TCprofile tag
    % 2.1 - Loop through all comma seperated tags listed
    for j = 1:length(tag);
        % 2.1.1 - Initilize variables for current tag
            n   = length(tag{j});
            var = fieldnames(data.variables);
            tg  = tag{j};
            TC{j} = []; depth{j} = []; time{j} = [];
        
        % Seperates data for current tag
        for i = 1:length(var);
            if length(var{i}) >= n
                test = var{i}(1:n);

                % If the tag matches extract the data
                if strcmp(test,tg);
                    TC{j} = [TC{j};data.variables.(var{i}).data'];
                    d = str2double(var{i}(length(tg)+1:length(var{i})));
                    depth{j} = [depth{j};d];
                    time{j}  = data.Time;
    end,end,end,end

%--------------------------------------------------------------------------
% SUBFUNCTION: interval
function [TC,lgnd] = interval(TCin,time,handle)
% INTERVAL removes data not corresponding to desired plotting interval

% Determine the interval
    str = get(handle,'String');
    int = str2double(str{get(handle,'Value')});

% Cycle through data and store for desried interval
    next = time(1) + int/24/60;
    k = 1;
    for i = 1:length(time);
        cur = time(i);

        if next <= cur;
            TC(:,k) = TCin(:,i);
            lgnd{k} = datestr(cur,'mmm-dd HH:MM');
            k = k + 1;
            next = cur + int/24/60;
    end,end
