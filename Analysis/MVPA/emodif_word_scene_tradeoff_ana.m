function emodif_word_scene_separation()

%to where results directory is
load('emodif_aggregate_results_complete.mat')

% across R
% across F 
% across both

%collapse across ALL the trials - 
R_data_word = [];
F_data_word = [];
R_data_scene = [];
F_data_scene = [];

for s = 1:24
    r_data_w = results.bysubject.data(s).results.remember.all.acts.word;
    f_data_w = results.bysubject.data(s).results.forget.all.acts.word;
    R_data_word = vertcat(r_data_w, R_data_word);
    F_data_word = vertcat(f_data_w, F_data_word);
    
    r_data_s = results.bysubject.data(s).results.remember.all.acts.scene;
    f_data_s = results.bysubject.data(s).results.forget.all.acts.scene;
    R_data_scene = vertcat(r_data_s, R_data_scene);
    F_data_scene = vertcat(f_data_s, F_data_scene);
    
    %compute correlation for every trial between word and scene
    R_corr=[];
    F_corr=[];
    R_corrP=[];
    F_corrP=[];

    for x = 1:length(R_data_scene)
        [R_correl(x,1), R_corrP(x,1)] = corr(R_data_word(x,:)',R_data_scene(x,:)');
        [F_correl(x,1), F_corrP(x,1)] = corr(F_data_word(x,:)',F_data_scene(x,:)');
        R_correl(x,2) = 0.5*log((1+R_correl(x,1))/(1-R_correl(x,1)));
        F_correl(x,2) = 0.5*log((1+F_correl(x,1))/(1-F_correl(x,1)));
        
        R_correl_mean_z = mean(R_correl(:,2));
        F_correl_mean_z = mean(F_correl(:,2));
        
        RPcount = sum(R_corrP <.05);
        FPcount = sum(F_corrP <.05);
        
        RPperc = RPcount/length(R_data_scene);
        FPperc = FPcount/length(F_data_scene);
        
    end
    results_tradeoff.bysubject.
    
    %Fisher's transform 
        
%FISHER Equation
%z = 0.5*log((1+r)/(1-r));
    
    
end



    results_tradeoff.R_data_w = R_data_words;
    results_tradeoff.F_data_s = F_data_scenes;
