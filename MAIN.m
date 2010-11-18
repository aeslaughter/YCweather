function gui = MAIN
% MAIN is the controlling program for the YCweather software.
%__________________________________________________________________________
% SYNTAX: gui = MAIN;
%
% INPUT: none
% OUTPUT: gui - handle for the main program
%
% PROGRAM OUTLINE:
% 1 - BUILD PROGRAM CONTROL WINDOW
% 2 - AUTOMATICALLY DOWNLOAD LATEST DATA
% 3 - BUILD THE GUI MENUS AND PANELS
% 4 - INITILIZE THE PROGRAM AND SIDEBARS
% CALLBACK: help
% CALLBACK: exit
% CALLBACK: about
% SUBFUNTION: buildgui
% SUBFUNCTION: create_defaultWS 
%__________________________________________________________________________
close all;
try
    
% 1 - BUILD PROGRAM CONTROL WINDOW
    % 1.1 - Default Position settings
        loc = [1,1,12.5,6.05];

    % 1.2 - Program Control created
        gui = dialog('Resize','off','WindowStyle','normal','Units',...
            'centimeters','Position',loc,'Name','Program Control',...
            'IntegerHandle','off','visible','off','tag','YCweather');
        set(gui,'units','normalized','HandleVisibility','on');
        
    % 1.3 - Load default file, creating if needed
        def = create_defaultWS;
        if ~exist([cd,'\default.mat'],'file');  
            save('default.mat','-mat','-struct','def');
        end
        GUI = load([cd,'\default.mat'],'-mat');
        guidata(gui,GUI);
        
    % 1.4 - Create "saved" directory
        svd = [cd,'\saved\'];
        if ~exist(svd,'dir'); mkdir(svd); end
        
    % 1.5 - Add YCmain directory to PATH
        %str = ['!path=%PATH%;',cd]; eval(str);

% 2 - AUTOMATICALLY DOWNLOAD LATEST DATA
    update = GUI.settings.pref.autoWx;
    if update == 1; callback_syncdata(gui,'current'); end

% 3 - BUILD THE GUI MENUS AND PANELS
    buildGUI(gui);        
          
% 4 - INITILIZE THE PROGRAM AND SIDEBARS
    callback_readWS(gui,[],[cd,'\default.mat']);  
    GUI = guidata(gui);
    GUI.main = gui;
    GUI.version = 0.72;        
    GUI.verdate = 'Nov. 18, 2010';
    guidata(gui,GUI); 
    save('default.mat','-mat','-struct','GUI');       
    set(gui,'Visible','on');

catch
    mes = ['An error occured when trying to open YCweather (MAIN.m)',...
            ', see errorlog.txt for details.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% function winscp(hObject,eventdata)
% WINSCP allows qualified user to download images and logs

% S{1} = '!winscp419.exe caesar.ce.montana.edu ';
% S{2} = '/console /command exclude /.svn ';
% S{3} = ['"synchronize local ',cd,filesep,'database',' /home/snow/db" '];
% S{4} = '"exit" &';
% eval([S{:}]);

%--------------------------------------------------------------------------
% CALLBACK: help
function help(~,~,~)
    if exist('help.pdf','file');
        winopen('help.pdf');
    else
        web('http://www.coe.montana.edu/ce/subzero/snow/help.pdf',...
            '-browser');
    end

%--------------------------------------------------------------------------
% CALLBACK: exit
function exit(~,~,~)
close all; fclose all;

%--------------------------------------------------------------------------
function about(~,~,gui)
% ABOUT opens the Snow Optics Toolbox information window

GUI = guidata(gui);
textbox = {['Version: ',num2str(GUI.version),' (',GUI.verdate,')'];
           'Andrew E. Slaughter (andrew.e.slaughter@gmail.com)';
           'Montana State University';
           'http://www.coe.montana.edu/ce/subzero/snow';
           'http://github.com/aeslaughter/YCweather'};
       
fid = fopen('license.txt','r');       
lic = textscan(fid,'%s','delimiter','\n'); lic = lic{1};
fclose(fid);

d = dialog('Units','Normalized','Position',[0.375,0.3,0.26,0.4],'Name',...
    'YCweather','WindowStyle','Normal');
annotation(d,'textbox',[0.005,0.88,0.99,0.1],'String','YCweather',...
    'FontSize',10,'EdgeColor','none','FontWeight','Bold');
annotation(d,'textbox',[0.01,0.76,0.98,0.18],'String',textbox,...
    'FontSize',9,'EdgeColor','none','VerticalAlignment','top');
annotation(d,'textbox',[0.01,0.01,0.98,0.74],'String',lic,'FontSize',8);

%--------------------------------------------------------------------------     
% SUBFUNTION: buildgui 
function buildGUI(gui)
% BUILDGUI constructs the main program window and associated
% buttons and menus

% 1 - SET STATION AND DATE/TIME PANELS
    % 1.1 - Set the date selection panel
        datepanel = uipanel('Parent',gui,'Units','centimeters',...
        'Position',[0.15,3.3,12.2,2.6],'title','Date/Time:',...
        'Tag','datepanel','FontWeight','Bold');
    % 1.2 - Set the station button panel
        loc = [0.15,0.15,12.2,3];
        uibuttongroup(gui,'Units','centimeters','Position',loc,...
            'Tag','stationpanel','title','Station Selection:',...
            'FontWeight','Bold');
    
%2 - SET DATE/TIME SELCECTION POPUPMENUS
    % 2.1 - Set text for folder/season pop-up menu
        uicontrol('Parent',datepanel,'Style','text','String',....
            'Folder/Season Selection:','Units','centimeters','Position',...
            [0.3,1.3,3.5,0.5],'HorizontalAlignment','left',...
            'Tag','seasonTXT');
        uicontrol('Parent',datepanel,'Style','popupmenu',...
            'Units','centimeters','Position',[0.3,0.9,3.5,0.5],...
            'Callback',{'callback_season'},'Tag','season');

    % 2.2 - Establish the popupmenu dimensions
        l = 5.5; spc = 0.1;         % Left location and spacing
        b = [1.6,1.2,0.6];          % Bottom location of each row
        h = 0.5;                    % Height
        w = [1.4,1.2,1.1,1.1,1.1];  % Widths of each column

    % 2.3 - Establish the item tags, style, and string properties
        % 2.3.1 - Tags are row and column dependent (e.g. txtyear) is the
        % tag for the txt row and the year column
            tag1 = {'txt','strt','end'};                % Rows
            tag2 = {'year','month','day','hr','min'};   % Columns

        % 2.3.2 - Styles are row dependent only
            style  = {'text','popupmenu','popupmenu'};  

        % 2.3.3 - Strings are row and column dependent
            % Build popupmenu cell arrays
            yr = datestr(now,'yyyy');
            month = {'Jan','Feb','Mar','Apr','May','Jun',...
                    'Jul','Aug','Sept','Oct','Nov','Dec'};
            day = num2cell(1:31);
            hr = num2cell(0:23);
            mn = num2cell(0:60);

            % Build cell array for each row
            str{1} = {'Year','Month','Day','Hour','Minute'};
            str{2} = {yr,month,day,hr,mn}; 
            str{3} = str{2};
    
    % 2.4 - Build the popupmenu items and associated labels
        for i = 1:length(tag1); 
            left = l; % Resets the left position
                for ii = 1:length(tag2);
                    P = [left,b(i),w(ii),h];    % Current position
                    uicontrol('Parent',datepanel,'Style',style{i},...
                        'String',str{i}{ii},'Units','Centimeter',...
                        'Position',P,'HorizontalAlignment',...
                        'center','Tag',[tag1{i},tag2{ii}],...
                        'callback',{'callback_settime'});
                    left = left + w(ii) + spc; % Update left position
        end,end

    % 2.5 - Build the start/end labels for the popupmenu rows
    uicontrol('Parent',datepanel,'Style','text','String','START:',...
        'Units','centimeters','Position',[l-1.05,b(2)-0.1,1,0.5],...
        'HorizontalAlignment','right');
    uicontrol('Parent',datepanel,'Style','text','String','END:',...
        'Units','centimeters','Position',[l-1.05,b(3)-0.1,1,0.5],...
        'HorizontalAlignment','right');

% 3 - ESTABLISH MENU BAR ITEMS
    % 3.1 - File menu
        file_menu = uimenu('Parent',gui,'Label','File','Callback',...
            {'callback_recent'},'tag','Fmenu');
        uimenu(file_menu,'Label','Save Workspace','Callback',...
            {'callback_saveWS'},'Separator','off','Accelerator','S');
        uimenu(file_menu,'Label','Open Workspace','Callback',...
            {'callback_readWS'},'Separator','off','Accelerator','O');
        uimenu(file_menu,'Label','Open Recent','tag','recent');
        uimenu(file_menu,'Label','Set Default Workspace','Callback',...
            {'callback_saveWS','default.mat'},'Separator','on');
        uimenu(file_menu,'Label','Open Default Workspace','Callback',...
            {'callback_readWS','default.mat'},'Separator','off');
        uimenu(file_menu,'Label','Preferences','Callback',...
            {'callback_pref'},'Separator','on');
        uimenu(file_menu,'Label','Exit','Callback',{@exit,gui},...
            'Separator','on','Accelerator','Q');
    
    % 3.2 - Plot menu
        plot_menu = uimenu('Parent',gui,'Label','Plot','tag','Pmenu');
        uimenu(plot_menu,'Label','Open Data List','Callback',...
            {'callback_varmenu'},'Accelerator','v');
        uimenu(plot_menu,'Label','Weather Data','Callback',...
            {'callback_plotdata'},...
            'Accelerator','W');

    % 3.3 - Data menu
        records_menu = uimenu('Parent',gui,'Label','Data','tag','Dmenu');
            uimenu(records_menu,'Label','Check for new  weather data',...
                'Callback',{'callback_syncdata'},'Accelerator','n');
            uimenu(records_menu,'Label','Update MesoWest data',...
                'Callback',{'callback_updatemesowest',true},'Accelerator','M',...
                'enable','off','Tag','mesowest_menu');
            uimenu(records_menu,'Label','Open Image Viewer','Callback',...
                {'callback_openimage'},'Separator','on',...
                'Accelerator','I','tag','openimage');
            uimenu(records_menu,'Label','Open Daily Logs','Callback',...
                {'callback_openlog'},'Accelerator','L','tag','openlog');
    
    % 3.4 - Panels menu
        window_menu = uimenu('Parent',gui,'Label','Panels','tag','window');
            uimenu(window_menu,'Label','Search Window',...
                'Callback',{'callback_sidebar',gui},'Accelerator','R',...
                'UserData','SEARCHpanel','tag','SEARCHcheck'); 
            uimenu(window_menu,'Label','Add Daily Log/Image(s)',...
                'Callback',{'callback_sidebar',gui},'Accelerator','A',...
                'UserData','INPUTpanel','tag','INPUTcheck');
            uimenu(window_menu,'Label','TC Profile Window','Callback',...
                {'callback_sidebar',gui},'Accelerator','T',...
                'UserData','TCpanel','tag','TCcheck');
          
    % 3.5 - Output menu   
        output_menu = uimenu('Parent',gui,'Label','Output','tag','Omenu');
        
        % 3.5.1 - Write to file options
        f1 = uimenu(output_menu,'Label','...to File');
            uimenu(f1,'Label','All data','Callback',...
                {'callback_export','all'});
            uimenu(f1,'Label','Selected data','Callback',...
                {'callback_export','selected'});

        % 3.5.2 - Output to Radtherm option        
        uimenu(output_menu,'Label','...to RadTherm','Callback',...
            {'radthermGUI'});
        
        % 3.5.3 - Output thermal modeol otiops
%         uimenu(output_menu,'Label','...to Thermal Model','Callback',...
%             {'thermGUI'});

    % 3.6 - Help menu
        help_menu = uimenu('Parent',gui,'Label','Help','tag','Hmenu');
        uimenu(help_menu,'Label','Help','Callback',{@help,gui},...
            'Accelerator','H');
        uimenu(help_menu,'Label','About','Callback',...
            {@about,gui},'Separator','on');   

% 4 - ESTABLISH TOOLBAR ITEMS
    % 4.1 - Open icon file and estblish toolbar
        icon = load('icons.ico','-mat');
        tbar = uitoolbar(gui);

    % 4.2 - Open/save/pref/list/plot buttons
        uipushtool(tbar,'Cdata',icon.open,'TooltipString',...
            'open workspace','ClickedCallback',{'callback_readWS'});
        uipushtool(tbar,'Cdata',icon.save,'TooltipString',...
            'save workspace','ClickedCallback',{'callback_saveWS'});
        uipushtool(tbar,'Cdata',icon.pref,'TooltipString',...
            'preferences','ClickedCallback',{'callback_pref'},...
            'separator','on');
        uipushtool(tbar,'Cdata',icon.mesowest,'TooltipString',...
            'update MesoWest data','separator','on','ClickedCallback',...
            {'callback_updatemesowest',true},'Tag','mesowest_btn');               
        uipushtool(tbar,'Cdata',icon.list,'TooltipString',...
            'weather data list','ClickedCallback',{'callback_varmenu'},...
            'separator','off');
        uipushtool(tbar,'Cdata',icon.plot,'TooltipString',...
            'plot weather data','ClickedCallback',{'callback_plotdata'});
       
    % 4.3 - Open logs/images buttons
    	uipushtool(tbar,'Cdata',icon.image,'TooltipString',...
            'open image(s)','separator','on','ClickedCallback',...
            {'callback_openimage'});
    	uipushtool(tbar,'Cdata',icon.log,'TooltipString',...
            'open daily log(s)','ClickedCallback',{'callback_openlog'});
