function callback_season(hObject,eventdata)
% CALLBACK_SEASON updates the data displayed by YCweather
%__________________________________________________________________________
% USAGE: callback_season(hObject,eventdata)
%
% INPUT:
%   hObject - current object 
%   eventdata - reserved for future use (MATLAB required)
%
% OUTPUT: none
%
% PROGRAM OUTLINE:
%   1 - DETERMINE THE SELECTED SEASON
%   2 - READ *.yc FORMAT FILES AND WEATHER DATA
%   3 - ELIMINATE BUTTONS FROM THE PREVIOUS SELECTION
%   4 - RESIZE THE DATE PANEL, STATION SELECTION PANEL, AND MAIN WINDOW   
%   5 - BUILD THE INDIVIDUAL STATION PANELS AND STATION BUTTONS   
%   SUBFUNCTION: PLACEBUTTONS
%   SUBFUNCTION: GROUPSTATIONS
%__________________________________________________________________________
try
% 1 - DETERMINE THE SELECTED SEASON
    h       = guihandles(hObject);
    GUI     = guidata(hObject);
    gui     = ancestor(hObject,'figure','toplevel');
    str     = get(h.season,'String');
    season  = str{get(h.season,'Value')};
    db      = [GUI.settings.paths.database,season,filesep];

% 2 - READ *.yc FORMAT FILES AND WEATHER DATA
    % 2.1 - Collect files from format directory for current season
        loc = [GUI.settings.paths.database,season,'\'];
        files = dir([loc,'*.yc']); 
        k = 1; groups = {}; % Eintilize storage
        
    % 2.2 - Read *.yc files    
        if ~isempty(files);
            disp('Opening data files, please wait...');
            nfiles = length(files);
            
            for i = 1:nfiles;
                % 2.2.1 - Read file
                filename   = [loc,files(i).name];
                [~,name]   = fileparts(filename);
                temp       = read_dat(filename);
                tag = temp.tag; S.(tag) = temp;

                % 2.2.2 - Store/remove file information
                if ~isfield(S.(tag),'variables'); 
                    S = rmfield(S,tag);
                else
                    groups{k} = S.(tag).group;
                    k = k + 1;
                end
            end    
        end

    % 2.3 - Add mesowest data
    mesofile = [db,'mesowest.txt'];
    mh = [h.mesowest_btn,h.mesowest_menu];
    set(mh,'enable','off');
    if exist([db,'mesowest.txt'],'file') ...
            && GUI.settings.pref.allowmesowest == 1;
        fid = fopen(mesofile);
        W = textscan(fid,'%s%s%s','delimiter',',');
        stn = W{1}; nm = W{2}; grp = W{3};
        fclose(fid);
        for i = 1:length(stn);
            tag = [stn{i},'_mesowest'];
            S.(tag) = emptystation(GUI);
            S.(tag).display = nm{i};
            S.(tag).group = grp{i};
            S.(tag).subfolder = stn{i};
            
            groups{k} = grp{i};
            k = k + 1;
            set(mh,'enable','on');
        end
    end
    
    % 2.4 - Return if no data was collected
    if k == 0;
        warndlg('No weather data files exist for this folder!',...
                'ERROR');
            return;
    end
 
    % 2.5 - Group the read data according to location
        if isempty(groups);
            errordlg('No weather data located!','ERROR'); return;
        end
        groups  = unique(groups);
        sta_grp = group_items(S,groups,'group');

% 3 - ELIMINATE BUTTONS FROM THE PREVIOUS SELECTION
    child = get(h.stationpanel,'children');
    if ~isempty(child); delete(child); end
    
% 4 - RESIZE THE DATE PANEL, STATION SELECTION PANEL, AND MAIN WINDOW
    % 4.1 - Determine the height of each station panel
        sp = get(h.stationpanel,'Position');
        Hb  = 0.45;  % Height of button
        spc = 0.1;   % Spacing
        Wp = (sp(3)- spc*6)/2; % Width of station panels

        for i = 1:length(sta_grp);
            Hp(i) = length(sta_grp{i})*(Hb)+ 4*spc;
        end

    % 4.2 - Determine the number of panels per column
        numP = length(sta_grp);
        col(1) = ceil(numP/2);
        col(2) = numP - col(1);

    % 4.3 - Determine the new height of main window and panels
        % 4.3.1 - Height of each column
            Hcol(1) = sum(Hp(1:col(1))+spc);
            Hcol(2) = sum(Hp(col(1)+1:col(1)+col(2)) + spc);
    
        % 4.3.2 - New height of Station Selection Panel
            Htot = max(Hcol + 6*spc);
            if Htot < 3; Htot = 3; end

            P_sel    = get(h.stationpanel,'Position');
            P_sel(4) = Htot;
        
        % 4.3.3 -  New location of Date Panel
            P_date    = get(h.datepanel,'Position');
            P_date(2) = P_sel(4) + 4*spc;
        
        % 4.3.4 - New Size of Program Control Window  
            set(gui,'Units','Centimeters');
            P_main = get(gui,'Position');
            P_main(4) = P_sel(4) + P_date(4) + 6*spc;
        
        % 4.3.5 - Set the new positions
            set(h.stationpanel,'Position',P_sel);
            set(h.datepanel,'Position',P_date);
            set(gui,'Position',P_main);
            set(gui,'Units','Centimeters');
     
% 5 - BUILD THE INDIVIDUAL STATION PANELS AND STATION BUTTONS   
    clr = [0.6,0.6,0.6]; % Color of station panels

    % 5.1 - Build the First Column
        % 5.1.1 - Seperate the first column data
            grp_1 = groups(1:col(1));   % Groups in first column
            ht_1  = Hp(1:col(1));       % Heights of above groups
            tag_1 = sta_grp(1:col(1));
            P(2)  = P_sel(4)-4*spc;     % Top of the Station Selection Panel
    
        tmin = []; tmax = [];
        % 5.1.2 - Build panels and place buttons inside each panel
        for i = 1:col(1);
            P(1)  = spc;                        % Left location
            P(2)  = P(2) - spc - ht_1(i);       % Botton location
            P(3)  = Wp;                         % Panel width
            P(4)  = ht_1(i);                    % Panel height

            % Build the panel
            btn = uipanel(h.stationpanel,'Units','centimeters',...
                'Position',P,'Title',grp_1{i},'BorderType','Line',...
                'ForegroundColor',clr);

            % Insert the buttons
            [t1,t2] = placebuttons(btn,tag_1{i},S);
            tmin = [tmin,t1]; tmax = [tmax,t2];
        end
        
    % 5.2 - Build the Second Column (if it exists)
        if col(2) > 0
        % 5.2.1 - Seperate the second column data
            grp_2 = groups(col(1)+1:numP); % Groups in second column
            ht_2  = Hp(col(1)+1:numP);     % Heights of above groups
            tag_2 = sta_grp(col(1)+1:numP);
            P(2)  = P_sel(4)-4*spc;        % Top of the Station Selection
    
        % 5.2.2 - Build the panels and place the button inside each panel    
            for i = 1:col(2);
                P(1)  = Wp+3*spc;               % Left location
                P(2)  = P(2) - spc - ht_2(i);   % Bottom location
                P(3)  = Wp;                     % Width of panel
                P(4)  = ht_2(i);                % Height of panel

                % Build the panel
                btn = uipanel(h.stationpanel,'Units','centimeters',...
                    'Position',P,'Title',grp_2{i},'BorderType','Line',...
                    'ForegroundColor',clr);

                % Insert the buttons
                [t1,t2] = placebuttons(btn,tag_2{i},S);
                tmin = [tmin,t1]; tmax = [tmax,t2];
            end 
        end

% 6 - SET YEAR AND RETURN DATA
    % 6.1 - Determine the min and max year in current data set
        yr1 = str2double(datestr(min(tmin),'yyyy'));
        yr2 = str2double(datestr(max(tmax),'yyyy'));
        yr  = num2cell(yr1:yr2);
        set(h.strtyear,'String',yr,'Value',length(yr)); 
        set(h.endyear,'String',yr,'Value',length(yr));

    % 6.2 - Place the new height into the siderbar structure
        set(gui,'Units','Centimeters');
        P = get(gui,'Position');
        P(3) = 12.5;
        GUI.sidebar.alloff = P;

    % 6.2 - Return GUI data and reset time
        GUI.season = season;
        guidata(gui,GUI);
        callback_settime(hObject,[]);
                
% 7 - RESET SIDEBARS
    if isfield(h,'TCpanel'); 
        delete([h.TCpanel,h.SEARCHpanel,h.INPUTpanel]);
    end
    buildsidebars(gui);
    disp('Complete.');
    %movegui(gui,'onscreen');

catch
    mes = ['Error occured opening data from season/folder popup',...
            ' (callback_season.m), see errorlog.txt.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% SUBFUNCTION: PLACEBUTTONS inserts buttons into the individual station
% panels
function [tmin,tmax] = placebuttons(btn,tag,S)
    
% 1 - Establish the geometry for placing buttons
    spc = 0.1;   % Space between buttons
    w = 5.6;     % Width of buttons
    ht = 0.45;   % Height of button
    
% 2 - Set the buttons    
    bot = 0;        % Initilize botton location

    for i = 1:length(tag);
        % 2.1 - Build time label
            [rng,tmin(i),tmax(i)] = timelabel(S.(tag{i}).Time);

        % 2.2 - Build the button
            label = S.(tag{i}).display;
            pos = [spc,bot,w,ht];
            id = uicontrol(btn,'Style','radiobutton');
            set(id,'Units','centimeters','String',[label,rng]);
            set(id,'Position',pos);
            set(id,'Tag',tag{i},'callback',{@callback_station});
            set(id,'UserData',S.(tag{i}));
        
        % 2.3 - Determine the location for the next button
            bot = bot + ht;
    end

%--------------------------------------------------------------------------
% SUBFUNCTION: CALLBACK_STATION changes lists of station in data structure
function callback_station(hObject,eventdata)

% 1 - Get the GUI information handles and structure
    h = guihandles(hObject);
    GUI = guidata(hObject);

% 2 - Gather the selected stations
    b = findobj(h.stationpanel,'Value',1);
    GUI.settings.stations = get(b,{'Tag'});

% 3 - Return the data structure
    guidata(hObject,GUI);
    
% % 4 - Update MESOWEST data
    test = strfind(get(hObject,'Tag'),'_mesowest');
    if get(hObject,'Value') == 1 && ~isempty(test);
        callback_updatemesowest(h.mesowest_btn,[],hObject);
    end
    
%--------------------------------------------------------------------------
function X = emptystation(GUI)
% EMPTYSTATION produces an empty data structure (same as read_dat)

    X.Time = GUI.time;    
    X.display = '';
    X.variables = struct([]);
    X.group = '';
    X.subfolder = '';
    X.season = GUI.season;
    X.arraryID = NaN;
    X.datfile = '';
    X.TCprofile = 'none';
    