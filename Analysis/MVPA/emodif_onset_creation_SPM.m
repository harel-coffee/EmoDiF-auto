function emodif_onset_creation_SPM (subjNum, phase)
%%
%this function converts the IMDiF onsets optimized for the Princeton MVPA toolbox
%for SPM - for all phases - Preview, DFencode_instr, DFencode_item,
%Localizer
%%
subjID = sprintf('emodif_%s',num2str(subjNum));
%subj_dir = sprintf('/corral-repl/utexas/lewpealab/imdif/%s', subjID);

%SET names for emodif_onsets to be read out

outfname = sprintf('~/emodif_data/%s/behav/EmoDif_SPM_%s_onsets_%s.mat', subjID, phase, subjID);


%read in old onsets
load(sprintf('~/emodif_data/%s/behav/EmoDif_mvpa_allregs.mat', subjID));

%%%%% these variables ALL change with experiment %%%%
%write names and durations
if subjID == 101 | subjID == 102 | subjID == 103
    localizer_run_TR = 426;
else
localizer_run_TR = 342; %426 in subject 1, 2 and 3.  %342 for everyone else.  
preview_run_TR = 366;
DFencode_run_TR = 426;
end

names_local = mvpa_regs.localizer.cat_names; % easy %face scene object word rest, for first three subjects - word is emotional and neutral
names_DFE = mvpa_regs.DFencode.cat_names;
names_preview = mvpa_regs.preview.cat_names;

% duration is 0 if we are modeling a delta - this goes up in number for
% boxcar models etc.  1 duration for each condition.
% durations = zeros(length(names),1)'; % easy

durations_local = repmat(9,length(names_local),1);
durations_local = num2cell(durations_local)';

durations_DFE = repmat(9,length(names_DFE),1);
durations_DFE = num2cell(durations_DFE)';

durations_preview = repmat(9,length(names_preview),1);
durations_preview  = num2cell(durations_preview)';

%%%%%%%% BUILDING our onsets %%%%%%%%%%%%%%
% for each of these conditions:
%face scene object word rest
%%% Start Massive Indexing Effort or SMIE %%%
loc_trials = mvpa_regs.localizer.trial;
DFE_trials = mvpa_regs.DFEncoding.trial;
preview_trials = mvpa_regs.preview.trial;

% 
% face_index = mvpa_regs.localizer.cat==1;
% scene_index = mvpa_regs.localizer.cat==2;
% object_index = mvpa_regs.localizer.cat ==3;

% if subjID == 101 || subjID == 102 || subjID == 103
% neg_word_index = mvpa_regs.localizer.cat==4;
% pos_word_index = mvpa_regs.localizer.cat ==5;   
% rest_index = mvpa.regs.localizer.cat ==6;
% else
%     
% word_index = mvpa_regs.localizer.cat==4;
% rest_index = mvpa_regs.localizer.cat ==5; 
% end

%onsets are all expanded - we need to find the beginning of each miniblock
%for the localizer 

%for exceptions - identify by trial number


miniblock_TR = 9;
postblock_rest = 5;
betweenrun_rest = 3;

if subjNum == 101 || subjNum == 102 || subjNum == 103
miniblock_run = 15;
else
miniblock_run= 12;
end


trial_start_run1 = 1:(miniblock_TR+postblock_rest):(miniblock_TR+postblock_rest)*miniblock_run;
trial_start_run2 = trial_start_run1(end)+ (miniblock_TR+postblock_rest) + betweenrun_rest:miniblock_TR+postblock_rest:(trial_start_run1(end)+betweenrun_rest)+((miniblock_TR+postblock_rest)*miniblock_run);


%here are exceptions for LOCALIZER
if subjNum == 101 %218 is 6 - extra TR
    bigger = find(trial_start_run2 > 218);
    for x = 1:length(bigger)
        trial_start_run2(bigger(x)) = trial_start_run2(bigger(x))+1;
    end
