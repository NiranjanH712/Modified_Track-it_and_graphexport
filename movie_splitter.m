function movie_splitter(varargin)

%Set variable for the path that opens when the file selection dialog opens
if nargin == 1
    %movie_splitter was called from the main TrackIt UI, so set the starting path
    %to the current folder of the main TrackIT UI
    startingPath = varargin{1};
else
    %movie_splitter was opened separately
    startingPath = pwd;
end

%File path to the preset .txt file
presetFilePath = [fileparts(which(mfilename)), '\MovieSplitterPresets.txt'];

%Initialize table with filenames and paths
filesTable = cell2table(cell(0,2));
filesTable.Properties.VariableNames = {'FileName','PathName'};

%Create user interface
ui = CreateMovieSplitterUI();

%Load presets from the PresetMovieSplitter.txt file
presets = LoadPresetFile();

%Load first preset into ui table
PresetMenuSelectionCB()

%Create movie splitter user interface
    function ui = CreateMovieSplitterUI()

        %Create figure
        ui.f = figure('Units','normalized',...
            'Position',[0.5 0.5 .35 .45],...
            'MenuBar','None',...
            'Name','Movie splitter',...
            'NumberTitle','off',...
            'WindowKeyPressFcn',@KeyPressFcnCB,...
            'CloseRequestFcn',@CloseRequestCB);

        %List of .tiff files
        ui.lbFilenames = uicontrol('Style','Listbox'...
            ,'Units','normalized',...
            'Value', [],...
            'Min', 0, 'Max', 2,...
            'Position',[0.05 0.53 .7 .45]);

        %Table where user enters sequences
        ui.tbSequences = uitable('Units','normalized',...
            'Position',[0.05 0.01 .456 .5],...
            'ColumnName',{'#frames in sequence';'Name';'Create .tiff file?'},...
            'ColumnFormat', {'numeric', 'numeric', 'logical'},...
            'Data',{'1','seq1',true;'1','seq2',true},...
            'ColumnEditable',[true,true,true],...
            'CellEditCallback',@SequenceTableEditCB);

        buttonPosHor = .76;
        buttonWidth = .22;
        buttonHeight = .1;

        %% Controls on the right side of the ui

        %Select .tiff files button
        uicontrol('String','Add .tiff files',...
            'Units','normalized',...
            'Position',[buttonPosHor .88 buttonWidth buttonHeight],...
            'Callback',@AddFilesCB);

        %Remove selected files button
        uicontrol('String','Remove selected files',...
            'Units','normalized',...
            'Position',[buttonPosHor 0.75 buttonWidth buttonHeight],...
            'Callback',@RemoveFilesCB);

        %Create meta data .txt checkbox
        ui.cboxCreateMetadata = uicontrol('String','<html>Create .txt file containing metadata of original movie',...
            'Units','normalized','Style','checkbox',...
            'Value',1,...
            'Position',[buttonPosHor .55  buttonWidth .2]);

        %Number of sequences text and edit field
        uicontrol('String','Amount of splits',...
            'Units','normalized','Style','Text',...
            'Position',[buttonPosHor .45 buttonWidth buttonHeight],...
            'Callback',@AddFilesCB);

        ui.nSequencesEdit = uicontrol('String','2',...
            'Units','normalized','Style','Edit',...
            'Position',[.82 .4 .1 .08],...
            'Callback',@NSplitsCB);

        %Feedback window
        ui.editFeedbackWin = uicontrol('String','',...
            'Units','normalized',...
            'Position',[buttonPosHor 0.15 buttonWidth .2],...
            'Style','Text','BackgroundColor',[.9 .9 .9]);

        %Start button
        uicontrol('String','Start',...
            'Units','normalized',...
            'Position',[buttonPosHor 0.01 buttonWidth buttonHeight],...
            'Callback',@StartCB);

        %% Split preset controls

        buttonHeight = .06;
        buttonWidth = .2;

        uicontrol('String','Split presets',...
            'Style','text',....
            'Units','normalized',...
            'Position',[0.53 0.41 buttonWidth buttonHeight]);

        ui.presetMenu = uicontrol(...
            'String',{''},...
            'Style','popupmenu',....
            'Units','normalized',...
            'Position',[0.53 0.35 buttonWidth buttonHeight],...
            'Callback',@PresetMenuSelectionCB);


        uicontrol('String','Add new preset',...
            'Units','normalized',...
            'Position',[0.53 0.28 buttonWidth buttonHeight],...
            'Callback',@AddPresetCB);


        uicontrol('String','Delete current preset',...
            'Units','normalized',...
            'Position',[0.53 0.20 buttonWidth buttonHeight],...
            'Callback',@DeletePresetCB);

        uicontrol('String','Save all presets',...
            'Units','normalized',...
            'Position',[0.53 0.12 buttonWidth buttonHeight],...
            'Callback',@SavePresetsCB);


    end

