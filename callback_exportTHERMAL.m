function callback_exportTHERMAL(hObject,eventdata)
% CALLBACK_EXPORTTHERMAL opens a GUI for exporting data to thermal model
%__________________________________________________________________________
% USAGE: callback_exportTHERMAL(hObject,eventdata)
%
% INPUT: hObject - handles of calling object
%        eventdata - not used, MATLAB required
%
% OUTPUT: none
%
% PROGRAM OUTLINE:
% 1 - OPEN THE GUI
% 2 - INITILIZE THE ATMOSPHERIC DATA
% 3 - SET GUI DATA
% 4 - COLLECT DATA FROM THE *thermal.thrm FILE
% 5 - SET START/END TIMES
% 6 - SET CALLBACKS
% CALLBACK: exit
% CALLBACK: callback_savefcn
% CALLBACK: callback_openfcn
% CALLBACK: callback_settimes
% SUBFUNCTION: getTCdata
% CALLBACK: callback_variable
% CALLBACK: callback_station
% CALLBACK: callback_build
%_________________________________________________________________________
try
% 1 - OPEN THE GUI
    % 1.1 - Gather information from Program Control
        GUI = guidata(hObject);
        h   = guihandles(hObject);
        use = getselected(hObject,'all');

    % 1.2 - Open the ThermalModel Export GUI
        thrm = thermGUI;
        r = guihandles(thrm); pause(0.5);

% 2 - INITILIZE THE ATMOSPHERIC DATA
    % 2.1 - Set the station list to match available stations
        for i = 1:length(use);
            data = get(h.(use{i}),'UserData');
            name{i} = [data.group,': ',data.display];
        end

    % 2.2 - Initilize station lists and callbacks for atmospheric data
        % 2.2.1 - Handles tags for atmospheric/snow data
            list = {'Tinitial','LW','SW','albedo','windspd','airtemp',...
                        'RH','bottom','airpress'};
            unit = {'C','W/m^2','W/m^2','none','m/s','C','%','C','kPa'};
            snow = {'depth','density','conductivity','specific','extinct'};

        % 2.2.2 - Loop through each handle and intilize
            for i = 1:length(list);
                user.handles = ['none';use];
                user.units   = unit{i};
                tag = r.(['sta',list{i}]);
                set(tag,'String',['Constant',name],'UserData',user,...
                    'Callback',{@callback_station});
                set(r.(list{i}),'Callback',{@callback_variable});
            end

% 3 - SET GUI DATA
        DATA.ProgramControl = GUI;
        DATA.list = list;
        DATA.snow = snow;
        guidata(thrm,DATA);

% 4 - COLLECT DATA FROM THE *thermal.thrm FILE
        callback_openfcn(r.openfile,[],'thermal.thrm');

% 5 - SET START/END TIMES
    set(r.updatetime,'Callback',{@callback_settimes});
    callback_settimes(r.updatetime,[]);

% 6 - SET CALLBACKS
    set(r.build,'Callback',{@callback_build});
    set(r.openfile,'Callback',{@callback_openfcn});
    set(r.savefile,'Callback',{@callback_savefcn});
    set(r.exit,'Callback',{@exit,thrm});

