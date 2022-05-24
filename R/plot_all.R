
plot_all <- function(out_dir, i = 1, min_LLR = 10, verbose = TRUE){
	
	bulk_subtrees = fread(glue('{out_dir}/bulk_subtrees_{i}.tsv.gz'), sep = '\t')
	
	bulk_clones = fread(glue('{out_dir}/bulk_clones_{i}.tsv.gz'), sep = '\t')

	
	numbat:::log_message('Making plots..', verbose = verbose)
	
	p = numbat:::plot_bulks(bulk_subtrees)
	
	ggsave(glue('{out_dir}/bulk_subtrees_{i}.png'), p, width = 14, height = 2*length(unique(bulk_subtrees$sample)), dpi = 200)
	
	p = numbat:::plot_bulks(bulk_clones, min_LLR = min_LLR)
	
	ggsave(glue('{out_dir}/bulk_clones_{i}.png'), p, width = 14, height = 2*length(unique(bulk_clones$sample)), dpi = 200)
	

	gtree = readRDS(glue('{out_dir}/tree_final_{i}.rds'))
	joint_post = fread(glue('{out_dir}/joint_post_{i}.tsv'), sep = '\t')
	segs_consensus = fread(glue('{out_dir}/segs_consensus_{i}.tsv'), sep = '\t')

	
	panel = numbat:::plot_phylo_heatmap(
		gtree,
		joint_post,
		segs_consensus,
		tip_length = 0.2,
		branch_width = 0.2,
		line_width = 0.1,
		geno_bar = TRUE
	)
	
	ggsave(glue('{out_dir}/panel_{i}.png'), panel, width = 8, height = 3.5, dpi = 200)
}
