import sys, os, re, subprocess

results = sys.argv[1]

def run_HGF_models(subject_list_path, run, results, model, prediction, counterbalance):
    if model == 'false':
        model_name = 'binary'
    else:
        model_name = 'rt'

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

    ssub_path = '/media/labs/rsmith/lab-members/clavalley/MATLAB/emotional_faces/run_HGF.ssub'

    for subject in subjects:
        stdout_name = f"{results}/logs/{subject}-%J.stdout"
        stderr_name = f"{results}/logs/{subject}-%J.stderr"

        jobname = f'HGF-{model_name}-fit-{subject}'
        os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} {subject} {run} {results} {model} {prediction} {counterbalance}")

        print(f"SUBMITTED JOB [{jobname}]")


for r in [1,2]: 
    for cb in [1,2]:
        for model in ['true', 'false']: 
            if model=='false':
                for predict_resp in ['p','r']:
                    run_HGF_models('/media/labs/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/id_list_'+str(cb)+'.csv',
                    str(r), 
                    results, 
                    model, 
                    predict_resp, 
                    str(cb))
            else:
                predict_resp = 'r'
                run_HGF_models('/media/labs/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/id_list_'+str(cb)+'.csv',
                    str(r), 
                    results, 
                    model, 
                    predict_resp, 
                    str(cb))
  


