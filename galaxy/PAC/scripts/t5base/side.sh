# This scripts trains Adapters method.
# For smaller datasets of GLUE (mrpc, cola, and stsb), we set the `num_train_epochs` to 20,
# for other larger datasets in GLUE we used `num_train_epochs` of 3. For all datasets we tried
# with the adapter's bottleneck size of `task_reduction_factor`=[32, 16, 8], and report the 
# results on the test set for the model performing the best on the validation set.

model_name=t5-base
method=side
folder_name=all_output_logs/${model_name}
if [ ! -d ${folder_name} ] ; then
    mkdir -p ${folder_name}
fi
source scripts/env.sh

file_name=${model_name}/${method}

r=8
lr=3e-3

encoder_side_layers="[1,2,3,5,6,7,9,10,11]"

for seed in 0 
do
    rm -r outputs/${model_name}/${method}/
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json model_name_or_path str ../../../llm-models/t5/t5-base
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json tokenizer_name str ../../../llm-models/t5/t5-base

    python scripts/update_scripts_for_given_input.py configs/${file_name}.json seed int $seed
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json task_name str $2
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json eval_dataset_name str $2
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json test_dataset_name str $2
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json output_dir str outputs/${config_name}
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json use_gate str "learnable"
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json task_reduction_factor int ${r}
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json load_side_pretrained_weights str fisher-v2
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json learning_rate float ${lr}
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json num_train_epochs int ${num_epochs[$2]}
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json add_bias_sampling str2bool True
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json create_side_lm str2bool False
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json freeze_side_lm str2bool False
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json add_residual_after str2bool False
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json encoder_side_layers eval ${encoder_side_layers}
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json decoder_side_layers eval ${encoder_side_layers}
    
    python scripts/update_scripts_for_given_input.py configs/${file_name}.json output_dir str outputs/${model_name}/${method}

    CUDA_VISIBLE_DEVICES=$1 python run_seq2seq.py  configs/${file_name}.json

    cp outputs/${model_name}/${method}/all_results.json   all_output_logs/${model_name}/${method}_bias_epoch_${num_epochs[$2]}_r${r}_g0_fisher_v2_lr${lr}_$2@${seed}.json
done