catch
    mes = ['Error openning thermal model export GUI ',...
            '(callback_exportTHERMAL.m), see errorlog.txt.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% CALLBACK: exit
function exit(h,e,thrm); close(thrm); 


%--------------------------------------------------------------------------
% CALLBACK: callback_savefcn
function callback_savefcn(hObject,eventdata)

try
% 1 - GET DATA FROM GUI
    r = guihandles(hObject);
    DATA = guidata(hObject)
    pth = DATA.ProgramControl.settings.paths.saved;

% 2 - DETERMINE THE SETTINGS FILE TO SAVE
    [fn,pn] = uiputfile({'*.thrm','Thermal Settings (*.thrm)'},...
    'Open Thermal Settings...',[pth,'*.thrm']);
    if fn == 0; return; end
    filename = [pn,fn];

% 3 - GET SNOW DATA
    snow = {'depth','density','conductivity','specific','extinct'};
    for i = 1:length(snow); 
        temp = get(r.(snow{i}),'String'); s{i} = temp{1};
    end

% 4 - GET ATMOSHPERIC DATA
    a = {'Tinitial','LW','SW','albedo','windspd',...
            'airtemp','RH','bottom','airpress'};

    for i = 1:length(a);
        u1 = get(r.(a{i}),'UserData');
        u2 = get(r.(['sta',a{i}]),'UserData');
        atm{i} = [u1.write,',',u2.write];
    end


% 5 - WRITE DATA
    % 5.1 - Open file and write snow property data
        fid = fopen(filename,'w');
        fprintf(fid,'%s,%s,%s,%s,%s\n',s{1},s{2},s{3},s{4},s{5});

    % 5.2 - Write atmospheric pairs and close file
        for i = 1:length(atm); fprintf(fid,'%s\n',atm{i}); end
        fclose(fid);
    
catch
    mes = ['Error occured saving thermal model settings ',...
            '(callback_exportTHERMAL.m > callback_savefcn) ',...
            'see errorlog.txt.'];
    errorlog(mes);
end

%-----------------------------------------------------------------------
% CALLBACK: callback_openfcn
function callback_openfcn(hObject,eventdata,varargin)
% OPENFCN opens the saved settings from *.thrm file

try
% 1 - EXTRACT DATA FROM GUI
    % 1.1 - Get handles and gui data
        r    = guihandles(hObject);
        DATA = guidata(hObject);
        pth  = DATA.ProgramControl.settings.paths.saved;

% 2 - DETERMINE THE SETTINGS FILE TO OPEN
    % 2.1 - Determine the file to open
        if ~isempty(varargin);  filename = varargin{1};
        else
            [fn,pn] = uigetfile({'*.thrm','Thermal Settings (*.thrm)'},...
            'Open settings...',[pth,'*.thrm']);
            if fn == 0; return; end
            filename = [pn,fn];
        end

    % 2.2 - Test the file exists
        if ~exist(filename,'file'); 
            disp('File does not exist.'); return; end

    % 2.3 - Open/read the file
        fid = fopen(filename);
        A = textscan(fid,'%s%s%s%s%s',1,'delimiter',',');
        C = textscan(fid,'%s%s',9,'delimiter',',');
        sta = C{2}; var = C{1};
        fclose(fid);

% 3 - INSERT DESIRED STATIONS IN POPUPMENUS
for i = 1:length(DATA.list);
    % 3.1 - Seperate current station tag
        s = r.(['sta',DATA.list{i}]); 

    % 3.2 - Match the curent string
        str = get(s,'String');
        val = strmatch(sta{i},str,'exact');
        if isempty(val); val = 1; end

    % 3.3 - Insert/match variable
        set(s,'Value',val);
        callback_station(s,[]);
end

% 4 - INSERT DESIRED VARIABLE IN POPUPMENUS
for i = 1:length(DATA.list);
    % 4.1 - Seperate current variable tag
        v = r.(DATA.list{i});

    % 4.2 - Set value based on the style of uicontrol
    switch get(v,'Style');

        % 4.2.1 - Case when an "edit" box is found
        case 'edit'; 
            set(v,'String',var{i}); 
            callback_variable(v,[]);

        % 4.2.2 - Case when a popupmenu is encountered
        case 'popupmenu'; 
            % Determine string and location of desired setting
            str = get(v,'String');
            val = strmatch(var{i},str,'exact');
            if isempty(val); val = 1; end

            % Set the desired value and evoke the callback fuction
            set(v,'Value',val);
            callback_variable(v,[]);
       end
end

% 5 - INSERT DATA INTO SNOW PROPERTIES
    s = DATA.snow;
    for i = 1:length(s); 
        set(r.(s{i}),'String',A{i},'Callback',{@callback_variable}); 
    end

catch
    mes = ['Error occured opening thermal model settings ',...
            '(callback_exportTHERMAL.m > callback_openfcn) ',...
            'see errorlog.txt.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% CALLBACK: callback_settimes
function callback_settimes(hObject,eventdata)
% CALLBACK_SETTIMES updates the time data for extracting data

try
% 1 - Determine the times from the Program Control
    DATA = guidata(hObject);
    r = guihandles(hObject);
    NEW = guidata(DATA.ProgramControl.main);
    t = NEW.time;
    DATA.time = t;

% 2 - Change the time display
    set(r.time1,'String',datestr(t(1),'mmm-dd-yy HH:MM'));
    set(r.time2,'String',datestr(t(2),'mmm-dd-yy HH:MM'));

% 3 - Return the new data structure to guidate for thermal export GUI
    guidata(hObject,DATA);

% 4 - Update Thermocouple profile data
    callback_variable(r.Tinitial,[]);

catch
    mes = ['Error occured setting time in thermal export GUI ',...
            '(callback_exportTHERMAL.m > callback_settimes) ',...
            'see errorlog.txt.'];
    errorlog(mes);
end


%--------------------------------------------------------------------------
% SUBFUNCTION: getTCdata
function data = getTCdata(obj,S)
% GETTCDATA extract thermocouple data from station variable list

% 1 - DETERMINE THE DESIRED TC DATA
    str = get(obj,'String');
    TC  = str{get(obj,'Value')};

% 2 - SEPERATE THE THERMOCOUPLE DATA
    % 2.1 - Initilize output
        n = length(TC);
        fn = fieldnames(S.variables);
        k = 1; out = [];

    % 2.2 - Loop through data and extract the thermocouple data and the
    %       associated depths
        for i = 1:length(fn);
            test = '';
            if length(fn{i}) > n; test = fn{i}(1:n); end
            if strcmpi(test,TC); 
                out = [out,S.variables.(fn{i}).data]; 
                depth(k,1) = str2double((fn{i}(n+1:length(fn{i}))));
                k = k + 1;
        end,end

% 3 - SEPERATE DATA AT DESIRED TIME
    DATA = guidata(obj);
    idx = dsearchn(S.Time,DATA.time(1));
    Y = out(idx,:);
    X = depth;

% 4 - RETURN DATA TO OBJECT
    data = [X,Y'];

%--------------------------------------------------------------------------
% CALLBACK: callback_variable
function callback_variable(hObject,eventdata)
% CALLBACK_VARIABLE executes when a variable with a popup menu is changed

try
% 1 - EXTRACT GUI AND USER DATA
    user = get(hObject,'UserData');
    str  = get(hObject,'String');
    val  = get(hObject,'Value');
    tag  = get(hObject,'Tag');
    sty  = get(hObject,'Style');

% 2 - EXTRACT DATA FROM GUI
    if strcmpi(tag,'Tinitial') && ~strcmpi(sty,'edit');
        user.output = getTCdata(hObject,user.data);
        wrt = str{val};
       
    elseif strcmpi(sty,'edit'); 
        user.output = str2double(str);
        wrt = str;
    else
        var = user.group{val};
        X = user.data.Time;
        Y = user.data.variables.(var).data;
        user.output = [X,Y];
        wrt = str{val};
    end

% 3 - INSERT DATA INTO USER DATA OF OBJECT
    user.write = wrt;
    set(hObject,'UserData',user);

catch
    mes = ['Error occured changing variable item in thermal GUI ',...
            '(callback_exportTHERMAL.m > callback_variable) ',...
            'see errorlog.txt.'];
    errorlog(mes);
end


%--------------------------------------------------------------------------
% CALLBACK: callback_station
function callback_station(hObject,eventdata)
% CALLBACK_STATION executes when a station popup menu is changed 

try
% 1 - EXTRACT GUI AND USER DATA
    % 1.1 - Get handles and gui data
        r    = guihandles(hObject);
        DATA = guidata(hObject);

    % 1.2 - Extract object specific data
        user = get(hObject,'UserData');
        tag  = get(hObject,'Tag');
        str  = get(hObject,'String');
        vartag = r.(tag(4:length(tag)));
        val = get(hObject,'Value');
    
    % 1.3 - Edit user data
        user.write = str{val};
        set(hObject,'UserData',user);

% 2 - SET CONSTANT ITEMS
        if val == 1; 
            set(vartag,'Style','edit','String','','Value',1); 
            callback_variable(vartag,[]);
        return; 
    end

% 3 - GET DATA FROM SELECTED STATION
    h = guihandles(DATA.ProgramControl.main);
    var = get(h.(user.handles{val}),'UserData');

% 4 - SEPERATE THE VARIABLES FOR DESIRED UNITS
    grp   = group_items(var.variables,{user.units},'unit');
    group = grp{1};

% 5 - BUILD A LIST OF VARIABLES
    name = {};
    % 5.1 - Set list for thermocouple arrays
        if strcmpi(tag,'staTinitial');
            A = textscan(var.TCprofile,'%s','delimiter',',');
            name = A{1};       

    % 5.2 - Set list for regular variables
        else
            for i = 1:length(group);
                name{i} = var.variables.(group{i}).label;
            end
        end

    % 5.3 - Set the list to a constant "edit" if nothing is found
        if isempty(name);
            set(vartag,'Style','edit','String',''); return;
        end

    % 5.4 - Insert the list into the popupmenu
        data.group = group;
        data.data  = var;
        set(vartag,'Style','popupmenu','String',name,...
            'UserData',data,'Value',1);

% 6 - ENOVKE CALLBACK AND SET USER DATA
    callback_variable(vartag,[]);

catch
    mes = ['Error occured changing station item in thermal GUI ',...
            '(callback_exportTHERMAL.m > callback_station) ',...
            'see errorlog.txt.'];
    errorlog(mes);
end


%--------------------------------------------------------------------------
% CALLBACK: callback_build
function callback_build(hObject,eventdata)
% CALLBACK_BUILD saves data into a excel file for use with thermal model
   
try
% 1 - EXTRACT DATA FROM GUI
    r = guihandles(hObject);
    D = guidata(hObject);

% 2 - BUILD ARRAY OF SNOWPACK DATA
    % 2.1 - Insert thermocouple data
        user = get(r.Tinitial,'UserData');
        out  = user.output;
        
        % 2.1.1 - Case when data is constant, use depth from GUI
            if isscalar(out);  
                d(:,1) = str2double(get(r.depth,'String'));
                d(:,2) = out;
            else
                d = out;
            end

        % 2.1.2 - Insert data into output array
            snow(:,1) = d(:,1);
            snow(:,5) = d(:,2);

    % 2.2 - Insert the remaining data
        s   = {'density','conductivity','specific','extinct'};
        loc = [2,3,4,6];
        for i = 1:length(s);
            snow(:,loc(i)) = str2double(get(r.(s{i}),'String'));
        end

% 3 - BUILD ATMOSPHERIC DATA ARRAY
    % 3.1 - Build the time array for export
        int  = str2double(get(r.interval,'String'));
        time = D.time(1):int/24/60:D.time(2);
        n    = length(time);

    % 3.2 - Insert data into a single array
    a = {'LW','SW','albedo','windspd','airtemp','RH','bottom','airpress'};
    for i = 1:length(a);
        user = get(r.(a{i}),'UserData');
        d    = user.output;

        % 3.2.1 - Case when a constant value is input
        if isscalar(d);    
            ATM(1:n,i) = d;
        
        % 3.2.2 - Case when non-constant data is input
        else
            x = d(:,1); Y = d(:,2); xi = time';
            yi = interp1(x,Y,xi,'linear');
            ATM(:,i) = yi;
        end
    end

    % 3.3 - Add the time data (hours) to the output array
        tm  = (time - time(1))*24;
        atm = [tm',ATM];

% 4 - TEST THAT THE DEPTH MATCHES THAT OF THE GUI
    depth = str2double(get(r.depth,'String'));
    r = size(snow,1);
    if snow(r,1) ~= depth;
        snow = [snow;snow(r,:)];
        snow(r+1,1) = depth;        % Total depth specified
        snow(r+1,5) = atm(1,8);     % Boundary condition initally
    end

% 5 - BUILD THE THERMAL MODEL EXCEL INPUT FILE
    % 5.1 - Determine the file to create
        GUI = guidata(hObject);
        saved = GUI.ProgramControl.settings.paths.saved;

        [fn,pn] = uiputfile({'*.xlsx','Excel 2007 (*.xlsx)'},...
            'Thermal model filename...',[saved,'*.xlsx']);
        if fn == 0; return; end
        filename = [pn,fn];

    % 5.2 - Copy the template file
        copyfile([cd,'\template.xls'],filename);

    % 5.3 - Insert the data into the new file
        xlswrite(filename,atm,'AtmosphericSettings','A4');
        xlswrite(filename,snow,'SnowProperties','A4');

catch
    mes = ['Error occured changing building thermal model excel file ',...
            '(callback_exportTHERMAL.m > callback_build) ',...
            'see errorlog.txt.'];
    errorlog(mes);
end


