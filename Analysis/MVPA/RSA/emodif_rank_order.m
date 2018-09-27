function [rank_results] = emodif_rank_order(maskName, preview_shift, TRstart, TRlength)
%rank order analysis - takes the output of intraphase RSA and rank orders
%(to output percentile ranking) the correlation to matching trials vs
%non-matching trials. 

% first part of this analysis is subject specific - but can do 'aggregate'
% in place of subjNum

args.base_dir = '/Users/tw24955/emodif_data';


%single subject
% if subjNum == 'aggregate'
% 
load(sprintf('/Users/tw24955/EmoDif/Analysis/MVPA/subj_list_%s.mat', maskName));
% 
% else
    
for i = 1:length(subj_list);
subjNum = (subj_list{i,1});
subj_folder = subj_list{i,2};
args.subjID = sprintf('emodif_%s',num2str(subjNum));
args.maskName = maskName;
args.output_dir = sprintf('%s/%s/%s/rank_order', args.base_dir, args.subjID, maskName);


args.output_dir = sprintf('%s/aggregate_results/RSA_rank_results/%s', args.base_dir, maskName);
args.outfname = sprintf('%s/rsa_rankorder_aggregate_%s', args.output_dir, date);
args.localizer.trialnum = 24; % 30 for subjects 1-3, but already coded in ...
%within phase rsa script. 24 should apply to everyone else. reducing to 24 happens at concatenation level. comment out 1-3 
%if not using these first 4 subjects.
args.preview.trialnum = 60;
args.DFencode.trialnum = 60;

mkdir(args.output_dir);

args.subj_dir = sprintf('%s/%s', args.base_dir, args.subjID);
    
    args.data_dir = sprintf('%s/results/rsa_results/preview_dfencode/%s/%d/%s',args.subj_dir,args.maskName, preview_shift, subj_folder);

results.bysubject.name = sprintf('%s/emodif_%d_TR%dto%d_rsa_results.mat',args.data_dir, subjNum, TRstart, ((TRstart+TRlength)-1));
results.bysubject.data(i) = load(results.bysubject.name);
results.bysubject.names{i} = results.bysubject.name;

corr_matrix_match_fullz = results.bysubject.data(i).rsa.results.smatrix.corr_matrix_match_fullz;
corr_matrix_match_Fz = results.bysubject.data(i).rsa.results.smatrix.corr_matrix_match_Fz;
corr_matrix_match_Rz = results.bysubject.data(i).rsa.results.smatrix.corr_matrix_match_Rz;

for x = 1:length(corr_matrix_match_fullz(1,:));
    order = (1:length(corr_matrix_match_fullz(1,:)))';
    rank = (1:length(corr_matrix_match_fullz(1,:)))';
    to_sort = horzcat(corr_matrix_match_fullz(:,i),order);
    sorted_corr_matrix_match_fullz_x = sortrows(to_sort);
    ranked_corr_matrix_match_fullz_x = horzcat(rank, sorted_corr_matrix_match_fullz_x); % rank, correlation, order
    match = find(ranked_corr_matrix_match_fullz_x (:,3) == x);
    matched_rank = ranked_corr_matrix_match_fullz_x(match,1)/length(corr_matrix_match_fullz(1,:));
    results.rankorder.rank_corr_matrix_match_fullz(i,x) = matched_rank;
end
    
for x = 1:length(corr_matrix_match_Fz(1,:));
    order = (1:length(corr_matrix_match_Fz(1,:)))';
    rank = (1:length(corr_matrix_match_Fz(1,:)))';
    to_sort = horzcat(corr_matrix_match_Fz(:,i),order);
    sorted_corr_matrix_match_Fz_x = sortrows(to_sort);
    ranked_corr_matrix_match_Fz_x = horzcat(rank, sorted_corr_matrix_match_Fz_x); % rank, correlation, order
    match = find(ranked_corr_matrix_match_Fz_x (:,3) == x);
    matched_rank = ranked_corr_matrix_match_Fz_x(match,1)/length(corr_matrix_match_Fz(1,:));
    results.rankorder.rank_corr_matrix_match_Fz(i,x) = matched_rank;
end

for x = 1:length(corr_matrix_match_Rz(1,:));
    order = (1:length(corr_matrix_match_Rz(1,:)))';
    rank = (1:length(corr_matrix_match_Rz(1,:)))';
    to_sort = horzcat(corr_matrix_match_Rz(:,i),order);
    sorted_corr_matrix_match_Rz_x = sortrows(to_sort);
    ranked_corr_matrix_match_Rz_x = horzcat(rank, sorted_corr_matrix_match_Rz_x); % rank, correlation, order
    match = find(ranked_corr_matrix_match_Rz_x (:,3) == x);
    matched_rank = ranked_corr_matrix_match_Rz_x(match,1)/length(corr_matrix_match_Rz(1,:));
    results.rankorder.rank_corr_matrix_match_Rz(i,x) = matched_rank;
end

end
filename = args.outfname;
save(filename, 'results');





end

    






