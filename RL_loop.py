import sys, os, re, subprocess
results = sys.argv[1]

def all_RL_models(subject_list_path,input_dir,results,assoc_model,split_model,counterbalance,run,p_or_r):
    if assoc_model=='true':
        model_name = 'assoc'
    elif split_model=='true':
        model_name = 'split-LR'
    else: 
        model_name = 'RL'

    if not os.path.exists(results):
        os.makedirs(results)
        print(f"Created results directory {results}")

    if not os.path.exists(f"{results}/logs"):
        os.makedirs(f"{results}/logs")
        print(f"Created results-logs directory {results}/logs")

    subjects = []
    with open(subject_list_path) as infile:
        for line in infile:
            if 'ID' not in line:
                subjects.append(line.strip())

    ssub_path = '/media/labs/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/run_RL.ssub'

    for subject in subjects:
        stdout_name = f"{results}/logs/{subject}-%J.stdout"
        stderr_name = f"{results}/logs/{subject}-%J.stderr"

        jobname = f'{model_name}-fit-{subject}'
        os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} {subject} {input_dir} {results} {assoc_model} {split_model} {counterbalance} {run} {p_or_r}")

        print(f"SUBMITTED JOB [{jobname}]")

for r in [1,2]:
    if r == 1:
        runst = ''
    else:
        runst = r    
    for cb in [1,2]:
        for predict_resp in ['p','r']:
            for model1 in ['true', 'false']: 
                if model1 == 'false':
                    for model2 in ['true', 'false']:
                        all_RL_models('/media/labs/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/id_list_'+str(cb)+'.csv',
                        '/media/labs/NPC/DataSink/StimTool_Online/WBMTURK_Emotional_Faces'+str(runst)+'CB'+str(cb),
                        results, 
                        model1, 
                        model2, 
                        str(cb), 
                        str(r), 
                        predict_resp)
                else:     
                    model2 = 'false'    
                    all_RL_models('/media/labs/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/id_list_'+str(cb)+'.csv',
                        '/media/labs/NPC/DataSink/StimTool_Online/WBMTURK_Emotional_Faces'+str(runst)+'CB'+str(cb),
                        results, 
                        model1, 
                        model2, 
                        str(cb), 
                        str(r), 
                        predict_resp)

