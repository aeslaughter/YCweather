function callback_export(hObject,eventdata,type)
% CALLBACK_EXPORT allows user to export data to *.txt or *.xlsx files
%__________________________________________________________________________
% USAGE: callback_export(hObject,eventdata,type)
%
% INPUT: hObject - calling object handle
%        eventdata - not used, MATLAB required
%        type = 'all' or 'selected'
%__________________________________________________________________________
try
% 1 - COLLECT INFORMATION FROM GUI
    GUI = guidata(hObject);
    h = guihandles(hObject);

% 2 - COLLECT DATA FROM GUI
switch type
    % 2.1 - Collect all the data from 
    case 'all'; 
        
        % 2.1.1 - Determine the selected stations
        use = getselected(hObject);
        if isempty(use); 
            errordlg('You must select a station','ERROR'); return;
        end

        % 2.1.2 - Extract data from selected stations
        for i = 1:length(use);
            [DATA{i},HEAD{i}] = getalldata(h.(use{i})); 
        end

    % 2.2 - Collect selected data from selected variables
    case 'selected'
  
        % 2.2.1 - Check the variable window is open
        if isempty(GUI.varwindow) || ~ishandle(GUI.varwindow)
            errordlg('You must select variables.','ERROR');
            return; 
        end

        % 2.2.2 - Extract selected data
        [DATA,HEAD,use] = getselecteddata(GUI.primary);
end

% 3 - CROP DATA BETWEEN TIMES IF DESIRED
    mes = ['Would you like to crop the data between the selected ',...
            'date/times or write the entire data set?'];
    q   = questdlg(mes,'Crop Data','Crop','Entire','Crop');
    if strcmpi(q,'Crop');  
        [DATA] = cropdata(DATA,GUI.time);
    end

% 4 - WRITE DATA TO FILE(S)
    % 4.1 - Get filenames and type
        FilterSpec = {'*.xls','Excel 97-03 (*.xls)';...
                '*.xlsx','Excel 2007 (*.xlsx)';'*.txt','Text (*.txt)'};
        [fname,fpath,fidx] = uiputfile(FilterSpec,'Save file(s) as...');
        if fname == 0; return; end

    % 4.2 - Write file(s)
        hbar = waitbar(0,'Writing data to file, please wait...');
        for i = 1:length(DATA);
            waitbar(i/length(DATA),hbar);
            writefile(HEAD{i},DATA{i},use{i},[fpath,fname]);    
        end
        close(hbar);
catch
    mes = ['An error occured exporting the data (callback_export), ',...
            'see errorlog.txt'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% SUBFUNCTION: writefile
function [out] = writefile(head,data,station,filename)

% 1 - Seperate desired filename into parts
[pth,file,ext] = fileparts(filename);
DATA = num2cell(data,2);

% 2 - Case when a comma deliminated text file is desired
switch ext
    case '.txt'
        % 2.1 - Build current filename
        filename = [pth,'\',file,'_',station,'.txt'];
        [r,c] = size(data);

        % 2.2 - Build a format text string
        frm = '';
        for i = 2:c; frm = [frm,',%f']; end; frm = [frm,'\n'];
  
        % 2.3 - Write data to file
        fid = fopen(filename,'w');
        for i = 1:r;
            d = DATA{i};                        % Numeric Data
            t = datestr(d(1),'mm-dd-yy HH:MM'); % Date/time
            fprintf(fid,'%s',t);                % Write date/time
            fprintf(fid,frm,d(2:c));            % Write numeric
        end
        fclose(fid);

% 3 - Case shen excel file is desired
    case {'.xlsx','.xls'}
        xlswrite(filename,head,station);
        xlswrite(filename,data,station,'A2')
end


%--------------------------------------------------------------------------
% SUBFUNCTION: cropdata
function [out] = cropdata(in,t)
% CROPDATA removes data between the specified date/times

for i = 1:length(in);
    data = in{i};
    time = data(:,1);
    idx = time >= t(1) & time <= t(2);  
    out{i} = data(idx,:);
end


%--------------------------------------------------------------------------
% SUBFUNCTION: getselecteddata
function [DATA,head,sta] = getselecteddata(handle)
% GETSELECTEDDATA extracts all of the data from the selected station

% Get handle information from primay axis
    user = get(handle,'UserData');
    station = user.sta_panel;

% Loop through each station and build output arrays for each
    for i = 1:length(station);
        U = get(station(i),'UserData');

        [C,head{i}] = get_data(station(i));
        head{i} = ['Time',head{i}];     
        sta{i}  = [user.sta_name{i}]; 

        Y = [];
        for j = 2:2:length(C); Y = [Y,C{j}]; end
        DATA{i} = [U.Time,Y];  
    end


%--------------------------------------------------------------------------
% SUBFUNCTION: getalldata
function [DATA,head] = getalldata(handle)
% GETALLDATA extracts all of the data from the selected station

% Find variable fieldnames
    user = get(handle,'UserData');
    V = user.variables;
    fn = fieldnames(V);

% Loop through each variable and build output arrays
    DATA = user.Time; head = {'Time'};
    for i = 1:length(fn);
        label = V.(fn{i}).label;
        unit  = V.(fn{i}).unit;

        DATA = [DATA,V.(fn{i}).data];
        head = [head,[label,' (',unit,')']];
    end
    