%Load presets from .txt file
    function newPresets = LoadPresetFile(~,~)


        %Check if preset file exists
        if isfile(presetFilePath)

            %Load file and save all text parts in a cell array
            textFileEntries = strsplit(fileread(presetFilePath),{'\n';'\t'}).';

            %Initialize variable for the current preset number in the loop
            currentPresetIdx = 0;

            %Initialize variables to save presets and names
            presetTables = {};
            presetNames = {};

            %Iterate through alls entries in the text file
            for idx = 1:length(textFileEntries)
                %Get current entry
                currentEntry = textFileEntries{idx};

                if isempty(currentEntry)
                    %Jump over empty lines
                    continue
                end

                %Check if current entry is preset name. Preset names are
                %indicated by the starting character '#'
                if strcmp(currentEntry(1),'#')
                    %Increase number of current preset
                    currentPresetIdx = currentPresetIdx + 1;

                    %Save preset name
                    presetNames(currentPresetIdx) = textFileEntries(idx);

                    %Initialize column and row index for following sequnces table
                    columnIdx = 1;
                    rowIdx = 1;
                else
                    %Fill sequences table with entries one-by-one
                    switch columnIdx
                        case 1
                            %First column is number of frames in current sequence
                            presetTables{currentPresetIdx}{rowIdx,columnIdx} = currentEntry;

                            %Go to next column
                            columnIdx = 2;
                        case 2
                            %Second column is sequence name
                            presetTables{currentPresetIdx}{rowIdx,columnIdx} = currentEntry;

                            %Go to next column
                            columnIdx = 3;
                        case 3
                            %Third column is boolean to save .tif file
                            presetTables{currentPresetIdx}{rowIdx,columnIdx} = logical(str2double(currentEntry));

                            %End of current row, so increase row number and
                            %start with first column
                            columnIdx = 1;
                            rowIdx = rowIdx + 1;
                    end
                end
            end

            %Check if txt file contained presets
            if ~isempty(presetNames)
                %Save preset names into the presets popup menu
                ui.presetMenu.String = presetNames;
            end

            %Save preset names and sequence tables into return variable
            newPresets.names = presetNames;
            newPresets.tables = presetTables;

        else
            %PresetMovieSplitter.txt was not found so initialize variable
            %to save preset names and sequence tables
            newPresets.names = {};
            newPresets.tables = {};
        end

    end

%Callback from the presets popup menu
    function PresetMenuSelectionCB(~,~)

        %Get selected element from the popup menu;
        presetValue = ui.presetMenu.Value;

        %Check if any presets exist in the list of presets
        if ~isempty(ui.presetMenu.String{presetValue})
            %Get selecte preset table
            curPreset = presets.tables{presetValue};

            %Display preset table in the ui table
            ui.tbSequences.Data = curPreset;

            %Show amount of sequences in the edit field
            ui.nSequencesEdit.String = size(curPreset,1);
        end
    end

%Called when "Add new preset" button is pressed
    function AddPresetCB(~,~)
        %Show input dialog to enter a preset name
        newPresetName = inputdlg('Enter a name for the new split preset');


        %Return if user didn't enter a string in the input dialog
        if isempty(newPresetName) && isempty(newPresetName{1})
            return
        end

        newPresetName = newPresetName{1};

        %Add a '#' character if name does not start with '#'
        if ~strcmp(newPresetName(1),'#')
            newPresetName = ['#',newPresetName];
        end

        %Check if preset popup menu list is empty
        if isempty(ui.presetMenu.String{1})
            %List is empty, so resplace first entry with new name
            newIdx = 1;
        else
            %List is not empty so append new name to list
            newIdx = length(ui.presetMenu.String) + 1;

        end

        %Add new name to list
        ui.presetMenu.String{newIdx} = newPresetName;

        %Set selected item to new preset
        ui.presetMenu.Value = newIdx;

        %Save data from ui table and the name of the preset into the
        %presets struct variable
        presets.tables{newIdx} = ui.tbSequences.Data;
        presets.names{newIdx} = newPresetName;


    end

