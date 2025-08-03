process CHAI_1 {
    tag "$meta.id"
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/gcc_linux-64_python_cuda_pip_chai_lab:44cb323409492b49'

    input:
    tuple val(meta), path(fasta)
    path weights_dir
    path msa_dir
    val num_trunk_recycles
    val num_diffusion_timesteps
    val seed
    val use_esm_embeddings

    output:
    tuple val(meta), path("${meta.id}/*.cif"), emit: structures
    tuple val(meta), path("${meta.id}/*.npz"), emit: arrays
    path "versions.yml"                      , emit: versions

    script:
    def downloads_dir = weights_dir ?: './downloads'
    def msa_path = msa_dir ? "--msa-dir=$msa_dir" : ''
    def use_esm = use_esm_embeddings ? '--use-esm-embeddings' : ''
    """
    CHAI_DOWNLOADS_DIR=$downloads_dir \\
    run_chai_1.py \\
        --fasta-file ${fasta} \\
        --output-dir ${meta.id} \\
        --num-trunk-recycles ${num_trunk_recycles} \\
        --num-diffn-timesteps ${num_diffusion_timesteps} \\
        --seed ${seed} \\
        ${use_esm} \\
        ${msa_path}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        chai_lab: \$(python -c "import chai_lab; print(chai_lab.__version__)")
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${meta.id}
    touch ${meta.id}/pred.model_idx_0.cif
    touch ${meta.id}/pred.model_idx_1.cif
    touch ${meta.id}/scores.model_idx_0.npz
    touch ${meta.id}/scores.model_idx_1.npz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        chai_lab: \$(python -c "import chai_lab; print(chai_lab.__version__)")
        torch: \$(python -c "import torch; print(torch.__version__)")
    END_VERSIONS
    """
}