elseif subjNum == 113
        bigger = find(trial_start_run1 > 5);
    for x = 1:length(bigger)
        trial_start_run1(bigger(x)) = trial_start_run1(bigger(x))+1;
    end
elseif subjNum == 115
            bigger = find(trial_start_run2> (213+102));
    for x = 1:length(bigger)
        trial_start_run2(bigger(x)) = trial_start_run2(bigger(x))+1;
    end
elseif subjNum == 117
                bigger = find(trial_start_run1> 119);
    for x = 1:length(bigger)
        trial_start_run1(bigger(x)) = trial_start_run1(bigger(x))+1;
    end
elseif subjNum == 118 
                bigger = find(trial_start_run2> (213+132));
    for x = 1:length(bigger)
        trial_start_run2(bigger(x)) = trial_start_run2(bigger(x))+1;
    end
elseif subjNum == 124   
                bigger = find(trial_start_run1> 57);
    for x = 1:length(bigger)
        trial_start_run1(bigger(x)) = trial_start_run1(bigger(x))+1;
    end
end
trials = horzcat(trial_start_run1, trial_start_run2);


%for face blocks
face_blocks = [];

for x = 1:length(trials)
    if mvpa_regs.localizer.cat(trials(x)) == 1
        face_t = trials(x);
        face_blocks = horzcat(face_blocks,face_t);
    else
        face_blocks = face_blocks;
    end
end

%for scene blocks
scene_blocks = [];
for x = 1:length(trials)
    if mvpa_regs.localizer.cat(trials(x)) == 2
        scene_t = trials(x);
        scene_blocks = horzcat(scene_blocks,scene_t);
    else
        scene_blocks = scene_blocks;
    end
end
    
%for object blocks
object_blocks = [];
for x = 1:length(trials)
    if mvpa_regs.localizer.cat(trials(x)) == 3
        object_t = trials(x);
        object_blocks = horzcat(object_blocks,object_t);
    else
        object_blocks = object_blocks;
    end
end

%for word blocks
if subjNum == 101 || subjNum == 102 || subjNum == 103
    

neg_words_blocks = [];
for x = 1:length(trials)
    if mvpa_regs.localizer.cat(trials(x)) == 4
        neg_words_t = trials(x);
        neg_words_blocks = horzcat(neg_words_blocks,neg_words_t);
    else
        neg_words_blocks = neg_words_blocks;
    end
end

neu_words_blocks = [];
for x = 1:length(trials)
    if mvpa_regs.localizer.cat(trials(x)) == 5
        neu_words_t = trials(x);
        neu_words_blocks = horzcat(neu_words_blocks,neu_words_t);
    else
        neu_words_blocks = neu_words_blocks;
    end
end

neg_words_blocks = neg_words_blocks(randperm(length(neg_words_blocks)));
neu_words_blocks = neu_words_blocks(randperm(length(neu_words_blocks)));
word_blocks = sort(horzcat(neg_words_blocks(1:3),neu_words_blocks(1:3)));
noncritword_blocks = sort(horzcat(neg_words_blocks(4:6),neu_words_blocks(4:6)));

onsets{1} = face_blocks;
onsets{2} = scene_blocks;
onsets{3} = object_blocks;
onsets{4} = word_blocks;
onsets{5} = noncritword_blocks;

names_local = {'face', 'scene', 'object', 'word', 'noncritword'};

else
word_blocks = [];
for x = 1:length(trials)
    if mvpa_regs.localizer.cat(trials(x)) == 4
        words_t = trials(x);
       word_blocks = horzcat(word_blocks,words_t);
    else
        word_blocks = word_blocks;
    end   
end

onsets{1} = face_blocks;
onsets{2} = scene_blocks;
onsets{3} = object_blocks;
onsets{4} = word_blocks;
names_local = {'face', 'scene', 'object', 'word'};
end

durations = durations(1:length(onsets));

%redefine names to reflect onsets


save(outfname,'names','onsets','durations');

clear onsets


clear all;

end
 
 