%Called when "Delete current preset" button is pressed
    function DeletePresetCB(~,~)

        %Return if preset popup list is empty
        if isempty(ui.presetMenu.String{1})
            return
        end

        %Get seleted preset from popup menu
        presetValue = ui.presetMenu.Value;

        %Delete selected preset from the presets struct variable
        presets.tables(presetValue) = [];
        presets.names(presetValue) = [];

        %Check how many elements there are in the menu
        if length(ui.presetMenu.String) == 1
            %Selection is last element so set entry to an empty string,
            %because ui element needs at least one entry
            ui.presetMenu.String{presetValue} = '';
        else
            %Selected element is not the last one, so delete entry
            ui.presetMenu.String(presetValue) = [];
        end

        %If selected element is not the first entry in the list, display the
        %element which is above the deleted one
        if ui.presetMenu.Value > 1
            ui.presetMenu.Value = presetValue-1;
        end

        %Preset selection has changed so update ui table and edit field
        PresetMenuSelectionCB()

    end

%Callbackwhen "Save all presets" button is pressed
    function SavePresetsCB(~,~)

        %Get preset tables and names from struct variable
        presetTables = presets.tables;
        presetNames = presets.names;

        %Check if any presets exist
        if isempty(presetTables)
            %No presets exist so write an empty character to the presets file

            % Open the file for writing
            fileID = fopen(presetFilePath, 'w');

            %Write empty character
            fprintf(fileID, '');

            % Close the file
            fclose(fileID);
        else
            % Iterate through all presets and write each on to the file
            for i = 1:length(presetTables)

                if i ==1
                    %In first iteration, discard existing contents of the file so set writing
                    %mode to 'w'

                    % Open the file for writing
                    fileID = fopen(presetFilePath, 'w');
                else
                    %Append following presets to the table
                    fileID = fopen(presetFilePath, 'a');%

                    % Add an empty line between tables
                    fprintf(fileID, '\n');
                end

                %Write current preset name to file
                fprintf(fileID, presetNames{i});

                % Close the file
                fclose(fileID);

                %Get current preset table from cell array
                curtable = presetTables{i};

                % Write the table to the file
                writecell(curtable, presetFilePath, 'Delimiter', '\t', 'WriteMode','append');
            end
        end
    end

%Called when value in the sequences table is changed
    function SequenceTableEditCB(~,~)
        %Get selected preset number
        presetValue = ui.presetMenu.Value;

        %Save values of ui table to the presets variable
        presets.tables{presetValue} = ui.tbSequences.Data;
    end

%Called when user changes "Amount of splits" edit field
    function NSplitsCB(src,~)
        %Get current table data
        data = ui.tbSequences.Data;

        %Get amount of desired splits
        nSequences = str2double(src.String);

        %Calculate difference between current amount of splits and new
        %amount of splits
        nAdditional = nSequences - size(data,1);

        if nAdditional > 0
            %More splits required

            %Create vector containing numbers of new rows
            newRowsVec = size(data,1)+1:size(data,1)+nAdditional;

            %Create cell array containing sequence strings for display
            strArray = cell(numel(newRowsVec),1);
            for m = 1:numel(newRowsVec)
                strArray{m} = ['seq',num2str(newRowsVec(m))];
            end

            %Create additional table entries
            ui.tbSequences.Data = [data; repmat({'1','',true},nAdditional,1)];
            %Write sequence strings into "Name" column
            ui.tbSequences.Data(size(data,1)+1:end,2) = strArray;
        elseif nAdditional < 0
            %Less splits required so just delete amount of excess rows
            ui.tbSequences.Data = data(1:end+nAdditional,:);
        end
    end

%Called when "Add files" button is pressed
    function AddFilesCB(~,~)

        %Open file dialog box
        [fileNameListNew,pathName] = uigetfile({'*.tif*'},'Select files you want to split', 'MultiSelect', 'on',startingPath);

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
        ui.lbFilenames.String = filesTable.FileName;

        if size(ui.lbFilenames.String,1) > 1
            %Set selected value to first entry
            ui.lbFilenames.Value = 1;
            %Make sure more than one file can be selected in the ui list
            ui.lbFilenames.Max = 2;
        end
    end

