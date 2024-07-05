import sys, os, re, subprocess

subject_list_path = sys.argv[1]
input_dir = sys.argv[2]
results = sys.argv[3]
assoc_model = sys.argv[4]
split_model = sys.argv[5]
counterbalance = sys.argv[6]
run = sys.argv[7]
p_or_r = sys.argv[8]

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

ssub_path = '/media/labs/rsmith/lab-members/clavalley/MATLAB/emotional_faces/run_RL.ssub'

for subject in subjects:
    stdout_name = f"{results}/logs/{subject}-%J.stdout"
    stderr_name = f"{results}/logs/{subject}-%J.stderr"

    jobname = f'{model_name}-fit-{subject}'
    os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} {subject} {input_dir} {results} {assoc_model} {split_model} {counterbalance} {run} {p_or_r}")

    print(f"SUBMITTED JOB [{jobname}]")


    ###python3 run_faces_RL.py /media/labs/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/id_list_1.csv /media/labs/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/raw/v2 /media/labs/rsmith/lab-members/clavalley/studies/development/wellbeing/faces/hgf_output/third_batch "true" "false" "1" "[]" "p"


    ## joblist | grep HGF-fit | grep -Po 98.... | xargs scancel