function emodif_mvpa_localizer_parse(subjNum,phase, maskName, test_date)

%emodif_mvpa_localizer_parse('101','localizer', 'tempoccfusi_pHg_LOC_combined_epi_space', '08-Nov-2018')

  args.break = 3; %how many TRs are at the end of each run regardless of condition
  args.local.nTRs = 426; % 135 trials per run, 5 TRs per rest, each post miniblock. each single run 145 stim TRs and 75 rest TRs.  
  args.local.trialTR = 9;
  
  args.subjNum = subjNum;
  args.subjID = sprintf('emodif_%s',num2str(subjNum));
  
  args.subj_dir = sprintf('/Users/tw24955/emodif_data/%s', args.subjID);
  
  args.bold_dir = sprintf('%s/BOLD', args.subj_dir);
  args.mask_dir = sprintf('%s/mask', args.subj_dir);
  args.regs_dir = sprintf('%s/behav', args.subj_dir);
  args.output_dir = sprintf('%s/results/%s/%s/%s',args.subj_dir, phase, maskName, test_date);
  args.script_dir = pwd;
  
  
  cd(args.output_dir)
  class_perf = load(sprintf('emodif_%s_localizer_concat_perf.txt',subjNum));
  
  %class performance is guesses, desireds, accuracy, acts
  regressors = load(sprintf('emodif_%s_localizer_shifted_info.txt',subjNum));
  
  %shifted trials, shifted TRs, shifted regs (which is 
  fparameters = fopen(sprintf('emodif_%s_localizer_parameters.txt',subjNum));
  
  
  
  