%Called when "Remove selected files" button is pressed
    function RemoveFilesCB(~,~)
        %Remove selection from filestable
        filesTable(ui.lbFilenames.Value,:) = [];

        %Update list of files in ui
        ui.lbFilenames.String = filesTable.FileName;

        if size(ui.lbFilenames.String,1) <= 1
            %Less than 2 files are less so disable multiselection and set
            %selected value to 1
            ui.lbFilenames.Value = 1;
            ui.lbFilenames.Max = 0;
        elseif size(ui.lbFilenames.String,1) < ui.lbFilenames.Value(end)
            %Make sure that selected value is not higher than the amount of
            %files in list
            ui.lbFilenames.Value = numel(ui.lbFilenames.String);
        end
    end

%Called when "Start" button is pressed
    function StartCB(~,~)

        %Get table containing information on how to split
        splitInfo = ui.tbSequences.Data;

        %Get information if .txt files with metadata should be created
        createTxt = ui.cboxCreateMetadata.Value;

        if ~isempty(filesTable) && ~isempty(splitInfo)

            %Create array containing the sequences
            sequences = cellfun(@str2double,splitInfo(:,1));

            %Get amount of splits
            nSequences = numel(sequences);

            %Create cell array containing the add-ons to original filenames
            nameArray = splitInfo(:,2);

            %Additionally we create a cell array with unique sequence name
            %entries so we now which sequences belong together because they
            %share the same name.
            [uniqueNameArray,ia,~] = unique(nameArray,'stable');

            %Create array containing information if a .tiff file should be
            %saved
            createTiff = splitInfo(ia,3);

            %Get amount of unique sequences
            nUniqueSequences = length(uniqueNameArray);

            %Get number of files to split
            nFiles = height(filesTable);

            %Iterate through files
            for n = 1:nFiles
                %Monitor progress in ui
                ui.editFeedbackWin.String = ['Loading Movie ' num2str(n) ' of ' num2str(nFiles)];
                drawnow

                %Get current filename and pathname
                curFileName = filesTable.FileName{n};
                curPathName = filesTable.PathName{n};

                %----------Write text file with metadata-----------------------
                if createTxt
                    %Retreive metadata using bioformats
                    metaData = read_tiff_metadata(fullfile(curPathName,curFileName));

                    %Split metadata at commas and sort them
                    sortedMetaData = sort(strsplit(char(metaData{1}),','));

                    %Create filename for text file
                    [~,curFileNamePart] = fileparts(curFileName);
                    txtFileName = fullfile(curPathName,strcat(curFileNamePart,'.txt'));

                    %Open a text file
                    fid = fopen(txtFileName,'w');
                    %Write metadata to text file
                    for r=1:size(sortedMetaData,1)
                        fprintf(fid,'%s\r\n',sortedMetaData{r,:});
                    end
                    %Close text file
                    fclose(fid);
                end

                %----------Load Stack--------------------------------------
                original = load_stack(curPathName, curFileName, ui);

                %--------Divide movie into substacks---------------------
                ui.editFeedbackWin.String = ['Splitting Movie ' num2str(n) ' of ' num2str(nFiles)];
                drawnow

                %Initialize variable indicating current substack number
                curSubStackNum = 1;

                %Get satck size
                oriStackSize = size(original);

                %Get bit depth of original movie
                oriClass = class(original);

                %Initialize cell array to contain one substack pero cell
                substacks = repmat({zeros(oriStackSize(1),oriStackSize(2),0,oriClass)},nUniqueSequences,1);

                %Initialize frame counter indicating amount of frames in
                %current sequence
                curSequenceFrameCounter = 1;

                %Create variable containing information on how many frames
                %the current sequence should be containing. Start with
                %first sequence.
                nFramesInCurSeq = sequences(1);

                %Get amount of frames in original stack
                nFrames = oriStackSize(3);

                feedbackWin = ui.editFeedbackWin.String;

                curSequenceStack = zeros(oriStackSize(1),oriStackSize(2),0);

                %Iterate through frames
                for m = 1:nFrames
                    %Write current frame to corresponding substack
                    curSequenceStack(:,:,curSequenceFrameCounter) = original(:,:,m);

                    %Check if current frame should be in the next sequence
                    %or if the end of the original movie is reached
                    if curSequenceFrameCounter == nFramesInCurSeq || m == nFrames
                        %Get name of current Sequence
                        curName = nameArray{curSubStackNum};
                        %Find index of corresponding substack
                        index = find(strcmp(curName,uniqueNameArray));
                        %Catenate current sequence into substack
                        substacks{index} = cat(3,substacks{index},curSequenceStack(:,:,1:curSequenceFrameCounter));

                        %Go to next sequence
                        curSubStackNum = mod(curSubStackNum, nSequences)+1;
                        %Get number of frames in next sequence
                        nFramesInCurSeq = sequences(curSubStackNum);
                        %Reinitialize current sequence
                        curSequenceStack = zeros(oriStackSize(1),oriStackSize(2),nFramesInCurSeq);
                        %Reinitialize frame counter for current Sequence
                        curSequenceFrameCounter = 0;
                    end



                    %Increase counter indicating amount of frames in
                    %current stack
                    curSequenceFrameCounter = curSequenceFrameCounter + 1;

                    %Monitor progress in ui
                    percentDone = round(m * 100/ nFrames);
                    if mod(percentDone,5) == 0
                        ui.editFeedbackWin.String = char(sprintf('Splitting progress: %3.0f %%', percentDone), feedbackWin);
                        drawnow
                        if double(get(gcf,'CurrentCharacter')) == 27
                            t.close();
                            break
                        end
                    end

                end

                %----------Get tiff tags from original movie-------------
                fullFileOriginal = char(fullfile(curPathName,curFileName));

                warning('off'); %Supress warnings for unrecognized tif tags
                TifLink = Tiff(fullFileOriginal, 'r');

                %Required .tiff tags
                tagstruct.ImageWidth = getTag(TifLink,'ImageWidth');
                tagstruct.ImageLength = getTag(TifLink,'ImageLength');
                tagstruct.BitsPerSample = getTag(TifLink,'BitsPerSample');
                tagstruct.SamplesPerPixel = getTag(TifLink,'SamplesPerPixel');
                tagstruct.Compression = getTag(TifLink,'Compression');
                tagstruct.PlanarConfiguration = getTag(TifLink,'PlanarConfiguration');
                tagstruct.Photometric = getTag(TifLink,'Photometric');

                %Additional .tiff tags
                tagstruct.RowsPerStrip = getTag(TifLink,'RowsPerStrip');
                tagstruct.Orientation = getTag(TifLink,'Orientation');
                tagstruct.SampleFormat = getTag(TifLink,'SampleFormat');
                close(TifLink);

                warning('on');

                %-------------Write .tiff files------------------------
                for m = 1:nUniqueSequences
                    if createTiff{m} %User chose 'save .tiff file' for this sequence

                        %Get original filename
                        [~,fileWithoutExt,~] = fileparts(curFileName);

                        %Get add-on to original filename
                        curFileAddon = splitInfo{m,2};

                        %Create new filename
                        newFullFilename = char(fullfile(curPathName, strcat(fileWithoutExt,'_', curFileAddon, '.tiff')));

                        %Open tiff file for writing
                        t = Tiff(newFullFilename,'w');

                        %Set tiff tiags
                        t.setTag(tagstruct);

                        %Write first frame
                        t.write(substacks{m}(:,:,1));

                        %Get amount of frames
                        nFrames = size(substacks{m},3);

                        %Iterate through the rest of frames
                        for k=2:nFrames
                            %Write current frame and tags
                            t.writeDirectory();
                            t.setTag(tagstruct);
                            t.write(substacks{m}(:,:,k));

                            %Monitor progress
                            percentDone = round(k * 100/ nFrames);
                            if mod(percentDone,5) == 0
                                ui.editFeedbackWin.String = char(sprintf('Writing Sequence %3.0f: %3.0f %%',m, percentDone), feedbackWin);
                                drawnow
                                if double(get(gcf,'CurrentCharacter')) == 27
                                    t.close();
                                    break
                                end
                            end

                        end
                        t.close();
                    end
                end

            end
            ui.editFeedbackWin.String = char('Splitting Finished');
        end
    end

%Called when escape key is pressed
    function KeyPressFcnCB(~,event)
        %Close figure if esc is pressed
        if strcmp(event.Key, 'escape')
            delete(gcf)
        end
    end

%Called when window is closed
    function CloseRequestCB(~,~)
        delete(gcf)
    end
end
