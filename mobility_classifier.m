function mobility_classifier(varargin)

%This tool separates tracks into bound and free segments and are then saved in two separate batch files with the
%filename add-on "_free.mat" and "_bound.mat", into the same folder as the original batch file.
%Before classification, tracks with gap frames are split at gap positions into separate tracks, as
%vbSPT cannot handle gap frames. The minimum track length field defines the minimum amount
%of frames of a track after splitting. Advanced settings can be set in the "runinput.m" file in the
%"vbSPT" folder.


if nargin == 1
    startingPath = varargin{1};
else
    startingPath = pwd;
end


%Initialize table with filenames and paths
filesTable = cell2table(cell(0,2));
filesTable.Properties.VariableNames = {'FileName','PathName'};

%Create user interface
ui = CreateMovieSelectorUI();

    function ui = CreateMovieSelectorUI()

        ui.f = figure('Units','normalized',...
            'Position',[0.4 0.4 .35 .3],...
            'MenuBar','None',...
            'Name','Mobility classifier',...
            'NumberTitle','off',...
            'WindowKeyPressFcn',@KeyPressFcnCB,...
            'CloseRequestFcn',@CloseRequestCB);
        ui.lb = uicontrol('Style','Listbox'...
            ,'Units','normalized',...
            'Value', [],...
            'Min', 0, 'Max', 2,...
            'Position',[0.05 0.35 .65 .62]);


        buttonPosHor = .76;
        buttonWidth = .23;
        buttonHeight = .09;

        filesButton = uicontrol('String','Select batch files',...
            'Units','normalized',...
            'Position',[buttonPosHor .88 buttonWidth buttonHeight],...
            'Callback',@AddFilesCB);

        removeButton = uicontrol('String','Remove selected files',...
            'Units','normalized',...
            'Position',[buttonPosHor 0.75 buttonWidth buttonHeight],...
            'Callback',@RemoveFilesCB);

        textMinTrackLength = uicontrol('String','Minimum track length',...
            'Units','normalized','Style','Text',...
            'HorizontalAlignment','Left',...
            'Position',[buttonPosHor+.01 .6 buttonWidth-.05 buttonHeight]);

        ui.editMinTrackLength = uicontrol('String','2',...
            'Units','normalized','Style','Edit',...
            'Position',[.94 .62 .05 buttonHeight-.01]);

        subRegionText = uicontrol('String','Sub-region assignment (only applicable if sub-regions exist)',...
            'Units','normalized','Style','text',...
            'Position',[buttonPosHor .46 buttonWidth buttonHeight]);

        ui.subRoiBorderHandlingMenu = uicontrol('String',...
            {'Assign by first appearance', 'Split tracks at borders', 'Delete tracks crossing borders', 'Only use tracks crossing borders'},...
            'Units','normalized','Style','popupmenu',...
            'Position',[buttonPosHor .35 buttonWidth buttonHeight]);


        ui.editProgressFeedbackWin = uicontrol('String','',...
            'Units','normalized',...
            'Position',[buttonPosHor 0.11 buttonWidth .2],...
            'Style','Text','BackgroundColor',[.9 .9 .9]);

        startButton = uicontrol('String','Start',...
            'Units','normalized',...
            'Position',[buttonPosHor 0.01 buttonWidth buttonHeight],...
            'Callback',@StartCB);


        textMinTrackLength = uicontrol('String',['This tool classifies tracks into bound and free segments and splits them accordingly. ' ...
            'The classification is done by the vbSPT software (see manual for more details and references). ' ...
            'Bound and free track segments are then saved in two separate batch files ' ...
            'with the filename add-on "_free.mat" and "_bound.mat", into the same folder as the original batch file. ' ...
            'Note: tracks with gap frames are split at the gap positions.'],...
            'Units','normalized','Style','Text',...
            'HorizontalAlignment','Left',...
            'FontSize',9,...
            'Position',[.05 .01 .65 .3]);


    end

    function KeyPressFcnCB(~,event)
        %Close figure if esc is pressed
        if strcmp(event.Key, 'escape')
            delete(gcf)
        end
    end

    function CloseRequestCB(~,~)
        delete(gcf)
    end

    function AddFilesCB(~,~)
        %User pressed "Add files" button

        %Open file dialog box
        [fileNameListNew,pathName] = uigetfile({'*.mat*'},'Select files you want to split', 'MultiSelect', 'on',startingPath);

        if isequal(fileNameListNew,0) %User didn't choose a file
            return
        elseif ~iscell(fileNameListNew) %Check if only one file has been chosen
            fileNameListNew = {fileNameListNew};
        end

        %Save path for next usgage of file dialog box
        startingPath = pathName;

        %Create table containing new filenames and paths
        pathNameListNew = repmat({pathName},1,length(fileNameListNew));
        filesTableNew = table(fileNameListNew',pathNameListNew','VariableNames',{'FileName','PathName'});

        %Add new filetable to existing one
        filesTable = [filesTable;filesTableNew];

        %Show filenames in ui
        ui.lb.String = filesTable.FileName;

        if size(ui.lb.String,1) > 1
            %Set selected value to first entry
            ui.lb.Value = 1;
            %Make sure more than one file can be selected in the ui list
            ui.lb.Max = 2;
        end
    end

    function RemoveFilesCB(~,~)
        %User pressed "Remove selected files" button

        %Remove selection from filestable
        filesTable(ui.lb.Value,:) = [];

        %Update list of files in ui
        ui.lb.String = filesTable.FileName;

        if size(ui.lb.String,1) <= 1
            %Less than 2 files are less so disable multiselection and set
            %selected value to 1
            ui.lb.Value = 1;
            ui.lb.Max = 0;
        elseif size(ui.lb.String,1) < ui.lb.Value(end)
            %Make sure that selected value is not higher than the amount of
            %files in list
            ui.lb.Value = numel(ui.lb.String);
        end
    end

    function StartCB(src,~)
        %Make sure current character is not str+s so user can press strg + s to cancel
        set(gcf,'currentch',char(1))

        %User pressed "Start" button
        src.BackgroundColor = 'r';
        src.String = 'Press Ctrl + X to stop';
        ui.editProgressFeedbackWin.String = '';
        drawnow;

        %Get number of batch files to analyze
        nBatchFiles = height(filesTable);

        %Get tracking settings
        minTrackLength = str2double(ui.editMinTrackLength.String);
        subRoiBorderHandling = ui.subRoiBorderHandlingMenu.String{ui.subRoiBorderHandlingMenu.Value};


        if ~isempty(filesTable)

            %Iterate through files
            tic
            for batchFileIdx = 1:nBatchFiles
                %Monitor progress in ui
                ui.editProgressFeedbackWin.String = ['Loading batch ' num2str(batchFileIdx) ' of ' num2str(nBatchFiles)];
                drawnow

                %Get current filename and pathname
                curFileName = filesTable.FileName{batchFileIdx};
                curPathName = filesTable.PathName{batchFileIdx};

                loadedFile = load(fullfile(curPathName,curFileName));

                if ~isfield(loadedFile,'batch')
                    ui.editProgressFeedbackWin.String = char('Please choose a valid batch file');
                    return
                end

                loadedBatch = loadedFile.batch;
                loadedFilesTable = loadedFile.filesTable;


                %Built filenames for bound and free batch files
                [~,name,ext] = fileparts(curFileName);

                boundFileName = fullfile(curPathName,[name, '_bound', ext]);
                freeFileName = fullfile(curPathName,[name, '_free', ext]);

                %-----------------------------------------------


                ui.editProgressFeedbackWin.String = ['Progressing batch ' num2str(batchFileIdx) ' of ' num2str(nBatchFiles)];
                drawnow

                nMovies = length(loadedBatch);


                %split the batch into two:
                batchBound=loadedBatch;
                batchFree=loadedBatch;

                %loop over all movies
                for movieIdx=1:nMovies


                    ui.editProgressFeedbackWin.String = char(ui.editProgressFeedbackWin.String(1,:), ['Classifying movie ' num2str(movieIdx) ' of ' num2str(nMovies)]);
                    drawnow
                    %---- Reformat tracks to make it compatible wit hvSPT--------------


                    %Get tracks in current movie
                    curMovieTracks = loadedBatch(movieIdx).results.tracks;

                    [tracksBound, tracksFree] = vbSPT_TrackItPlugin(curMovieTracks, minTrackLength);

                    %Get ROI, subROI and frameRange of the current batch to create
                    %results for TrackIt
                    ROI = loadedBatch(movieIdx).ROI;
                    subROI = loadedBatch(movieIdx).subROI;
                    frameRange = loadedBatch(movieIdx).params.frameRange;
                    spotsAll = loadedBatch(movieIdx).results.spotsAll;


                    %Create results for TrackIt and save it into the batch structure
                    batchBound(movieIdx).results=create_results(spotsAll,tracksBound,ROI,subROI,minTrackLength,frameRange,subRoiBorderHandling); %use the create_results() function to overwrite the entries in the results struct with the new values corresponding only to the tracks with mobility class 1
                    batchFree(movieIdx).results=create_results(spotsAll,tracksFree,ROI,subROI,minTrackLength,frameRange,subRoiBorderHandling); %use the create_results() function to overwrite the entries in the results struct with the new values corresponding only to the tracks with mobility class 2


                end

                %delete the files, that were stored for the classification algorithm to
                %access:
                delete Jdata.mat
                delete Jresult.mat


                %----------------------------------------------------


                %save the batch with only mobility class 1 (bound):
                S = struct;

                ui.editProgressFeedbackWin.String = ['Saving batch file ' num2str(batchFileIdx) ' of ' num2str(batchFileIdx) ' containing bound segments.'];
                drawnow

                S.filesTable = loadedFilesTable;
                S.batch = batchBound;
                save(boundFileName,'-struct','S')


                ui.editProgressFeedbackWin.String = ['Saving free batch file ' num2str(batchFileIdx) ' of ' num2str(batchFileIdx) ' containing free segments.'];
                drawnow

                S.batch = batchFree;
                save(freeFileName,'-struct','S')

            end


            if  ~isempty(get(gcf,'CurrentCharacter')) &&  double(get(gcf,'CurrentCharacter')) == 24
                %Analysis aborted by user
                ui.editProgressFeedbackWin.String = char('Analysis stopped by user');
            else
                %Analysis finished
                ui.editProgressFeedbackWin.String = ['Analysis finished in ', num2str(floor(toc/60)),' min, ', num2str(ceil(toc - floor(toc/60) * 60)), ' sec'];
            end

        end


        src.BackgroundColor = [.94 .94 .94]; %Reset button color to gray
        src.String = 'Start'; %Reset button string
    end

end
